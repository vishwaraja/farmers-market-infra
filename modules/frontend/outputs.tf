# Frontend Module Outputs

output "s3_bucket_name" {
  description = "Name of the S3 bucket for frontend hosting"
  value       = aws_s3_bucket.frontend.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for frontend hosting"
  value       = aws_s3_bucket.frontend.arn
}

output "s3_bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = aws_s3_bucket.frontend.bucket_domain_name
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.frontend.id
}

output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.frontend.arn
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.frontend.domain_name
}

output "cloudfront_url" {
  description = "URL of the CloudFront distribution"
  value       = "https://${aws_cloudfront_distribution.frontend.domain_name}"
}

output "frontend_url" {
  description = "Frontend URL (CloudFront or custom domain)"
  value       = var.custom_domain != null ? "https://${var.custom_domain}" : "https://${aws_cloudfront_distribution.frontend.domain_name}"
}

output "deploy_role_arn" {
  description = "ARN of the IAM role for frontend deployment"
  value       = aws_iam_role.frontend_deploy.arn
}

output "deploy_role_name" {
  description = "Name of the IAM role for frontend deployment"
  value       = aws_iam_role.frontend_deploy.name
}
