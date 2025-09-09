# Kong Services Configuration

This directory contains individual YAML configuration files for each service that will be routed through Kong API Gateway.

## 📁 **Directory Structure**

```
kong-services/
├── README.md              # This file
├── user-service.yml       # User service configuration
├── product-service.yml    # Product service configuration
├── order-service.yml      # Order service configuration
└── [service-name].yml     # Add new services here
```

## 🎯 **How to Add a New Service**

1. **Create a new YAML file** named `[service-name].yml`
2. **Use the following template:**

```yaml
# =============================================================================
# [SERVICE-NAME] KONG CONFIGURATION
# =============================================================================

name: service-name
url: http://service-name.farmers-market.svc.cluster.local:80

routes:
  - name: service-name-v1-route
    paths:
      - /v1/service-endpoint
    methods:
      - GET
      - POST
      - PUT
      - DELETE
      - PATCH
    strip_path: false
    preserve_host: false

plugins:
  - name: cors
    config:
      origins: ["*"]
      methods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"]
      credentials: true
  - name: rate-limiting
    config:
      minute: 100
      hour: 1000
      policy: local
  - name: request-transformer
    config:
      add:
        headers:
          - "X-Forwarded-By:Kong"
          - "X-Service:service-name"
```

## 🔧 **Configuration Options**

### **Service Definition**
- `name`: Unique service identifier
- `url`: Kubernetes service URL (format: `http://service-name.namespace.svc.cluster.local:port`)

### **Routes**
- `name`: Unique route identifier
- `paths`: Array of URL paths to match (e.g., `/v1/users`, `/api/products`)
- `methods`: HTTP methods to allow
- `strip_path`: Whether to remove the matched path before forwarding
- `preserve_host`: Whether to preserve the original host header

### **Common Plugins**

#### **CORS Plugin**
```yaml
- name: cors
  config:
    origins: ["*"]
    methods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"]
    credentials: true
    max_age: 3600
```

#### **Rate Limiting Plugin**
```yaml
- name: rate-limiting
  config:
    minute: 100    # Requests per minute
    hour: 1000     # Requests per hour
    policy: local
```

#### **JWT Authentication Plugin**
```yaml
- name: jwt
  config:
    secret_is_base64: false
    key_claim_name: iss
    algorithm: HS256
    anonymous: null
```

#### **Request Transformer Plugin**
```yaml
- name: request-transformer
  config:
    add:
      headers:
        - "X-Forwarded-By:Kong"
        - "X-Service:service-name"
```

## 🚀 **Deployment**

1. **Add/modify** a service YAML file
2. **Run Terraform** to apply changes:
   ```bash
   cd environments/dev
   terraform plan
   terraform apply
   ```
3. **Test the service** through Kong:
   ```bash
   curl -X GET http://kong-proxy:8000/v1/your-endpoint
   ```

## 📝 **Best Practices**

1. **Use versioned paths** (e.g., `/v1/users`, `/v2/users`)
2. **Set appropriate rate limits** based on service requirements
3. **Add authentication** for sensitive endpoints
4. **Use descriptive names** for services and routes
5. **Comment your configurations** for future reference
6. **Test locally** before deploying to production

## 🔍 **Troubleshooting**

- **Kong not picking up changes?** Check the ConfigMap is updated
- **Route not working?** Verify the Kubernetes service is running
- **Rate limiting too strict?** Adjust the minute/hour limits
- **CORS issues?** Check the origins configuration

## 📚 **Examples**

### **User Service with Authentication**
```yaml
name: user-service
url: http://user-service.farmers-market.svc.cluster.local:80
routes:
  - name: user-service-public-route
    paths: [/v1/users/login, /v1/users/register]
    methods: [POST]
    strip_path: false
    preserve_host: false
  - name: user-service-private-route
    paths: [/v1/users]
    methods: [GET, PUT, DELETE]
    strip_path: false
    preserve_host: false
plugins:
  - name: cors
    config:
      origins: ["*"]
      credentials: true
  - name: jwt
    config:
      secret_is_base64: false
      algorithm: HS256
    route: user-service-private-route  # Only apply to private routes
```

### **High-Traffic Service**
```yaml
name: product-service
url: http://product-service.farmers-market.svc.cluster.local:80
routes:
  - name: product-service-route
    paths: [/v1/products]
    methods: [GET, POST, PUT, DELETE]
    strip_path: false
    preserve_host: false
plugins:
  - name: rate-limiting
    config:
      minute: 1000   # Higher limits for product browsing
      hour: 10000
      policy: local
```
