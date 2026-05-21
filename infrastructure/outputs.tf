# =========================================================================
#                   ROOT LEVEL OUTPUTS 
# =========================================================================

output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "The primary production VPC identifier."
}

output "database_endpoint" {
  value       = module.aurora.cluster_endpoint
  description = "The routing URL for your private Aurora Serverless v2 PostgreSQL cluster."
}

output "database_credentials_secret_arn" {
  value       = module.aurora.rds_secret_arn
  description = "The AWS Secrets Manager ARN managing your RDS master credentials."
}

output "github_actions_deployment_role_arn" {
  value       = module.security.github_actions_role_arn
  description = "Inject this ARN straight into your github workflow configurations."
}