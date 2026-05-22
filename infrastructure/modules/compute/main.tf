# =========================================================================
#       SERVERLESS PROCESSING INFRA FOR LAMBDA FUNCTIONS 
# =========================================================================

# 1. IAM EXECUTION ROLE FOR LAMBDA FUNCTIONS (Unified Role for both Web API and Queue Worker)
resource "aws_iam_role" "lambda_exec" {
  name        = "asgard-${var.environment}-lambda-execution-role"
  description = "Unified execution identity role for the serverless application layer"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = {
    Name = "asgard-${var.environment}-lambda-execution-role"
  }
}

# Unified Custom Policy for VPC Execution, Logging, Secrets Access, SQS Processing, and SES Email Dispatch
resource "aws_iam_policy" "lambda_permissions" {
  name        = "asgard-${var.environment}-lambda-permissions-policy"
  description = "IAM policy granting network boundary routing, logging, queue handling, credential decoding, and SES mail dispatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # CloudWatch Logging Permissions
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      # VPC Execution Elastic Network Interface (ENI) management
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = "*"
      },
      # Access to RDS managed credentials & application settings envelope
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          var.rds_secret_arn,
          var.app_secrets_arn
        ]
      },
      # Asynchronous Queue interaction bounds
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:SendMessage"
        ]
        Resource = var.sqs_queue_arn
      },
      # SES Email Dispatch 
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        # Scoped to all identities since SES requires you to verify individual 
        # domains/emails inside the service itself before you can send from them.
        Resource = "*" 
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_link" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_permissions.arn
}


# 2. LAMBDA LOGS
resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/lambda/asgard-${var.environment}-web-api"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "worker_logs" {
  name              = "/aws/lambda/asgard-${var.environment}-queue-worker"
  retention_in_days = 14
}


# 3. THE CORE WEB API LAMBDA (For Handling HTTP Traffic)
resource "aws_lambda_function" "web_api" {
  function_name = "asgard-${var.environment}-web-api"
  description   = "Monolambda running Django DRF handling all synchronous application API paths"
  role          = aws_iam_role.lambda_exec.arn

  # Points to the pre-staged S3 bootstrap storage location
  s3_bucket = var.s3_bucket_id
  s3_key    = var.s3_bootstrap_key

  # Runtime Specs
  runtime     = "python3.11"
  handler     = "asgard.asgi.handler" # Routed cleanly via Mangum adapter in code
  timeout     = 30
  memory_size = 512 # Standard minimum baseline processing ceiling for standard Django packages

  # VPC Placement Routing Configuration
  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_sg_id]
  }

  environment {
    variables = {
      ENVIRONMENT         = var.environment
      APP_SECRETS_ARN     = var.app_secrets_arn
      DATABASE_SECRET_ARN = var.rds_secret_arn
      SQS_QUEUE_URL       = var.sqs_queue_id
    }
  }

  depends_on = [aws_cloudwatch_log_group.api_logs]
}


# 4. THE ASYNCHRONOUS BACKGROUND QUEUE WORKER
resource "aws_lambda_function" "queue_worker" {
  function_name = "asgard-${var.environment}-queue-worker"
  description   = "Worker processing decoupled heavy restaurant booking workloads from SQS"
  role          = aws_iam_role.lambda_exec.arn

  s3_bucket = var.s3_bucket_id
  s3_key    = var.s3_bootstrap_key

  runtime     = "python3.11"
  handler     = "workers.booking_worker.handler" 
  timeout     = 60 # Extended lifecycle limit for handling batch processing retries
  memory_size = 512

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_sg_id]
  }

  environment {
    variables = {
      ENVIRONMENT         = var.environment
      APP_SECRETS_ARN     = var.app_secrets_arn
      DATABASE_SECRET_ARN = var.rds_secret_arn
    }
  }

  depends_on = [aws_cloudwatch_log_group.worker_logs]
}


# 5. BATCH-TUNING EVENT SOURCE MAPPING (For 90% Invocation Cost Reduction on SQS Triggered Lambda)
resource "aws_lambda_event_source_mapping" "sqs_to_worker" {
  event_source_arn = var.sqs_queue_arn
  function_name    = aws_lambda_function.queue_worker.arn
  
  # Accumulates up to 10 payloads or waits 5 seconds before waking up the Lambda execution layer
  batch_size                         = 10   
  maximum_batching_window_in_seconds = 5    
  
  enabled = true
}