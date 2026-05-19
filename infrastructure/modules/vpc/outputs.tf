# =========================================================================
#  VPC MODULE OUTPUTS
#  Allows us to pass data from the VPC module to other modules that depend on it, in the root module
# =========================================================================

# VPC ID OUTPUTS
output "vpc_id" {
  value       = aws_vpc.asgard_vpc.id
  description = "The ID of the main VPC"
}

output "public_subnet_ids" {
  value       = [for subnet in aws_subnet.public_sn : subnet.id]
  description = "List of IDs of the public subnets"
}

output "private_subnet_ids" {
  value       = [for subnet in aws_subnet.private_sn : subnet.id]
  description = "List of IDs of the private subnets"
}


# SECURITY GROUP ID OUTPUTS
output "lambda_sg_id" {
  value       = aws_security_group.lambda.id
  description = "The Security Group ID to attach to Lambda functions"
}

output "database_sg_id" {
  value       = aws_security_group.database.id
  description = "The Security Group ID to attach to the Aurora DB"
}

output "vpc_endpoints_sg_id" {
  value       = aws_security_group.vpc_endpoints.id
  description = "The Security Group ID attached to the VPC Endpoints"
}

output "bastion_sg_id" {
  value       = aws_security_group.bastion.id
  description = "The Security Group ID attached to the management bastion host perimeter."
}


# ROUTING & ENDPOINT OUTPUTS
output "private_route_table_id" {
  value       = aws_route_table.private_rt.id
  description = "The ID of the private route table (needed for Gateway Endpoints later)"
}

output "vpc_interface_endpoint_ids" {
  value       = [for endpoint in aws_vpc_endpoint.interfaces : endpoint.id]
  description = "List of unique identifiers for the provisioned SQS, Secrets Manager, and SES Interface Endpoints."
}