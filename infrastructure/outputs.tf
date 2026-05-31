# =========================================================================
#                   ROOT LEVEL OUTPUTS 
# =========================================================================

output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "The primary production VPC identifier."
}

output "database_endpoint" {
  value       = module.database.cluster_endpoint
  description = "The routing URL for your private Aurora Serverless v2 PostgreSQL cluster."
}

output "database_credentials_secret_arn" {
  value       = module.database.rds_secret_arn
  description = "The AWS Secrets Manager ARN managing your RDS master credentials."
}

output "github_actions_deployment_role_arn" {
  value       = module.security.github_actions_role_arn
  description = "Inject this ARN straight into your github workflow configurations."
}

output "bucket_name" {
  value       = module.storage.bucket_name # Adjust path based on your module structure
  description = "The S3 bucket name for CI/CD uploads"
}

output "api_function_name" {
  value = module.compute.web_api_function_name # Adjust based on your module outputs
}

output "static_bucket_name" {
  value       = module.storage.static_assets_bucket_id
  description = "The S3 bucket name for static assets, exposed for CI/CD synchronization."
}