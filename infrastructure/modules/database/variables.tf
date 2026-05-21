# =========================================================================
#  CONFIGURATIONS FOR THE AURORA DATABASE MODULE
# =========================================================================
variable "environment" {
  type        = string
  description = "Deployment environment name"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC where the database will reside"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for the DB Subnet Group"
}

variable "database_sg_id" {
  type        = string
  description = "The Security Group ID chained to allow inbound traffic from Lambda"
}