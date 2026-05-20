# ==========================================
# DEFINE THE GLOBAL PROJECT VARIABLES
# This file passes the configuration values from your execution environment down into the root orchestrator.
# ==========================================

variable "aws_profile" {
  description = "The AWS CLI profile to use"
  type        = string
  default     = "iamadmin-project"
}

variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "production"
}


# VPC CONFIGURATION VALUES
variable "vpc_cidr" {
  type        = string
  description = "Base CIDR block for the custom VPC"
  default     = "10.16.0.0/16"
}

variable "public_subnets" {
  type        = map(string)
  description = "Public subnets per availability zone"
  default = {
    "eu-west-1a" = "10.16.1.0/24"
    "eu-west-1b" = "10.16.2.0/24"
    "eu-west-1c" = "10.16.3.0/24"
  }
}

variable "private_subnets" {
  type        = map(string)
  description = "Private subnets per availability zone"
  default = {
    "eu-west-1a" = "10.16.10.0/24"
    "eu-west-1b" = "10.16.11.0/24"
    "eu-west-1c" = "10.16.12.0/24"
  }
}

variable "db_port" {
  type        = number
  description = "The network port for the database cluster"
  default     = 5432 # Defaulting to PostgreSQL for clean setup
}


# MESSAGING CONFIGURATION VALUES (Asynchronous Queue Tuning)

variable "queue_delay_seconds" {
  type        = number
  default     = 0
}

variable "max_message_size" {
  type        = number
  default     = 262144 # 256 KB (AWS Max standard)
}

variable "queue_retention_seconds" {
  type        = number
  default     = 345600 # 4 Days
}

variable "visibility_timeout_seconds" {
  type        = number
  default     = 30 # Matches standard default Lambda timeout nicely
}

variable "dlq_retention_seconds" {
  type        = number
  default     = 1209600 # 14 Days (Max allowable to store errors for investigation)
}

variable "max_receive_count" {
  type        = number
  default     = 5 # Retry 5 times before failing to DLQ
}