# ============================================================================================
#       INGRESS COMPONENTS FOR HANDLING EXTERNAL TRAFFIC: ROUTE 53, CLOUDFRONT & API GATEWAY  
# ============================================================================================

# 1. ROUTE 53 AUTOMATED HOSTED ZONE DISCOVERY (Fetches asgardcuisines.link)
data "aws_route53_zone" "primary" {
  name         = var.domain_name
  private_zone = false
}


# 2. AWS CERTIFICATE MANAGER (Scoped to the Apex Domain: asgardcuisines.link)
resource "aws_acm_certificate" "api_cert" {
  provider          = aws.us_east_1 
  domain_name       = var.domain_name 
  validation_method = "DNS"

  tags = {
    Name = "asgard-${var.environment}-edge-tls-cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Automated Record Provisioning for Domain Identity Proofing Challenge
resource "aws_route53_record" "cert_validation_record" {
  for_each = {
    for dvo in aws_acm_certificate.api_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.primary.zone_id
}

# Managed Validation Structural Barrier Waiter
resource "aws_acm_certificate_validation" "api_cert_verify" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.api_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation_record : record.fqdn]
}


# 3. AMAZON API GATEWAY (Low-Latency Native HTTP V2 Regional Core Engine)
resource "aws_apigatewayv2_api" "http_gateway" {
  name          = "asgard-${var.environment}-http-gateway"
  protocol_type = "HTTP"
  description   = "Clean regional proxy backend delivering requests straight into Lambda"

  tags = {
    Name = "asgard-${var.environment}-http-gateway"
  }
}

# Production CloudWatch Log Ingestion Target for Api Gateway Tracking
resource "aws_cloudwatch_log_group" "gateway_logs" {
  name              = "/aws/apigateway/asgard-${var.environment}-http-gateway"
  retention_in_days = 14
}

# Core Gateway Runtime Dynamic Routing Interface Stage
resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.http_gateway.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.gateway_logs.arn
    format          = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }
}

# Integration Binding: Maps Gateway interface capabilities directly to Web Python Lambda Core
resource "aws_apigatewayv2_integration" "lambda_link" {
  api_id                 = aws_apigatewayv2_api.http_gateway.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.web_api_function_arn
  integration_method     = "POST"
  payload_format_version = "2.0" 
}

# Catch-All Gateway Routing Strategy
resource "aws_apigatewayv2_route" "catch_all_route" {
  api_id    = aws_apigatewayv2_api.http_gateway.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_link.id}"
}

# Execution Privilege Delegation (Lambda resource policy to allow API Gateway to invoke the function)
resource "aws_lambda_permission" "gateway_invoke_clearance" {
  statement_id  = "AllowAsgardGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.web_api_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_gateway.execution_arn}/*/*"
}


# 4. CLOUDFRONT EDGE ROUTER (For Dual Origins & Path Routing)

# Origin Access Control (OAC) to securely allow CloudFront to read from your private S3 bucket
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "asgard-${var.environment}-s3-oac"
  description                       = "OAC for static assets bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution with Dual Origins (API Gateway & S3) and Path-Based Routing
resource "aws_cloudfront_distribution" "api_cdn" {
  enabled         = true
  is_ipv6_enabled = true
  price_class     = "PriceClass_100" 
  web_acl_id      = var.cloudfront_waf_arn  # Binds WAF rate limits at the edge

  aliases = [var.domain_name] # Using the apex domain

  # ORIGIN 1: The Compute Backend (API Gateway)
  origin {
    # Strips out https:// protocol prefixes to expose clean domain routing handles
    domain_name = replace(aws_apigatewayv2_api.http_gateway.api_endpoint, "https://", "")
    origin_id   = "APIGatewayOrigin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only" # Enforces Segment 2 security bounds (CloudFront to API Gateway communication must be encrypted)
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # ORIGIN 2: The Static Asset Storage (S3 Bucket)
  origin {
    domain_name              = var.static_bucket_regional_domain_name
    origin_id                = "S3StaticBucketOrigin"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
  }

  # BEHAVIOR 1: Route /static/* traffic instantly to S3 (Bypasses Lambda)
  ordered_cache_behavior {
    path_pattern     = "/static/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3StaticBucketOrigin"
    viewer_protocol_policy = "redirect-to-https" # Enforces Segment 1 client security edge (redirects all HTTP traffic to HTTPS)

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 86400    # Cache for 1 day
    max_ttl     = 31536000 # Max cache 1 year
  }

  # DEFAULT BEHAVIOR: Route everything else (API & HTML Pages) to Django
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "APIGatewayOrigin"
    viewer_protocol_policy = "redirect-to-https" # Enforces Segment 1 client security edge (redirects all HTTP traffic to HTTPS)

    forwarded_values {
      query_string = true
      headers      = ["*"] 

      cookies {
        forward = "all"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.api_cert_verify.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Name = "asgard-${var.environment}-api-cdn"
  }
}


# 5. ROUTE 53 SYSTEM POINTER CANONICAL LINK (Points Apex directly to Edge)
resource "aws_route53_record" "api_dns_pointer" {
  name            = var.domain_name
  type            = "A"
  zone_id         = data.aws_route53_zone.primary.zone_id
  allow_overwrite = true

  alias {
    name                   = aws_cloudfront_distribution.api_cdn.domain_name
    zone_id                = aws_cloudfront_distribution.api_cdn.hosted_zone_id
    evaluate_target_health = false
  }
}


# 6. ORIGIN ACCESS CONTROL (OAC) BUCKET POLICY
# Placed here to break the Terraform circular dependency between Storage and Ingress
resource "aws_s3_bucket_policy" "static_assets_oac_policy" {
  # We use the id passed from the storage module via the root
  bucket = split(":::", var.static_bucket_arn)[1] 

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipalReadOnly"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${var.static_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.api_cdn.arn
          }
        }
      }
    ]
  })
}