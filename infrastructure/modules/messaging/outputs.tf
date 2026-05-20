# =========================================================================
#  MESSAGING MODULE OUTPUTS
#  Allows us to pass data from the Messaging module to other modules that depend on it, in the root module
# =========================================================================

output "queue_id" {
  value       = aws_sqs_queue.booking_queue.id
  description = "The URL of the primary booking SQS queue."
}

output "queue_arn" {
  value       = aws_sqs_queue.booking_queue.arn
  description = "The absolute ARN of the primary booking SQS queue."
}

output "dlq_id" {
  value       = aws_sqs_queue.booking_dlq.id
  description = "The URL of the booking Dead Letter Queue."
}

output "dlq_arn" {
  value       = aws_sqs_queue.booking_dlq.arn
  description = "The absolute ARN of the booking Dead Letter Queue."
}