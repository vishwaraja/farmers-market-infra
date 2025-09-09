# =============================================================================
# MAIN CONFIGURATION - PRODUCTION ENVIRONMENT
# =============================================================================
# This file orchestrates the deployment of all infrastructure components
# for the production environment

# Local values
locals {
  name_prefix = "${var.environment}-${var.project_name}"
  
  # Common tags
  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
      Owner       = "farmers-market-team"
    },
    var.additional_tags
  )
}

# Networking Module
module "networking" {
  source = "../../modules/networking"
  
  name_prefix                = local.name_prefix
  vpc_cidr                   = var.vpc_cidr
  availability_zone_count    = var.availability_zone_count
  single_nat_gateway         = var.single_nat_gateway
  eks_cluster_name           = var.cluster_name
  tags                       = local.common_tags
}

# Compute Module (EKS)
module "compute" {
  source = "../../modules/compute"
  
  name_prefix                        = local.name_prefix
  cluster_name                       = var.cluster_name
  kubernetes_version                 = var.kubernetes_version
  vpc_id                            = module.networking.vpc_id
  private_subnet_ids                = module.networking.private_subnet_ids
  cluster_security_group_id         = module.networking.eks_cluster_security_group_id
  workers_security_group_id         = module.networking.eks_workers_security_group_id
  cluster_endpoint_public_access    = var.cluster_endpoint_public_access
  instance_types                    = var.instance_types
  capacity_type                     = var.capacity_type
  min_size                          = var.min_size
  max_size                          = var.max_size
  desired_size                      = var.desired_size
  disk_size                         = var.disk_size
  enable_ebs_csi                    = var.enable_ebs_csi
  tags                              = local.common_tags
  
  depends_on = [module.networking]
}

# Storage Module (Static Hosting)
module "storage" {
  source = "../../modules/storage"
  
  name_prefix = local.name_prefix
  price_class = var.frontend_price_class
  tags        = local.common_tags
  
  # Optional: Custom domain configuration
  # custom_domain = var.frontend_domain
  # ssl_certificate_arn = var.frontend_ssl_certificate_arn
}

# API Gateway Module (Load Balancer + API Gateway)
module "api_gateway" {
  source = "../../modules/api-gateway"
  
  name_prefix           = local.name_prefix
  vpc_id               = module.networking.vpc_id
  public_subnet_ids    = module.networking.public_subnet_ids
  private_subnet_ids   = module.networking.private_subnet_ids
  enable_alb_logs      = var.enable_alb_logs
  log_retention_days   = var.log_retention_days
  tags                 = local.common_tags
  
  # Optional: Custom domain configuration
  # domain_name = var.backend_domain
  # hosted_zone_id = var.hosted_zone_id
  # ssl_certificate_arn = var.backend_ssl_certificate_arn
  
  depends_on = [module.networking]
}

# Services Module (Kong API Gateway)
module "services" {
  source = "../../modules/services"
  
  name_prefix = local.name_prefix
  kong_database_password = var.kong_database_password
  kong_services = var.kong_services
  enable_kong_admin = var.enable_kong_admin
  kong_replicas = var.kong_replicas
  tags = local.common_tags
  
  depends_on = [module.compute]
}

# Security Module (IAM)
module "security" {
  source = "../../modules/security"
  
  project_name = var.project_name
  environment  = var.environment
  aws_region   = data.aws_region.current.name
  
  # Cross-account configuration
  enable_cross_account_access = var.enable_cross_account_access
  account_id                  = data.aws_caller_identity.current.account_id
  cross_account_external_id   = var.cross_account_external_id
  
  # MFA configuration
  enable_mfa_enforcement = var.enable_mfa_enforcement
  
  # EKS OIDC configuration
  eks_oidc_provider_arn = module.compute.eks_oidc_provider_arn
  kong_namespace        = "kong"
  
  # User assignments
  devops_users     = var.devops_users
  admin_users      = var.admin_users
  developer_users  = var.developer_users
  qa_users         = var.qa_users
  manager_users    = var.manager_users
  readonly_users   = var.readonly_users
  
  tags = local.common_tags
  
  depends_on = [module.compute]
}

# Data sources for outputs
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}