# =============================================================================
# KONG MODULE VARIABLES
# =============================================================================

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

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

variable "enable_kong_plugins" {
  description = "Enable additional Kong plugins"
  type        = list(string)
  default     = ["cors", "rate-limiting", "request-transformer", "prometheus"]
}

variable "kong_replicas" {
  description = "Number of Kong proxy replicas"
  type        = number
  default     = 2
}

variable "kong_database_replicas" {
  description = "Number of Kong database replicas"
  type        = number
  default     = 1
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
