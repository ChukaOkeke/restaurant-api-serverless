# =========================================================================
#       CONFIGURATION VARIABLES FOR THE COMPUTE MODULE
# =========================================================================

variable "environment" {
  type        = string
  description = "The deployment environment name (e.g., production, staging)"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnets where the Lambda functions will execute to reach the DB"
}

variable "lambda_sg_id" {
  type        = string
  description = "The security group identifier assigned to the Lambda functions"
}

variable "s3_bucket_id" {
  type        = string
  description = "The S3 bucket name holding the Lambda deployment artifact zip"
}

variable "s3_bootstrap_key" {
  type        = string
  description = "The S3 object key pointing to the initial bootstrap zip file"
}

variable "sqs_queue_arn" {
  type        = string
  description = "The ARN of the primary SQS booking intake queue for the worker trigger"
}

variable "sqs_queue_id" {
  type        = string
  description = "The URL of the primary SQS booking intake queue"
}

variable "rds_secret_arn" {
  type        = string
  description = "The Secrets Manager secret ARN holding the auto-managed RDS root credentials"
}

variable "app_secrets_arn" {
  type        = string
  description = "The Secrets Manager secret ARN holding application specific variables"
}