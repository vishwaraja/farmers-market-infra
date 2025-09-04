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

# Data sources for outputs
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}