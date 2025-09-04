# =============================================================================
# VARIABLES - PRODUCTION ENVIRONMENT
# =============================================================================

# Environment Configuration
variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"
  
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
  default     = "10.1.0.0/16"  # Different CIDR for production
}

variable "availability_zone_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 3  # More AZs for production
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for cost optimization"
  type        = bool
  default     = false  # Multiple NAT gateways for production HA
}

# EKS Configuration
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "farmers-market-prod"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "cluster_endpoint_public_access" {
  description = "Whether the EKS cluster endpoint is publicly accessible"
  type        = bool
  default     = false  # Private endpoint for production security
}

# Node Group Configuration (Production-ready)
variable "instance_types" {
  description = "EC2 instance types for the node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "capacity_type" {
  description = "Type of capacity for the node group"
  type        = string
  default     = "ON_DEMAND"  # On-demand instances for production stability
}

variable "min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 2  # Minimum 2 nodes for HA
}

variable "max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 5
}

variable "desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 3  # 3 nodes for production
}

variable "disk_size" {
  description = "Size of the EBS volume in GB"
  type        = number
  default     = 50  # Larger disk for production
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
  default     = true  # Enabled for production
}

# Tags
variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}