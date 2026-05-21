# =========================================================================
#       CONFIGURATION VARIABLES FOR THE SECURITY MODULE
# =========================================================================

variable "environment" {
  type        = string
  description = "The deployment environment name (e.g., production, staging)"
}

variable "github_org" {
  type        = string
  description = "The GitHub username or organizational owner of the repository (e.g., your-github-username)."
}

variable "github_repo" {
  type        = string
  description = "The exact name of your GitHub repository hosting the application code."
}