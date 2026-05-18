# ==========================================
# ROOT PROVIDER CONFIGURATIONS & DEFAULT TAGS (RECOMMENDED FOR FINOPS)
# This file initializes the downloaded AWS provider binary and applies the operational rules, like the region and AWS account selection, and the global FinOps tagging strategy.
# ==========================================

provider "aws" {
  region = var.aws_region
  profile = var.aws_profile # Specify the AWS CLI profile 
  # Access keys can be set in the environment variables or through the AWS CLI configuration

  # Cascades the granular tagging strategy down to every single sub-resource
  default_tags {
    tags = {
      Project     = "Restaurant-API"
      CostCenter  = "Engineering"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}