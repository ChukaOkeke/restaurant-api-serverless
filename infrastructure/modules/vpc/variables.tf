# Explicit configuration values for the VPC module
variable "environment" {
  type        = string
  description = "Deployment environment name"
}

variable "vpc_cidr" {
  type        = string
  description = "The primary IPv4 CIDR block for the VPC"
}

variable "public_subnets" {
  type = map(string)
  description = "Map of Availability Zones to Public Subnet IPv4 CIDRs"
}

variable "private_subnets" {
  type = map(string)
  description = "Map of Availability Zones to Private Subnet IPv4 CIDRs"
}