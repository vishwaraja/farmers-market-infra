# =============================================================================
# KONG MODULE VERSION CONSTRAINTS
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}
