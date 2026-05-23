# =========================================================================
#  SECURITY MODULE OUTPUTS
#  Allows us to pass data from the Security module to other modules that depend on it, in the root module
# =========================================================================

output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "The specific AWS IAM role ARN that must be passed to your GitHub Actions configuration yaml."
}

output "app_secrets_arn" {
  value       = aws_secretsmanager_secret.app_secrets.arn
  description = "The absolute identifier pointer for the Django runtime Secrets Manager container."
}

output "cloudfront_waf_arn" {
  value       = aws_wafv2_web_acl.cloudfront_waf.arn
  description = "The global ARN handle of the edge firewall perimeter."
}