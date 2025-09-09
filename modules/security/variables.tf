variable "project_name" {
  description = "Name of the project (used for resource naming and tagging)"
  type        = string
  default     = "farmers-market"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"
}

variable "enable_cross_account_access" {
  description = "Enable cross-account access policies for future multi-account setup"
  type        = bool
  default     = true
}

variable "enable_mfa_enforcement" {
  description = "Enable MFA enforcement for all IAM users"
  type        = bool
  default     = true
}

variable "allowed_regions" {
  description = "List of allowed AWS regions for resource access"
  type        = list(string)
  default     = ["us-east-1", "us-west-2"]
}

variable "devops_users" {
  description = "List of IAM usernames to add to the devops group"
  type        = list(string)
  default     = []
}

variable "admin_users" {
  description = "List of IAM usernames to add to the admin group"
  type        = list(string)
  default     = []
}

variable "developer_users" {
  description = "List of IAM usernames to add to the developers group"
  type        = list(string)
  default     = []
}

variable "qa_users" {
  description = "List of IAM usernames to add to the qa-engineers group"
  type        = list(string)
  default     = []
}

variable "manager_users" {
  description = "List of IAM usernames to add to the managers group"
  type        = list(string)
  default     = []
}

variable "readonly_users" {
  description = "List of IAM usernames to add to the readonly group"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags to apply to all IAM resources"
  type        = map(string)
  default     = {}
}

variable "eks_oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider for service account roles"
  type        = string
  default     = ""
}

variable "kong_namespace" {
  description = "Kubernetes namespace for Kong deployment"
  type        = string
  default     = "kong"
}

variable "account_id" {
  description = "AWS Account ID for cross-account role trust relationships"
  type        = string
  default     = ""
}

variable "cross_account_external_id" {
  description = "External ID for cross-account role assumption"
  type        = string
  default     = ""
}
