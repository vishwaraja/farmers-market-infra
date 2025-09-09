# =============================================================================
# VARIABLES - DEV ENVIRONMENT
# =============================================================================

# Environment Configuration
variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

# Project Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "farmers-market"
}

# Networking Configuration
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zone_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 2
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for cost optimization"
  type        = bool
  default     = true
}

# EKS Configuration
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "farmers-market-dev"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "cluster_endpoint_public_access" {
  description = "Whether the EKS cluster endpoint is publicly accessible"
  type        = bool
  default     = true
}

# Node Group Configuration (Optimized for minimal microservices)
variable "instance_types" {
  description = "EC2 instance types for the node group"
  type        = list(string)
  default     = ["t3.small"]
}

variable "capacity_type" {
  description = "Type of capacity for the node group"
  type        = string
  default     = "SPOT"  # Use spot instances for cost optimization in dev
}

variable "min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 3
}

variable "desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 1  # Minimal for dev environment
}

variable "disk_size" {
  description = "Size of the EBS volume in GB"
  type        = number
  default     = 20
}

# Feature Flags
variable "enable_ebs_csi" {
  description = "Enable EBS CSI driver"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring"
  type        = bool
  default     = false  # Disabled for dev to save costs
}

variable "enable_alb_logs" {
  description = "Enable ALB access logs"
  type        = bool
  default     = false  # Disabled for dev to save costs
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 7
}

# Frontend Configuration
variable "frontend_price_class" {
  description = "CloudFront price class for cost optimization"
  type        = string
  default     = "PriceClass_100"  # US, Canada, Europe
}

# Optional: Custom domain configuration
# variable "frontend_domain" {
#   description = "Custom domain for the frontend"
#   type        = string
#   default     = null
# }

# variable "frontend_ssl_certificate_arn" {
#   description = "ARN of the SSL certificate for frontend"
#   type        = string
#   default     = null
# }

# variable "backend_domain" {
#   description = "Custom domain for the backend API"
#   type        = string
#   default     = null
# }

# variable "hosted_zone_id" {
#   description = "Route53 hosted zone ID"
#   type        = string
#   default     = null
# }

# variable "backend_ssl_certificate_arn" {
#   description = "ARN of the SSL certificate for backend"
#   type        = string
#   default     = null
# }

# Kong Configuration
variable "kong_database_password" {
  description = "Password for Kong database"
  type        = string
  default     = "kong-password-123"
  sensitive   = true
}

variable "kong_services" {
  description = "List of services to configure in Kong"
  type = list(object({
    name                = string
    url                 = string
    path                = string
    strip_path          = bool
    preserve_host       = bool
    rate_limit_minute   = number
    rate_limit_hour     = number
  }))
  default = [
    {
      name                = "user-service"
      url                 = "http://user-service.farmers-market.svc.cluster.local:80"
      path                = "/api/users"
      strip_path          = true
      preserve_host       = false
      rate_limit_minute   = 100
      rate_limit_hour     = 1000
    },
    {
      name                = "product-service"
      url                 = "http://product-service.farmers-market.svc.cluster.local:80"
      path                = "/api/products"
      strip_path          = true
      preserve_host       = false
      rate_limit_minute   = 100
      rate_limit_hour     = 1000
    },
    {
      name                = "order-service"
      url                 = "http://order-service.farmers-market.svc.cluster.local:80"
      path                = "/api/orders"
      strip_path          = true
      preserve_host       = false
      rate_limit_minute   = 50
      rate_limit_hour     = 500
    }
  ]
}

variable "enable_kong_admin" {
  description = "Enable Kong Admin API access"
  type        = bool
  default     = true
}

variable "kong_replicas" {
  description = "Number of Kong proxy replicas"
  type        = number
  default     = 2
}

# IAM Configuration
variable "enable_cross_account_access" {
  description = "Enable cross-account access for future multi-account setup"
  type        = bool
  default     = true
}

variable "enable_mfa_enforcement" {
  description = "Enable MFA enforcement for all IAM users"
  type        = bool
  default     = false
}

variable "cross_account_external_id" {
  description = "External ID for cross-account role assumption"
  type        = string
  default     = "farmers-market-cross-account-2024"
}

# IAM User Assignments
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

# Tags
variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}