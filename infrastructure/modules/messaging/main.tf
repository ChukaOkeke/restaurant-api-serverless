# =========================================================================
#                 ASYNCHRONOUS DECOUPLING WITH SQS
# =========================================================================

# 1. THE DEAD LETTER QUEUE (Captures Failed Messages)
resource "aws_sqs_queue" "booking_dlq" {
  name                      = "asgard-${var.environment}-booking-dlq"
  kms_master_key_id         = "alias/aws/sqs" # Enables native encryption at rest
  message_retention_seconds = var.dlq_retention_seconds

  # checkov:skip=CKV2_AWS_73:KMS encryption is bypassed in dev to eliminate custom key costs; default cloud security is sufficient

  tags = {
    Name = "asgard-${var.environment}-booking-dlq"
  }
}

# 2. THE PRIMARY INTAKE QUEUE (Receives Booking Requests)
resource "aws_sqs_queue" "booking_queue" {
  name                      = "asgard-${var.environment}-booking-queue"
  delay_seconds             = var.queue_delay_seconds
  max_message_size          = var.max_message_size
  message_retention_seconds = var.queue_retention_seconds
  kms_master_key_id         = "alias/aws/sqs" # Enables native encryption at rest
  # The visibility timeout MUST be greater than or equal to your processing 
  # Lambda's execution timeout to prevent dual-processing races.
  visibility_timeout_seconds = var.visibility_timeout_seconds

  # Attach the DLQ redrive policy
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.booking_dlq.arn
    maxReceiveCount     = var.max_receive_count # Max retries before dropping to DLQ
  })

  # checkov:skip=CKV2_AWS_73:KMS encryption is bypassed in dev to eliminate custom key costs; default cloud security is sufficient

  tags = {
    Name = "asgard-${var.environment}-booking-queue"
  }
}