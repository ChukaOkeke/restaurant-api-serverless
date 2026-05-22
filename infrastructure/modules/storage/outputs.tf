# =========================================================================
#  STORAGE MODULE OUTPUTS
#  Allows us to pass data from the Storage module to other modules (like compute) that depend on it, in the root module
# =========================================================================

output "bucket_name" {
  value       = aws_s3_bucket.lambda_artifacts.id
  description = "The globally unique string name of the artifact storage bucket."
}

output "bucket_arn" {
  value       = aws_s3_bucket.lambda_artifacts.arn
  description = "The absolute ARN identifier of the artifact storage bucket."
}

output "bootstrap_object_key" {
  value       = aws_s3_object.lambda_bootstrap_artifact.key
  description = "The target key location containing our safe bootstrap payload container."
}