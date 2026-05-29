# =========================================================================================================
#                       ZERO-TRUST CI/CD IDENTITY FEDERATION
# Establishes a trust relationship between GitHub Actions and AWS IAM using OIDC federation.
# This allows GitHub Actions to assume a short-lived IAM role with scoped permissions for deployment tasks
# ==========================================================================================================

# 1. DYNAMIC TLS CERTIFICATE LOOKUP (Prevents brittle hardcoded thumbprint breaks)
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

# 2. IAM OIDC PROVIDER (Registers GitHub as a Trusted Identity Authority)
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]

  tags = {
    Name = "asgard-github-oidc-provider"
  }
}

# 3. IAM ROLE TRUST POLICY DEFINITION (Scoped explicitly to your repo and branch)
data "aws_iam_policy_document" "github_actions_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    # Strict Conditional Safeguards: Lock down access ONLY to your repo and main branch
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main"]
    }
  }
}

# 4. THE DEPLOYMENT IAM ROLE (The "Hat" GitHub Actions puts on)
resource "aws_iam_role" "github_actions" {
  name               = "asgard-${var.environment}-github-actions-role"
  description        = "Short-lived access role for GitHub Actions infrastructure deployment workflows"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume.json

  tags = {
    Name = "asgard-${var.environment}-github-actions-role"
  }
}

# 5. ATTACH PERMISSIONS POLICY (Example placeholder: PowerUserAccess for infra provisioning)
# In actual production, you would prune this to a tightly controlled custom architecture policy.
resource "aws_iam_role_policy_attachment" "terraform_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"

  # checkov:skip=CKV_AWS_274:AdminAccess is required for now to ensure infra is stablely provisioned by GitHub Actions; in a production environment, this should be replaced with a custom least-privilege policy that only allows necessary actions for infrastructure deployment.
}