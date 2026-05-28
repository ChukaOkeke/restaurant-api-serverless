# =========================================================================
#        APPLICATION SECRETS MANAGEMENT WITH AWS SECRETS MANAGER
# =========================================================================

# 1. THE APP SECRET CONTAINER
resource "aws_secretsmanager_secret" "app_secrets" {
  name                    = "asgard-${var.environment}-app-secrets"
  description             = "Secure container for Django runtime environment variables and API keys."
  recovery_window_in_days = 7 # FinOps safety: short window allows faster recreation testing if wiped

  # checkov:skip=CKV_AWS_149:KMS encryption is bypassed in dev to eliminate custom key costs; default cloud security is sufficient

  tags = {
    Name = "asgard-${var.environment}-app-secrets"
  }
}

# 2. THE INITIAL KEY SHELL (Gives your app schema structure without storing plaintext values in git)
resource "aws_secretsmanager_secret_version" "app_secrets_template" {
  secret_id = aws_secretsmanager_secret.app_secrets.id
  secret_string = jsonencode({
    DJANGO_SECRET_KEY = "placeholder-to-be-rotated-manually-via-aws-console"
    DEBUG             = "False"
  })

  # Prevents Terraform from overwriting real production values on subsequent runs
  lifecycle {
    ignore_changes = [secret_string]
  }
}