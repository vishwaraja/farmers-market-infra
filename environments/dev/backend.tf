# =============================================================================
# TERRAFORM BACKEND CONFIGURATION - DEV ENVIRONMENT
# =============================================================================
# This file configures the S3 backend for storing Terraform state
# Each environment has its own state file to prevent conflicts

terraform {
  backend "s3" {
    # S3 bucket for storing state (must be created manually or via bootstrap)
    bucket         = "farmers-market-terraform-state-dev"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    
    # DynamoDB table for state locking (must be created manually or via bootstrap)
    dynamodb_table = "farmers-market-terraform-locks-dev"
    encrypt        = true
    
    # Additional security
    kms_key_id = "alias/terraform-state-key-dev"
  }
}