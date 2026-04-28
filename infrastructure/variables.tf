# Define the variables

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

