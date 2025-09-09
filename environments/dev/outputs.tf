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

# Storage Information
output "storage_url" {
  description = "URL to access the static storage (frontend)"
  value       = module.storage.frontend_url
}

output "storage_s3_bucket" {
  description = "S3 bucket for static storage deployment"
  value       = module.storage.s3_bucket_id
}

output "storage_deployment_instructions" {
  description = "Instructions for deploying static content"
  value       = module.storage.deployment_instructions
}

# API Gateway Information
output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = module.api_gateway.api_gateway_url
}

output "api_gateway_dns_name" {
  description = "DNS name of the API Gateway"
  value       = module.api_gateway.alb_dns_name
}

output "target_group_arn" {
  description = "ARN of the target group for API services"
  value       = module.api_gateway.target_group_arn
}

# Services Information (Kong)
output "services_admin_url" {
  description = "Kong Admin API URL (internal)"
  value       = module.services.kong_admin_url
}

output "services_proxy_url" {
  description = "Kong Proxy URL (internal)"
  value       = module.services.kong_proxy_url
}

output "services_deployment_info" {
  description = "Services deployment information"
  value       = module.services.kong_deployment_info
}

output "services_connection_commands" {
  description = "Commands to connect to services"
  value       = module.services.kong_connection_commands
}

# Security Information (IAM)
output "security_groups" {
  description = "IAM groups created"
  value       = module.security.iam_groups_summary
}

output "security_policies" {
  description = "IAM policies created"
  value       = module.security.iam_policies_summary
}

output "service_roles" {
  description = "Service roles for AWS services"
  value = {
    eks_cluster_role = module.security.eks_cluster_role_name
    eks_node_role    = module.security.eks_node_role_name
    alb_controller_role = module.security.alb_controller_role_name
    cross_account_role = module.security.cross_account_role_name
  }
}

# Complete Application URLs
output "application_urls" {
  description = "Complete application URLs"
  value = {
    storage = module.storage.frontend_url
    api_gateway = module.api_gateway.api_gateway_url
    services_admin = module.services.kong_admin_url
    cluster  = "https://${module.compute.cluster_endpoint}"
  }
}