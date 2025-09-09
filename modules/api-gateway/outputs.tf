# =============================================================================
# BACKEND MODULE OUTPUTS
# =============================================================================

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.api_gateway.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.api_gateway.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.api_gateway.zone_id
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.api_gateway.arn
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = "https://${aws_lb.api_gateway.dns_name}"
}

output "api_gateway_domain" {
  description = "Custom domain of the API Gateway (if configured)"
  value       = var.hosted_zone_id != null ? "https://api.${var.domain_name}" : null
}

output "ssl_certificate_arn" {
  description = "ARN of the SSL certificate"
  value       = var.ssl_certificate_arn != null ? var.ssl_certificate_arn : (length(aws_acm_certificate.api_gateway) > 0 ? aws_acm_certificate.api_gateway[0].arn : null)
}
