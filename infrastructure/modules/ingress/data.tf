# =========================================================================
#                       DATA SOURCES
# =========================================================================

# ROUTE 53 AUTOMATED HOSTED ZONE DISCOVERY (Fetches asgardcuisines.link)
data "aws_route53_zone" "primary" {
  name         = var.domain_name
  private_zone = false
}

# CLOUD FRONT SECURITY HEADERS POLICY (AWS Managed)
data "aws_cloudfront_response_headers_policy" "security_headers" {
  name = "Managed-SecurityHeadersPolicy"
}