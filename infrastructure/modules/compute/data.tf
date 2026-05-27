# =========================================================================
#                       DATA SOURCES
# =========================================================================

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Fetching the existing VPC configuration that our resources must bind to
data "aws_vpc" "selected" {
  filter {
    name   = "tag:Environment"
    values = [var.environment]
  }
}