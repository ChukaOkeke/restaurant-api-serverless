# ===============================================================================================
# WAF CONFIGURATION FOR CLOUDFRONT DISTRIBUTION (Must be in us-east-1 for global edge acceptance)
# ===============================================================================================

resource "aws_wafv2_web_acl" "cloudfront_waf" {
  provider = aws.us_east_1 # Crucial: Must be instantiated in N. Virginia

  name        = "asgard-${var.environment}-cloudfront-waf"
  description = "Edge firewall containing rate limiting policies for CloudFront"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # RULE: Anti-Brute Force / DDoS Rate Limiting
  rule {
    name     = "IPRateLimit"
    priority = 1
    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 300 # Max requests per 5 minutes per single IP address
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AsgardApiIPRateLimitMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "AsgardCloudFrontWafGlobalMetric"
    sampled_requests_enabled   = true
  }

  # checkov:skip=CKV_AWS_192:Log4j protection is bypassed because the application stack utilizes a pure Python runtime environment, making Java-based Log4jshell exploits zero-risk for this infrastructure.

  tags = {
    Name = "asgard-${var.environment}-cloudfront-waf"
  }
}