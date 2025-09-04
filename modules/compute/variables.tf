# =============================================================================
# COMPUTE MODULE VARIABLES
# =============================================================================

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.28"
  
  validation {
    condition     = can(regex("^1\\.(2[0-8]|1[0-9]|[0-9])$", var.kubernetes_version))
    error_message = "Kubernetes version must be a valid 1.x version."
  }
}

variable "vpc_id" {
  description = "ID of the VPC where the cluster will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the cluster"
  type        = list(string)
}

variable "cluster_security_group_id" {
  description = "ID of the security group for the EKS cluster"
  type        = string
}

variable "workers_security_group_id" {
  description = "ID of the security group for the EKS worker nodes"
  type        = string
}

variable "cluster_endpoint_public_access" {
  description = "Whether the EKS cluster endpoint is publicly accessible"
  type        = bool
  default     = true
}

variable "instance_types" {
  description = "List of EC2 instance types for the node group"
  type        = list(string)
  default     = ["t3.small"]
}

variable "capacity_type" {
  description = "Type of capacity for the node group (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
  
  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.capacity_type)
    error_message = "Capacity type must be either ON_DEMAND or SPOT."
  }
}

variable "min_size" {
  description = "Minimum number of nodes in the node group"
  type        = number
  default     = 1
  
  validation {
    condition     = var.min_size >= 0
    error_message = "Minimum size must be a non-negative number."
  }
}

variable "max_size" {
  description = "Maximum number of nodes in the node group"
  type        = number
  default     = 3
  
  validation {
    condition     = var.max_size >= var.min_size
    error_message = "Maximum size must be greater than or equal to minimum size."
  }
}

variable "desired_size" {
  description = "Desired number of nodes in the node group"
  type        = number
  default     = 2
  
  validation {
    condition     = var.desired_size >= var.min_size && var.desired_size <= var.max_size
    error_message = "Desired size must be between minimum and maximum size."
  }
}

variable "disk_size" {
  description = "Size of the EBS volume in GB"
  type        = number
  default     = 20
  
  validation {
    condition     = var.disk_size >= 20
    error_message = "Disk size must be at least 20 GB."
  }
}

variable "node_labels" {
  description = "Labels to apply to the nodes"
  type        = map(string)
  default     = {}
}

variable "node_taints" {
  description = "Taints to apply to the nodes"
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}

variable "enable_ebs_csi" {
  description = "Enable EBS CSI driver for persistent volumes"
  type        = bool
  default     = true
}

variable "create_additional_iam_role" {
  description = "Create additional IAM role for node groups"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
