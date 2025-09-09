# Frontend Module Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "farmers-market"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "custom_domain" {
  description = "Custom domain for the frontend (optional)"
  type        = string
  default     = null
}

variable "ssl_certificate_arn" {
  description = "ARN of the SSL certificate for custom domain (required if custom_domain is set)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
