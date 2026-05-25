# ========================================================================================================
#  INGRESS MODULE OUTPUTS
#  Allows us to pass data from the Ingress module to other modules that depend on it, in the root module
# ========================================================================================================

output "api_gateway_regional_endpoint" {
  value       = aws_apigatewayv2_api.http_gateway.api_endpoint
  description = "The raw regional URL generated natively by AWS API Gateway."
}