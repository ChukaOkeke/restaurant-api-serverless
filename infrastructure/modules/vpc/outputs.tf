# =========================================================================
#  VPC MODULE OUTPUTS
#  Allows us to pass data from the VPC module to other modules that depend on it, in the root module
# =========================================================================
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

output "private_route_table_id" {
  value       = aws_route_table.private_rt.id
  description = "The ID of the private route table (needed for Gateway Endpoints later)"
}

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