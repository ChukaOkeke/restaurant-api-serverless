# ==========================================
# ROOT MODULE FOR ENVIRONMENT ORCHESTRATION: ASGARD CUISINES
# ==========================================

# Create the VPC and its associated resources (subnets, route tables, security groups, interface endpoints etc.)
module "vpc" {
  source      = "./modules/vpc"

  # Overriding or explicitly declaring the configuration values, though it will default to what we wrote in the module variables if omitted
  environment = var.environment
  vpc_cidr    = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  db_port         = var.db_port
}