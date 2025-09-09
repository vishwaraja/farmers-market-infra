# =============================================================================
# FRONTEND MODULE VARIABLES
# =============================================================================

variable "name_prefix" {
  description = "Prefix for resource names"
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

variable "price_class" {
  description = "CloudFront price class for cost optimization"
  type        = string
  default     = "PriceClass_100"  # US, Canada, Europe
  
  validation {
    condition = contains([
      "PriceClass_All",
      "PriceClass_200", 
      "PriceClass_100"
    ], var.price_class)
    error_message = "Price class must be one of: PriceClass_All, PriceClass_200, PriceClass_100."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
