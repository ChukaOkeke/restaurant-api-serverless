# ==========================================
# DEFINE THE GLOBAL PROJECT VARIABLES
# This file passes the configuration values from your execution environment down into the root orchestrator.
# ==========================================

variable "aws_profile" {
  description = "The AWS CLI profile to use"
  type = string
  default = "iamadmin-project"
}

variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type = string
  default = "eu-west-1"
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "production"
}