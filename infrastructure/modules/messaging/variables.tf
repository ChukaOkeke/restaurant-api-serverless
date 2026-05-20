# =========================================================================
#       CONFIGURATION VARIABLES FOR THE MESSAGING MODULE
# =========================================================================

variable "environment" {
  type        = string
  description = "The deployment environment name (e.g., production, staging)"
}

variable "queue_delay_seconds" {
  type        = number
  description = "The time in seconds for which the delivery of all messages in the queue is delayed."
}

variable "max_message_size" {
  type        = number
  description = "The limit of how many bytes a message can contain before Amazon SQS rejects it."
}

variable "queue_retention_seconds" {
  type        = number
  description = "The number of seconds Amazon SQS retains a message in the primary queue."
}

variable "visibility_timeout_seconds" {
  type        = number
  description = "The visibility timeout for the queue in seconds."
}

variable "dlq_retention_seconds" {
  type        = number
  description = "The number of seconds Amazon SQS retains a message in the Dead Letter Queue."
}

variable "max_receive_count" {
  type        = number
  description = "The number of times a message is delivered to the source queue before being moved to the dead-letter queue."
}