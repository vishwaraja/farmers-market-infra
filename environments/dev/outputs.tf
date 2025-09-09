# =============================================================================
# OUTPUTS - DEV ENVIRONMENT
# =============================================================================

# Account Information
output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS Region"
  value       = data.aws_region.current.name
}

# VPC Information
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.networking.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

# EKS Cluster Information
output "cluster_id" {
  description = "ID of the EKS cluster"
  value       = module.compute.cluster_id
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.compute.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS cluster"
  value       = module.compute.cluster_endpoint
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for the EKS cluster"
  value       = module.compute.cluster_oidc_issuer_url
}

# Connection Commands
output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${data.aws_region.current.name} --name ${module.compute.cluster_name}"
}

output "cluster_info" {
  description = "Cluster information for easy access"
  value = {
    name    = module.compute.cluster_name
    region  = data.aws_region.current.name
    endpoint = module.compute.cluster_endpoint
  }
}

# Frontend Information
output "frontend_url" {
  description = "URL to access the frontend application"
  value       = module.frontend.frontend_url
}

output "frontend_s3_bucket" {
  description = "S3 bucket for frontend deployment"
  value       = module.frontend.s3_bucket_id
}

output "frontend_deployment_instructions" {
  description = "Instructions for deploying the frontend"
  value       = module.frontend.deployment_instructions
}

# Backend Information
output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = module.backend.api_gateway_url
}

output "api_gateway_dns_name" {
  description = "DNS name of the API Gateway"
  value       = module.backend.alb_dns_name
}

output "target_group_arn" {
  description = "ARN of the target group for backend services"
  value       = module.backend.target_group_arn
}

# Kong Information
output "kong_admin_url" {
  description = "Kong Admin API URL (internal)"
  value       = module.kong.kong_admin_url
}

output "kong_proxy_url" {
  description = "Kong Proxy URL (internal)"
  value       = module.kong.kong_proxy_url
}

output "kong_deployment_info" {
  description = "Kong deployment information"
  value       = module.kong.kong_deployment_info
}

output "kong_connection_commands" {
  description = "Commands to connect to Kong services"
  value       = module.kong.kong_connection_commands
}

# IAM Information
output "iam_groups" {
  description = "IAM groups created"
  value       = module.iam.iam_groups_summary
}

output "iam_policies" {
  description = "IAM policies created"
  value       = module.iam.iam_policies_summary
}

output "service_roles" {
  description = "Service roles for AWS services"
  value = {
    eks_cluster_role = module.iam.eks_cluster_role_name
    eks_node_role    = module.iam.eks_node_role_name
    alb_controller_role = module.iam.alb_controller_role_name
    cross_account_role = module.iam.cross_account_role_name
  }
}

# Complete Application URLs
output "application_urls" {
  description = "Complete application URLs"
  value = {
    frontend = module.frontend.frontend_url
    backend  = module.backend.api_gateway_url
    kong_admin = module.kong.kong_admin_url
    cluster  = "https://${module.compute.cluster_endpoint}"
  }
}