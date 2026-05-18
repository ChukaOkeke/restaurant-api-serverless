# This file allows us to pass data from the VPC module to other modules that depend on it, in the root module.
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