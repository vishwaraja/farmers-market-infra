# =============================================================================
# SHARED LOCAL VALUES
# =============================================================================
# Common local values used across all environments and modules

locals {
  # Project metadata
  project_name = "farmers-market"
  project_owner = "farmers-market-team"
  
  # Common naming patterns
  name_prefix = "${var.environment}-${local.project_name}"
  
  # Common tags applied to all resources
  common_tags = {
    Project     = local.project_name
    Environment = var.environment
    Owner       = local.project_owner
    ManagedBy   = "terraform"
    CreatedAt   = formatdate("YYYY-MM-DD", timestamp())
  }
  
  # Environment-specific configurations
  environment_configs = {
    dev = {
      instance_types = ["t3.small"]
      node_count     = 1
      use_spot       = true
      enable_logging = false
    }
    staging = {
      instance_types = ["t3.medium"]
      node_count     = 2
      use_spot       = true
      enable_logging = true
    }
    production = {
      instance_types = ["t3.medium"]
      node_count     = 3
      use_spot       = false
      enable_logging = true
    }
  }
  
  # Current environment configuration
  env_config = local.environment_configs[var.environment]
}
