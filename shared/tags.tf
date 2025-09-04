# =============================================================================
# STANDARDIZED TAGGING
# =============================================================================
# Centralized tagging strategy for consistent resource management

locals {
  # Base tags applied to all resources
  base_tags = {
    Project     = local.project_name
    Environment = var.environment
    Owner       = local.project_owner
    ManagedBy   = "terraform"
    Repository  = "farmers-market-infra"
  }
  
  # Cost allocation tags
  cost_tags = {
    CostCenter = "engineering"
    Budget     = var.environment == "production" ? "production" : "development"
  }
  
  # Security tags
  security_tags = {
    DataClassification = var.environment == "production" ? "confidential" : "internal"
    Compliance        = "required"
  }
  
  # Operational tags
  operational_tags = {
    BackupRequired = var.environment == "production" ? "true" : "false"
    Monitoring     = "enabled"
    AutoShutdown   = var.environment == "dev" ? "true" : "false"
  }
  
  # Combined tags for all resources
  all_tags = merge(
    local.base_tags,
    local.cost_tags,
    local.security_tags,
    local.operational_tags
  )
}
