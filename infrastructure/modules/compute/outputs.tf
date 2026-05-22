# ========================================================================================================
#  COMPUTE MODULE OUTPUTS
#  Allows us to pass data from the Compute module to other modules that depend on it, in the root module
# ========================================================================================================

output "web_api_function_arn" {
  value       = aws_lambda_function.web_api.arn
  description = "The absolute identifier ARN of your primary HTTP handling Web API Lambda function."
}

output "web_api_function_name" {
  value       = aws_lambda_function.web_api.function_name
  description = "The string name identifier of the HTTP handling API function container."
}

output "worker_function_arn" {
  value       = aws_lambda_function.queue_worker.arn
  description = "The absolute identifier ARN of your background SQS queue worker engine."
}