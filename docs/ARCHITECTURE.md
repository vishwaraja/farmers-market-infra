# 🏗️ Architecture Guide - Farmers Market Infrastructure

## 📋 Table of Contents

- [Current Architecture](#current-architecture)
- [Service Segregation](#service-segregation)
- [Frontend Deployment](#frontend-deployment)
- [Backend Deployment](#backend-deployment)
- [Cost Optimization Strategy](#cost-optimization-strategy)
- [Future Scaling](#future-scaling)

## 🎯 Current Architecture (Dev Environment)

```
┌─────────────────────────────────────────────────────────────┐
│                    AWS Account (Dev)                       │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                 VPC (10.0.0.0/16)                      │ │
│  │                                                         │ │
│  │  ┌─────────────────┐    ┌─────────────────────────────┐ │ │
│  │  │  Public Subnets │    │     Private Subnets         │ │ │
│  │  │  (Load Balancers)│    │   (EKS Worker Nodes)       │ │ │
│  │  │                 │    │                             │ │ │
│  │  │ ┌─────────────┐ │    │ ┌─────────────────────────┐ │ │ │
│  │  │ │   ALB/NLB   │ │    │ │      EKS Cluster        │ │ │ │
│  │  │ │             │ │    │ │                         │ │ │ │
│  │  │ │ Frontend    │ │    │ │ ┌─────────────────────┐ │ │ │ │
│  │  │ │ (React/Next)│ │    │ │ │   Backend Services  │ │ │ │ │
│  │  │ │             │ │    │ │ │                     │ │ │ │ │
│  │  │ │ - Static    │ │    │ │ │ - API Gateway       │ │ │ │ │
│  │  │ │ - CDN       │ │    │ │ │ - User Service      │ │ │ │ │
│  │  │ │ - S3        │ │    │ │ │ - Product Service   │ │ │ │ │
│  │  │ └─────────────┘ │    │ │ │ - Order Service     │ │ │ │ │
│  │  └─────────────────┘    │ │ └─────────────────────┘ │ │ │ │
│  │                         │ └─────────────────────────┘ │ │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 🔄 Service Segregation Strategy

### **Frontend Services**
- **Deployment**: Static hosting (S3 + CloudFront) or containerized
- **Location**: Public subnets or EKS cluster
- **Resources**: Minimal (CDN, S3, or small containers)

### **Backend Services**
- **Deployment**: EKS cluster (containers)
- **Location**: Private subnets
- **Resources**: Auto-scaling based on demand

### **Shared Services**
- **Database**: RDS (if needed) or managed services
- **Cache**: ElastiCache (if needed)
- **Monitoring**: CloudWatch + Container Insights

## 🚀 Frontend Deployment Options

### **Option 1: Static Hosting (Recommended for React/Next.js)**
```
Frontend → S3 Bucket → CloudFront CDN → ALB (if needed)
```
- **Cost**: ~$5-10/month
- **Performance**: Excellent (CDN)
- **Maintenance**: Minimal

### **Option 2: Containerized Frontend**
```
Frontend → EKS Cluster → ALB → Public
```
- **Cost**: ~$20-30/month (additional pods)
- **Performance**: Good
- **Maintenance**: Medium

## 🔧 Backend Deployment Strategy

### **Microservices in EKS**
```
API Gateway → Backend Services → Database
     ↓              ↓              ↓
   ALB/NLB    EKS Pods (2-3)    RDS/Managed
```

### **Service Architecture**
- **API Gateway**: Single entry point
- **User Service**: Authentication, user management
- **Product Service**: Product catalog, inventory
- **Order Service**: Order processing, payments

## 💰 Cost Optimization Strategy

### **Current Setup (Dev Only)**
- **EKS Cluster**: 1 node, t3.small, SPOT
- **Frontend**: S3 + CloudFront
- **Backend**: 2-3 microservices in EKS
- **Total Cost**: ~$40-60/month

### **Future Scaling**
- **Staging**: Add when needed (~$50/month)
- **Production**: Separate account or same account (~$200/month)

## 🔮 Future Scaling Path

### **Phase 1: Development (Current)**
- Single dev environment
- Minimal resources
- Cost: ~$40-60/month

### **Phase 2: Staging (When Ready)**
- Add staging environment
- Medium resources
- Cost: ~$90-110/month total

### **Phase 3: Production (When Ready)**
- Production environment
- Full resources
- Cost: ~$290-410/month total

## 🛠️ Implementation Plan

1. **Deploy dev environment** with frontend + backend
2. **Monitor costs** and performance
3. **Add staging** when development stabilizes
4. **Add production** when ready for launch
5. **Consider separate accounts** for production
