# 🚀 Frontend & Backend Deployment Guide

This guide explains how to deploy both frontend and backend services in the Farmers Market infrastructure.

## 📋 Table of Contents

- [Architecture Overview](#architecture-overview)
- [Frontend Deployment](#frontend-deployment)
- [Backend Deployment](#backend-deployment)
- [Service Integration](#service-integration)
- [Cost Breakdown](#cost-breakdown)
- [Deployment Commands](#deployment-commands)

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    AWS Account (Dev)                       │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                 VPC (10.0.0.0/16)                      │ │
│  │                                                         │ │
│  │  ┌─────────────────┐    ┌─────────────────────────────┐ │ │
│  │  │  Public Subnets │    │     Private Subnets         │ │ │
│  │  │                 │    │                             │ │ │
│  │  │ ┌─────────────┐ │    │ ┌─────────────────────────┐ │ │ │
│  │  │ │   ALB/NLB   │ │    │ │      EKS Cluster        │ │ │ │
│  │  │ │             │ │    │ │                         │ │ │ │
│  │  │ │ API Gateway │ │    │ │ ┌─────────────────────┐ │ │ │ │
│  │  │ │ (Backend)   │ │    │ │ │   Backend Services  │ │ │ │ │
│  │  │ └─────────────┘ │    │ │ │                     │ │ │ │ │
│  │  └─────────────────┘    │ │ │ - User Service      │ │ │ │ │
│  │                         │ │ │ - Product Service   │ │ │ │ │
│  │  ┌─────────────────┐    │ │ │ - Order Service     │ │ │ │ │
│  │  │   CloudFront    │    │ │ └─────────────────────┘ │ │ │ │
│  │  │                 │    │ └─────────────────────────┘ │ │ │
│  │  │ Frontend (S3)   │    │                             │ │ │
│  │  │                 │    │                             │ │ │
│  │  │ - React/Next.js │    │                             │ │ │
│  │  │ - Static Files  │    │                             │ │ │
│  │  └─────────────────┘    │                             │ │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 🌐 Frontend Deployment

### **Architecture: S3 + CloudFront**

The frontend is deployed as a static website using:
- **S3 Bucket**: Hosts static files (HTML, CSS, JS, images)
- **CloudFront CDN**: Global content delivery with caching
- **SSL Certificate**: HTTPS encryption (automatic with CloudFront)

### **Deployment Process**

1. **Build your frontend application**:
   ```bash
   # For React
   npm run build
   
   # For Next.js
   npm run build && npm run export
   
   # For Vue.js
   npm run build
   ```

2. **Deploy to S3**:
   ```bash
   # Get the S3 bucket name from Terraform output
   cd environments/dev
   terraform output frontend_s3_bucket
   
   # Upload your built files
   aws s3 sync ./dist s3://<bucket-name> --delete
   
   # Or use the provided command
   terraform output frontend_deployment_instructions
   ```

3. **Invalidate CloudFront cache**:
   ```bash
   # Get CloudFront distribution ID
   terraform output frontend_deployment_instructions
   
   # Invalidate cache
   aws cloudfront create-invalidation --distribution-id <distribution-id> --paths '/*'
   ```

### **Frontend Configuration**

Update your frontend to point to the backend API:

```javascript
// In your frontend configuration
const API_BASE_URL = 'https://<alb-dns-name>';  // Get from terraform output

// Example API calls
fetch(`${API_BASE_URL}/api/users`)
  .then(response => response.json())
  .then(data => console.log(data));
```

## 🔧 Backend Deployment

### **Architecture: EKS + ALB**

The backend is deployed as microservices using:
- **EKS Cluster**: Kubernetes cluster for container orchestration
- **Application Load Balancer**: API Gateway with SSL termination
- **Target Groups**: Routes traffic to backend services

### **Backend Services Structure**

```
Backend Services:
├── API Gateway (ALB)
├── User Service (Authentication, User Management)
├── Product Service (Product Catalog, Inventory)
└── Order Service (Order Processing, Payments)
```

### **Deployment Process**

1. **Connect to EKS cluster**:
   ```bash
   # Configure kubectl
   aws eks update-kubeconfig --region us-east-1 --name farmers-market-dev
   
   # Verify connection
   kubectl get nodes
   ```

2. **Deploy backend services**:
   ```bash
   # Create namespace
   kubectl create namespace farmers-market
   
   # Deploy your microservices
   kubectl apply -f k8s/user-service.yaml
   kubectl apply -f k8s/product-service.yaml
   kubectl apply -f k8s/order-service.yaml
   ```

3. **Configure service routing**:
   ```yaml
   # Example: user-service.yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: user-service
     namespace: farmers-market
   spec:
     replicas: 2
     selector:
       matchLabels:
         app: user-service
     template:
       metadata:
         labels:
           app: user-service
       spec:
         containers:
         - name: user-service
           image: your-registry/user-service:latest
           ports:
           - containerPort: 3000
           env:
           - name: DATABASE_URL
             value: "postgresql://..."
   ---
   apiVersion: v1
   kind: Service
   metadata:
     name: user-service
     namespace: farmers-market
   spec:
     selector:
       app: user-service
     ports:
     - port: 80
       targetPort: 3000
     type: ClusterIP
   ```

4. **Configure ALB Target Group**:
   ```bash
   # Get target group ARN
   terraform output target_group_arn
   
   # Register your services with the target group
   # This is typically done via Kubernetes ingress or service annotations
   ```

## 🔗 Service Integration

### **Frontend → Backend Communication**

```javascript
// Frontend API configuration
const config = {
  apiBaseUrl: 'https://<alb-dns-name>',
  endpoints: {
    users: '/api/users',
    products: '/api/products',
    orders: '/api/orders'
  }
};

// Example API service
class ApiService {
  async getUsers() {
    const response = await fetch(`${config.apiBaseUrl}${config.endpoints.users}`);
    return response.json();
  }
  
  async createOrder(orderData) {
    const response = await fetch(`${config.apiBaseUrl}${config.endpoints.orders}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(orderData)
    });
    return response.json();
  }
}
```

### **Backend Service Communication**

```yaml
# Example: Internal service communication
apiVersion: v1
kind: Service
metadata:
  name: user-service
  namespace: farmers-market
spec:
  selector:
    app: user-service
  ports:
  - port: 80
    targetPort: 3000
  type: ClusterIP
```

```javascript
// Backend service communication
const userServiceUrl = 'http://user-service.farmers-market.svc.cluster.local';

async function getUserById(userId) {
  const response = await fetch(`${userServiceUrl}/users/${userId}`);
  return response.json();
}
```

## 💰 Cost Breakdown

### **Monthly Costs (Dev Environment)**

| Component | Cost | Description |
|-----------|------|-------------|
| EKS Cluster | $0 | Free tier |
| EKS Worker Nodes (1x t3.small) | ~$15 | Spot instance |
| ALB | ~$16 | Application Load Balancer |
| CloudFront | ~$1 | CDN (minimal usage) |
| S3 | ~$1 | Static file storage |
| Data Transfer | ~$2 | Minimal traffic |
| **Total** | **~$35/month** | **Complete setup** |

### **Cost Optimization Tips**

1. **Use Spot Instances**: 60-70% cost savings
2. **Disable ALB Logs**: Save ~$5/month
3. **Use CloudFront Price Class 100**: Cheaper for US/Europe
4. **Monitor Usage**: Set up billing alerts

## 🚀 Deployment Commands

### **Complete Deployment**

```bash
# 1. Bootstrap infrastructure
./scripts/bootstrap.sh dev

# 2. Deploy infrastructure
./scripts/deploy.sh dev init
./scripts/deploy.sh dev apply

# 3. Get deployment information
cd environments/dev
terraform output application_urls

# 4. Deploy frontend
# Build your frontend and upload to S3
terraform output frontend_deployment_instructions

# 5. Deploy backend services
# Connect to EKS and deploy your microservices
aws eks update-kubeconfig --region us-east-1 --name farmers-market-dev
kubectl create namespace farmers-market
kubectl apply -f k8s/
```

### **Frontend Deployment Commands**

```bash
# Build and deploy frontend
npm run build
aws s3 sync ./dist s3://$(terraform output -raw frontend_s3_bucket) --delete
aws cloudfront create-invalidation --distribution-id $(terraform output -raw frontend_deployment_instructions | jq -r '.cloudfront_invalidation' | cut -d' ' -f6) --paths '/*'
```

### **Backend Deployment Commands**

```bash
# Deploy backend services
kubectl apply -f k8s/user-service.yaml
kubectl apply -f k8s/product-service.yaml
kubectl apply -f k8s/order-service.yaml

# Check deployment status
kubectl get pods -n farmers-market
kubectl get services -n farmers-market
```

## 🔍 Monitoring and Debugging

### **Frontend Monitoring**

```bash
# Check CloudFront distribution
aws cloudfront get-distribution --id <distribution-id>

# Check S3 bucket
aws s3 ls s3://<bucket-name>
```

### **Backend Monitoring**

```bash
# Check EKS cluster
kubectl get nodes
kubectl get pods -A

# Check ALB
aws elbv2 describe-load-balancers --names dev-farmers-market-api-gateway

# Check target group health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
```

## 🎯 Next Steps

1. **Deploy your first service**: Start with a simple API endpoint
2. **Set up CI/CD**: Automate frontend and backend deployments
3. **Add monitoring**: Set up CloudWatch dashboards
4. **Scale up**: Add more services as needed
5. **Add staging**: When ready, add staging environment

---

**Ready to deploy?** Start with the [Quick Start Guide](../README.md#quick-start)!
