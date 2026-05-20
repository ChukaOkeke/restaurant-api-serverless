# =========================================================================
#  AURORA DB MODULE OUTPUTS
#  Allows us to pass data from the Aurora module to other modules that depend on it, in the root module
# =========================================================================

output "cluster_endpoint" {
  value       = aws_rds_cluster.aurora_cluster.endpoint
  description = "The writer endpoint for the Aurora Serverless v2 cluster. Use this in your Django settings connection configuration."
}

output "cluster_id" {
  value       = aws_rds_cluster.aurora_cluster.id
  description = "The ID of the Aurora cluster container."
}

output "database_name" {
  value       = aws_rds_cluster.aurora_cluster.database_name
  description = "The default relational database name created at initialization (e.g., asgard_db)."
}

output "master_username" {
  value       = aws_rds_cluster.aurora_cluster.master_username
  description = "The administrative master database username."
}

# SECURITY & SECRETS HANDOFFS (For Lambda runtime integration)
output "rds_secret_arn" {
  value       = aws_rds_cluster.aurora_cluster.master_user_secret[0].secret_arn
  description = "The absolute ARN of the AWS Secrets Manager secret containing the auto-generated database administrative credentials."
}