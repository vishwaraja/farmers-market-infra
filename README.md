# 🌾 Farmers Market Infrastructure

A well-structured, production-ready AWS infrastructure for The Farmers Market project using Terraform. This infrastructure is optimized for minimal microservices deployment (2-3 services) with proper environment isolation and cost optimization.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Environments](#environments)
- [Deployment](#deployment)
- [Cost Optimization](#cost-optimization)
- [Security](#security)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## 🎯 Overview

This infrastructure provides:

- **EKS Cluster**: Managed Kubernetes cluster for microservices
- **VPC**: Isolated network environment with public/private subnets
- **Security Groups**: Proper network security with least privilege
- **State Management**: Isolated Terraform state per environment
- **Cost Optimization**: Spot instances for dev, right-sized resources
- **Environment Isolation**: Separate dev and production environments

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    AWS Account                              │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────────────────────┐ │
│  │   Dev Environment │    │    Production Environment      │ │
│  │                 │    │                                 │ │
│  │ ┌─────────────┐ │    │ ┌─────────────────────────────┐ │ │
│  │ │     VPC     │ │    │ │           VPC               │ │ │
│  │ │ 10.0.0.0/16 │ │    │ │      10.1.0.0/16           │ │ │
│  │ │             │ │    │ │                             │ │ │
│  │ │ ┌─────────┐ │ │    │ │ ┌─────────────────────────┐ │ │ │
│  │ │ │  EKS    │ │ │    │ │ │         EKS             │ │ │ │
│  │ │ │ Cluster │ │ │    │ │ │       Cluster           │ │ │ │
│  │ │ │ 1 Node  │ │ │    │ │ │      3 Nodes            │ │ │ │
│  │ │ │ t3.small│ │ │    │ │ │     t3.medium           │ │ │ │
│  │ │ │  SPOT   │ │ │    │ │ │    ON_DEMAND            │ │ │ │
│  │ │ └─────────┘ │ │    │ │ └─────────────────────────┘ │ │ │
│  │ └─────────────┘ │    │ └─────────────────────────────┘ │ │
│  └─────────────────┘    └─────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
farmers-market-infra/
├── modules/                          # Reusable Terraform modules
│   ├── networking/                   # VPC, subnets, security groups
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── versions.tf
│   └── compute/                      # EKS cluster and node groups
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── versions.tf
├── environments/                     # Environment-specific configurations
│   ├── dev/                         # Development environment
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars.example
│   │   ├── backend.tf
│   │   ├── providers.tf
│   │   └── outputs.tf
│   └── production/                  # Production environment
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars.example
│       ├── backend.tf
│       ├── providers.tf
│       └── outputs.tf
├── shared/                          # Shared configurations
│   ├── locals.tf                    # Common local values
│   ├── tags.tf                      # Standardized tagging
│   └── versions.tf                  # Provider version constraints
├── scripts/                         # Deployment and utility scripts
│   ├── deploy.sh                    # Deployment script
│   ├── bootstrap.sh                 # Bootstrap state management
│   └── validate.sh                  # Validation script
├── docs/                           # Documentation
│   ├── DEPLOYMENT.md                # Detailed deployment guide
│   └── ARCHITECTURE.md              # Architecture documentation
└── .gitignore
```

## 🔧 Prerequisites

Before deploying the infrastructure, ensure you have:

### Required Tools
- **Terraform** >= 1.5.0
- **AWS CLI** >= 2.0
- **kubectl** >= 1.28
- **Git**

### AWS Requirements
- AWS Account with appropriate permissions
- AWS CLI configured with credentials
- IAM permissions for EKS, VPC, S3, DynamoDB, KMS

### Installation Commands

```bash
# Install Terraform (macOS)
brew install terraform

# Install AWS CLI (macOS)
brew install awscli

# Install kubectl (macOS)
brew install kubectl

# Configure AWS CLI
aws configure
```

## 🚀 Quick Start

### 1. Clone and Setup

```bash
git clone <repository-url>
cd farmers-market-infra
```

### 2. Bootstrap State Management

```bash
# Bootstrap dev environment
./scripts/bootstrap.sh dev

# Bootstrap production environment
./scripts/bootstrap.sh production
```

### 3. Deploy Infrastructure

```bash
# Deploy dev environment
./scripts/deploy.sh dev init
./scripts/deploy.sh dev plan
./scripts/deploy.sh dev apply

# Deploy production environment
./scripts/deploy.sh production init
./scripts/deploy.sh production plan
./scripts/deploy.sh production apply
```

### 4. Connect to EKS Cluster

```bash
# Configure kubectl for dev
aws eks update-kubeconfig --region us-east-1 --name farmers-market-dev

# Verify cluster
kubectl get nodes
kubectl get pods -A
```

## 🌍 Environments

### Development Environment
- **Purpose**: Development and testing
- **Resources**: Minimal (1 node, t3.small, SPOT)
- **Cost**: ~$30-50/month
- **Features**: Public endpoint, spot instances, minimal monitoring

### Production Environment
- **Purpose**: Production workloads
- **Resources**: Production-ready (3 nodes, t3.medium, ON_DEMAND)
- **Cost**: ~$200-300/month
- **Features**: Private endpoint, on-demand instances, full monitoring

## 🚀 Deployment

### Manual Deployment

```bash
# Navigate to environment directory
cd environments/dev

# Initialize Terraform
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply

# Destroy (when needed)
terraform destroy
```

### Automated Deployment

```bash
# Using deployment script
./scripts/deploy.sh dev apply

# With auto-approval
./scripts/deploy.sh dev apply --yes

# Plan only
./scripts/deploy.sh dev apply --plan
```

## 💰 Cost Optimization

### Development Environment
- **Spot Instances**: 60-70% cost savings
- **Single NAT Gateway**: Shared across AZs
- **Minimal Node Count**: 1 node with auto-scaling
- **Small Instance Types**: t3.small

### Production Environment
- **On-Demand Instances**: Stable pricing and availability
- **Multiple NAT Gateways**: High availability
- **Right-sized Resources**: t3.medium for microservices
- **Auto-scaling**: Scale based on demand

### Cost Monitoring
- Enable AWS Cost Explorer
- Set up billing alerts
- Use AWS Budgets for cost control

## 🔒 Security

### Network Security
- **Private Subnets**: Worker nodes in private subnets
- **Security Groups**: Restrictive rules with least privilege
- **NACLs**: Additional network-level security
- **VPC Flow Logs**: Network traffic monitoring

### Access Control
- **IAM Roles**: Service-specific roles with minimal permissions
- **EKS RBAC**: Kubernetes role-based access control
- **Private Endpoints**: Production cluster endpoint is private

### Data Protection
- **Encryption at Rest**: EBS volumes encrypted
- **Encryption in Transit**: TLS for all communications
- **State Encryption**: Terraform state encrypted in S3

## 📊 Monitoring

### CloudWatch Integration
- **Container Insights**: EKS cluster monitoring
- **Log Groups**: Application and system logs
- **Metrics**: CPU, memory, network utilization
- **Alarms**: Automated alerting

### Kubernetes Monitoring
- **Metrics Server**: Resource utilization
- **Horizontal Pod Autoscaler**: Automatic scaling
- **Cluster Autoscaler**: Node scaling

## 🔧 Troubleshooting

### Common Issues

#### Terraform State Issues
```bash
# Re-initialize backend
terraform init -reconfigure

# Import existing resources
terraform import aws_instance.example i-1234567890abcdef0
```

#### EKS Connection Issues
```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name farmers-market-dev

# Verify cluster status
aws eks describe-cluster --name farmers-market-dev --region us-east-1
```

#### Node Group Issues
```bash
# Check node group status
aws eks describe-nodegroup --cluster-name farmers-market-dev --nodegroup-name primary

# View node group logs
aws logs describe-log-groups --log-group-name-prefix /aws/eks/farmers-market-dev
```

### Getting Help
- Check AWS CloudTrail for API call logs
- Review Terraform state for resource status
- Use AWS Support for infrastructure issues

## 🤝 Contributing

### Development Workflow
1. Create feature branch
2. Make changes with proper testing
3. Update documentation
4. Submit pull request

### Code Standards
- Use consistent naming conventions
- Add comprehensive comments
- Validate with `terraform validate`
- Format with `terraform fmt`

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For support and questions:
- Create an issue in the repository
- Contact the platform team
- Check the troubleshooting section

---

**Happy Farming! 🌾**