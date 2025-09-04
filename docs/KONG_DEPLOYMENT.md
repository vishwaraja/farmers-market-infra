# 🦍 Kong API Gateway Deployment Guide

This guide explains how to deploy and use Kong API Gateway in your Farmers Market infrastructure.

## 📋 Table of Contents

- [Architecture Overview](#architecture-overview)
- [Kong Components](#kong-components)
- [Deployment Process](#deployment-process)
- [Configuration](#configuration)
- [Testing Kong](#testing-kong)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Internet                                 │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                Application Load Balancer                   │
│                    (AWS ALB)                               │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                  Kong Ingress Controller                   │
│                    (EKS Cluster)                           │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                    Kong Proxy                               │
│              (API Gateway + Rate Limiting)                 │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                Microservices                                │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐          │
│  │User Service │ │Product Svc  │ │Order Service│          │
│  └─────────────┘ └─────────────┘ └─────────────┘          │
└─────────────────────────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                PostgreSQL Database                          │
│              (Kong Configuration Storage)                  │
└─────────────────────────────────────────────────────────────┘
```

## 🦍 Kong Components

### **1. Kong Proxy**
- **Purpose**: Main API gateway that handles incoming requests
- **Features**: Rate limiting, CORS, request transformation, authentication
- **Port**: 8000 (proxy), 8001 (admin)

### **2. Kong Ingress Controller**
- **Purpose**: Kubernetes integration, manages Kong configuration
- **Features**: Automatic service discovery, route management

### **3. Kong Database (PostgreSQL)**
- **Purpose**: Stores Kong configuration, services, routes, plugins
- **Features**: Persistent configuration, high availability

### **4. Kong Admin API**
- **Purpose**: Management interface for Kong configuration
- **Features**: REST API for managing services, routes, plugins

## 🚀 Deployment Process

### **Step 1: Deploy Infrastructure with Kong**

```bash
# 1. Bootstrap infrastructure
./scripts/bootstrap.sh dev

# 2. Deploy infrastructure (includes Kong)
./scripts/deploy.sh dev init
./scripts/deploy.sh dev apply

# 3. Verify Kong deployment
kubectl get pods -n kong
kubectl get services -n kong
```

### **Step 2: Deploy Microservices**

```bash
# 1. Create namespace
kubectl apply -f k8s/namespace.yaml

# 2. Deploy microservices
kubectl apply -f k8s/user-service.yaml
kubectl apply -f k8s/product-service.yaml
kubectl apply -f k8s/order-service.yaml

# 3. Verify services
kubectl get pods -n farmers-market
kubectl get services -n farmers-market
```

### **Step 3: Configure Kong Services**

```bash
# Get Kong admin URL
cd environments/dev
terraform output kong_connection_commands

# Port forward to Kong admin
kubectl port-forward -n kong svc/kong-admin 8001:8001

# Test Kong admin API
curl http://localhost:8001/status
```

## ⚙️ Configuration

### **Kong Services Configuration**

The Kong services are configured in `terraform.tfvars`:

```hcl
kong_services = [
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
```

### **Kong Plugins**

Kong comes with these plugins enabled by default:

1. **CORS**: Cross-origin resource sharing
2. **Rate Limiting**: Request rate limiting per service
3. **Request Transformer**: Add headers, modify requests
4. **Prometheus**: Metrics collection

### **Adding New Services**

To add a new service to Kong:

1. **Deploy the service** in Kubernetes
2. **Update terraform.tfvars** with new service configuration
3. **Apply Terraform** to update Kong configuration

```hcl
# Add to kong_services list
{
  name                = "new-service"
  url                 = "http://new-service.farmers-market.svc.cluster.local:80"
  path                = "/api/new"
  strip_path          = true
  preserve_host       = false
  rate_limit_minute   = 100
  rate_limit_hour     = 1000
}
```

## 🧪 Testing Kong

### **Test Kong Admin API**

```bash
# Port forward to Kong admin
kubectl port-forward -n kong svc/kong-admin 8001:8001

# Check Kong status
curl http://localhost:8001/status

# List services
curl http://localhost:8001/services

# List routes
curl http://localhost:8001/routes
```

### **Test Kong Proxy**

```bash
# Get ALB DNS name
cd environments/dev
terraform output api_gateway_dns_name

# Test user service through Kong
curl https://<alb-dns-name>/api/users

# Test product service through Kong
curl https://<alb-dns-name>/api/products

# Test order service through Kong
curl https://<alb-dns-name>/api/orders
```

### **Test Rate Limiting**

```bash
# Test rate limiting (should work for first 100 requests per minute)
for i in {1..105}; do
  curl -w "%{http_code}\n" -o /dev/null -s https://<alb-dns-name>/api/users
done
```

## 📊 Monitoring

### **Kong Metrics**

Kong exposes Prometheus metrics at `/metrics`:

```bash
# Port forward to Kong proxy
kubectl port-forward -n kong svc/kong-proxy 8000:8000

# Get metrics
curl http://localhost:8000/metrics
```

### **Kong Logs**

```bash
# View Kong proxy logs
kubectl logs -n kong -l app=kong-proxy -f

# View Kong ingress controller logs
kubectl logs -n kong -l app=kong-ingress-controller -f

# View Kong database logs
kubectl logs -n kong -l app=kong-database -f
```

### **Health Checks**

```bash
# Check Kong proxy health
kubectl get pods -n kong -l app=kong-proxy

# Check Kong database health
kubectl get pods -n kong -l app=kong-database

# Check microservices health
kubectl get pods -n farmers-market
```

## 🔧 Troubleshooting

### **Common Issues**

#### **1. Kong Proxy Not Starting**

```bash
# Check Kong proxy logs
kubectl logs -n kong -l app=kong-proxy

# Check Kong database connectivity
kubectl exec -n kong -it deployment/kong-proxy -- kong health
```

#### **2. Services Not Accessible Through Kong**

```bash
# Check if services are registered in Kong
kubectl port-forward -n kong svc/kong-admin 8001:8001
curl http://localhost:8001/services

# Check Kong routes
curl http://localhost:8001/routes
```

#### **3. Rate Limiting Not Working**

```bash
# Check Kong plugins
curl http://localhost:8001/plugins

# Check specific service plugins
curl http://localhost:8001/services/<service-id>/plugins
```

### **Debug Commands**

```bash
# Get Kong configuration
kubectl port-forward -n kong svc/kong-admin 8001:8001
curl http://localhost:8001/ | jq

# Check Kong database
kubectl exec -n kong -it deployment/kong-database -- psql -U kong -d kong -c "\dt"

# Check Kong ingress controller
kubectl logs -n kong -l app=kong-ingress-controller --tail=100
```

## 🎯 Kong Features

### **Available Plugins**

1. **Authentication**: JWT, OAuth2, API Key
2. **Security**: CORS, IP Restriction, Bot Detection
3. **Traffic Control**: Rate Limiting, Request Size Limiting
4. **Analytics**: Prometheus, Datadog, New Relic
5. **Transformation**: Request/Response Transformer
6. **Logging**: File, HTTP, TCP, UDP, Syslog

### **Adding Plugins**

```bash
# Add JWT plugin to a service
curl -X POST http://localhost:8001/services/<service-id>/plugins \
  --data "name=jwt"

# Add IP restriction plugin
curl -X POST http://localhost:8001/services/<service-id>/plugins \
  --data "name=ip-restriction" \
  --data "config.whitelist=192.168.1.0/24"
```

## 🚀 Next Steps

1. **Add Authentication**: Implement JWT or API key authentication
2. **Add Monitoring**: Set up Prometheus and Grafana
3. **Add Logging**: Configure centralized logging
4. **Add CI/CD**: Automate Kong configuration updates
5. **Add Security**: Implement additional security plugins

---

**Kong is now ready to handle your API traffic!** 🦍
