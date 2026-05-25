# =========================================================================
#       CONFIGURATION VARIABLES FOR THE INGRESS MODULE
# =========================================================================

variable "environment" {
  type        = string
  description = "The deployment environment name (e.g., production, staging)"
}

variable "domain_name" {
  type        = string
  description = "The primary root domain name hosted in Route 53 (e.g., asgardcuisines.com)"
}

variable "web_api_function_arn" {
  type        = string
  description = "The absolute identifier ARN of the synchronous Web API Lambda function"
}

variable "web_api_function_name" {
  type        = string
  description = "The string name identifier of the HTTP handling API function container"
}

variable "cloudfront_waf_arn" {
  type        = string
  description = "The absolute identifier ARN of the CloudFront WAF Web ACL to attach to the distribution for edge security"
}

variable "static_bucket_regional_domain_name" {
  description = "The regional domain name of the S3 bucket storing static assets"
  type        = string
}

variable "static_bucket_arn" {
  description = "The ARN of the static assets bucket (needed for the OAC resource policy)"
  type        = string
}