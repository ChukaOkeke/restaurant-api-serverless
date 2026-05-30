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
      # Dead Letter Queue interaction bounds
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage" # Lambda ONLY needs to send messages here, never read them
        ]
        Resource = var.sqs_dlq_arn
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

  # checkov:skip=CKV_AWS_355:Wildcard resource is mandatory for ec2:DescribeNetworkInterfaces to permit VPC Lambda ENI allocation, and intentionally permitted for SES in dev to allow multi-identity sandbox testing.
  # checkov:skip=CKV_AWS_290:Wildcard resource is mandatory for ec2:DescribeNetworkInterfaces to permit VPC Lambda ENI allocation, and intentionally permitted for SES in dev to allow multi-identity sandbox testing.
}

resource "aws_iam_role_policy_attachment" "lambda_policy_link" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_permissions.arn
}

# Attach X-Ray write permissions to your Lambda execution role
resource "aws_iam_role_policy_attachment" "lambda_xray" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}


# 2. LAMBDA LOGS
resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/lambda/asgard-${var.environment}-web-api"
  retention_in_days = 14

  # Inline suppression annotations for Checkov to acknowledge intentional security decisions in the logging configuration:
  # checkov:skip=CKV_AWS_338:Short retention period is intentional for lower-environment cost optimization
  # checkov:skip=CKV_AWS_158:KMS encryption is bypassed in dev to eliminate custom key costs; default cloud security is sufficient
}

resource "aws_cloudwatch_log_group" "worker_logs" {
  name              = "/aws/lambda/asgard-${var.environment}-queue-worker"
  retention_in_days = 14

  # checkov:skip=CKV_AWS_338:Short retention period is intentional for lower-environment cost optimization
  # checkov:skip=CKV_AWS_158:KMS encryption is bypassed in dev to eliminate custom key costs; default cloud security is sufficient
}


# 3. THE CORE WEB API LAMBDA (For Handling HTTP Traffic)
resource "aws_lambda_function" "web_api" {
  function_name = "asgard-${var.environment}-web-api"
  description   = "Monolambda running Django DRF handling all synchronous application API paths"
  role          = aws_iam_role.lambda_exec.arn

  # Points to S3 storage, prioritizing the CI/CD artifact over the bootstrap during deployments, and falling back to the bootstrap for local development runs to ensure a smooth developer experience without needing to set up CI/CD pipelines or S3 buckets.
  s3_bucket = var.s3_bucket_id
  s3_key    = var.api_artifact_key != "" ? var.api_artifact_key : var.s3_bootstrap_key

  # Runtime Specs
  runtime     = "python3.11"
  handler     = "handler.handler" # The variable/function in application code to execute to route cleanly via Mangum adapter in code (Entry point for API Gateway triggered processing)
  timeout     = 30
  memory_size = 512 # Standard minimum baseline processing ceiling for standard Django packages

  # VPC Placement Routing Configuration
  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_sg_id]
  }

  # Restricts this function to a safe maximum, protecting the rest of your AWS account pool from being exhausted during traffic spikes.
  # reserved_concurrent_executions = var.lambda_concurrency_limit

  # Instructs AWS to capture performance metrics and downstream request traces.
  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      ENVIRONMENT         = var.environment
      APP_SECRETS_ARN     = var.app_secrets_arn
      DATABASE_SECRET_ARN = var.rds_secret_arn
      SQS_QUEUE_URL       = var.sqs_queue_id
      DEBUG               = "False"
      CI_MODE             = "True"
    }
  }

  # Secure environment variable storage via native AWS managed KMS key
 # kms_key_arn = "arn:aws:kms:${var.aws_region}:${data.aws_caller_identity.current.account_id}:alias/aws/lambda"

  # checkov:skip=CKV_AWS_272:Code signing is bypassed for this environment. Pipeline integrity is maintained via GitHub Actions OIDC identity validation and branch protection rules.
  # checkov:skip=CKV_AWS_173:KMS encryption is bypassed in dev to eliminate custom key costs; default cloud security is sufficient
  # checkov:skip=CKV_AWS_116:Uses redrive policy with SQS DLQ for handling failed events instead of Lambda Destinations to allow for easier debugging and reprocessing of failed events during development without needing to set up additional infrastructure components.

  depends_on = [aws_cloudwatch_log_group.api_logs]
}


# 4. THE ASYNCHRONOUS BACKGROUND QUEUE WORKER
resource "aws_lambda_function" "queue_worker" {
  function_name = "asgard-${var.environment}-queue-worker"
  description   = "Worker processing decoupled heavy restaurant booking workloads from SQS"
  role          = aws_iam_role.lambda_exec.arn

  s3_bucket = var.s3_bucket_id
  s3_key    = var.api_artifact_key != "" ? var.api_artifact_key : var.s3_bootstrap_key

  runtime     = "python3.11"
  handler     = "worker.handler" # The variable/function in application code to execute (Entry point for SQS-triggered processing)
  timeout     = 60               # Extended lifecycle limit for handling batch processing retries
  memory_size = 512

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_sg_id]
  }

  # Restricts this function to a safe maximum, protecting the rest of your AWS account pool from being exhausted during traffic spikes.
 # reserved_concurrent_executions = var.lambda_concurrency_limit

  # Instructs AWS to capture performance metrics and downstream request traces.
  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      ENVIRONMENT         = var.environment
      APP_SECRETS_ARN     = var.app_secrets_arn
      DATABASE_SECRET_ARN = var.rds_secret_arn
      DEBUG               = "False"
      CI_MODE             = "True"
    }
  }

  # checkov:skip=CKV_AWS_272:Code signing is bypassed for this environment. Pipeline integrity is maintained via GitHub Actions OIDC identity validation and branch protection rules.
  # checkov:skip=CKV_AWS_173:KMS encryption is bypassed in dev to eliminate custom key costs; default cloud security is sufficient
  # checkov:skip=CKV_AWS_116:Uses redrive policy with SQS DLQ for handling failed events instead of Lambda Destinations to allow for easier debugging and reprocessing of failed events during development without needing to set up additional infrastructure components.
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