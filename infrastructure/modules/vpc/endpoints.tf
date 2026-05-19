# =========================================================================
# VPC INTERFACE ENDPOINTS (Private API Access for Serverless Components)
# =========================================================================

# Local helper to define the exact AWS service endpoints required by your backend
locals {
  interface_services = {
    sqs            = "com.amazonaws.eu-west-1.sqs"
    secretsmanager = "com.amazonaws.eu-west-1.secretsmanager"
    email          = "com.amazonaws.eu-west-1.email" # SES Interface Endpoint
  }
}

resource "aws_vpc_endpoint" "interfaces" {
  for_each = local.interface_services

  vpc_id            = aws_vpc.asgard_vpc.id
  service_name      = each.value
  vpc_endpoint_type = "Interface"

  # Bind the endpoints to all private subnets for Multi-AZ high availability
  subnet_ids = [for subnet in aws_subnet.private_sn : subnet.id]

  # Attach the chained security group that explicitly trusts our Lambda compute
  security_group_ids = [aws_security_group.vpc_endpoints.id]

  # CRITICAL: Enables private DNS hostname resolution (e.g., sqs.eu-west-1.amazonaws.com resolves to private IPs in the VPC instead of public endpoints) 
  # so your Python/Django SDK code doesn't need custom endpoint URL overrides.
  private_dns_enabled = true

  tags = {
    Name = "asgard-${var.environment}-${each.key}-endpoint"
  }
}


# =========================================================================
# AMAZON S3 GATEWAY ENDPOINT (Cost-Optimized FinOps Routing for Deployment Artifacts)
# =========================================================================
resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = aws_vpc.asgard_vpc.id
  service_name      = "com.amazonaws.eu-west-1.s3"
  vpc_endpoint_type = "Gateway"

  # Automatically injects the private S3 routing prefix list into our private route table
  route_table_ids = [aws_route_table.private_rt.id]

  tags = {
    Name = "asgard-${var.environment}-s3-gateway"
  }
}