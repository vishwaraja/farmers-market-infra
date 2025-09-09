# 🚀 Initial Setup Guide

This guide walks you through the complete initial setup of your Farmers Market infrastructure. This is a **one-time setup** that you'll only need to do once.

## 🎯 Overview

This setup will create:
- **AWS Infrastructure**: EKS cluster, VPC, security groups, etc.
- **Terraform State Management**: S3 buckets and DynamoDB tables
- **CI/CD Pipeline**: GitHub Actions workflows
- **Cost Monitoring**: Infracost integration

## 📋 Prerequisites

### Required Tools
- **AWS CLI** >= 2.0
- **Terraform** >= 1.6.0
- **kubectl** >= 1.28
- **Git** >= 2.0
- **GitHub Account** with repository access

### AWS Requirements
- **AWS Account** with appropriate permissions
- **AWS CLI configured** with access keys
- **Billing enabled** (required for some services)

### Installation Commands

#### macOS (Homebrew)
```bash
# Install AWS CLI
brew install awscli

# Install Terraform
brew install terraform

# Install kubectl
brew install kubectl

# Install Git (if not already installed)
brew install git
```

#### Ubuntu/Debian
```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

#### Windows (Chocolatey)
```bash
# Install AWS CLI
choco install awscli

# Install Terraform
choco install terraform

# Install kubectl
choco install kubernetes-cli

# Install Git
choco install git
```

## 🔧 AWS Setup

### 1. Configure AWS CLI
```bash
# Configure AWS credentials
aws configure

# Enter your credentials:
# AWS Access Key ID: [Your Access Key]
# AWS Secret Access Key: [Your Secret Key]
# Default region name: us-east-1
# Default output format: json

# Verify configuration
aws sts get-caller-identity
```

### 2. Create IAM User (Recommended)
```bash
# Create IAM user for Terraform
aws iam create-user --user-name terraform-user

# Attach necessary policies
aws iam attach-user-policy --user-name terraform-user --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
aws iam attach-user-policy --user-name terraform-user --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
aws iam attach-user-policy --user-name terraform-user --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
aws iam attach-user-policy --user-name terraform-user --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
aws iam attach-user-policy --user-name terraform-user --policy-arn arn:aws:iam::aws:policy/AmazonVPCFullAccess
aws iam attach-user-policy --user-name terraform-user --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
aws iam attach-user-policy --user-name terraform-user --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess
aws iam attach-user-policy --user-name terraform-user --policy-arn arn:aws:iam::aws:policy/IAMFullAccess

# Create access keys
aws iam create-access-key --user-name terraform-user
```

## 🏗️ Infrastructure Setup

### 1. Clone Repository
```bash
# Clone the repository
git clone https://github.com/vishwaraja/farmers-market-infra.git
cd farmers-market-infra

# Verify you're in the correct directory
ls -la
```

### 2. Bootstrap State Management
```bash
# Make the bootstrap script executable
chmod +x scripts/bootstrap-state.sh

# Bootstrap state management for dev environment
./scripts/bootstrap-state.sh dev

# Bootstrap state management for production environment
./scripts/bootstrap-state.sh prod
```

This script creates:
- **S3 buckets** for Terraform state storage
- **DynamoDB tables** for state locking
- **KMS keys** for state encryption
- **IAM policies** for state access

### 3. Configure Environment Variables
```bash
# Copy example variables file
cp environments/dev/terraform.tfvars.example environments/dev/terraform.tfvars

# Edit the variables file
nano environments/dev/terraform.tfvars
```

#### Key Variables to Configure:
```hcl
# AWS Configuration
aws_region = "us-east-1"
environment = "dev"

# EKS Configuration
kubernetes_version = "1.28"
cluster_endpoint_public_access = true

# Node Group Configuration
instance_types = ["t3.small"]
capacity_type = "SPOT"  # Use spot instances for cost savings
min_size = 1
max_size = 3
desired_size = 1

# Feature Flags
enable_monitoring = false  # Disabled for cost savings in dev
enable_alb_logs = false   # Disabled for cost savings in dev

# Tags
tags = {
  Environment = "dev"
  Project     = "farmers-market"
  CostCenter  = "engineering"
}
```

### 4. Deploy Development Environment
```bash
# Navigate to dev environment
cd environments/dev

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the infrastructure
terraform apply

# Confirm with 'yes' when prompted
```

### 5. Deploy Production Environment
```bash
# Navigate to production environment
cd ../production

# Copy example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit the variables file
nano terraform.tfvars
```

#### Production Variables:
```hcl
# AWS Configuration
aws_region = "us-east-1"
environment = "production"

# EKS Configuration
kubernetes_version = "1.28"
cluster_endpoint_public_access = true

# Node Group Configuration
instance_types = ["t3.medium"]  # Larger instances for production
capacity_type = "ON_DEMAND"     # On-demand for stability
min_size = 2
max_size = 5
desired_size = 2

# Feature Flags
enable_monitoring = true   # Enabled for production
enable_alb_logs = true    # Enabled for production

# Tags
tags = {
  Environment = "production"
  Project     = "farmers-market"
  CostCenter  = "production"
}
```

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the infrastructure
terraform apply

# Confirm with 'yes' when prompted
```

## 🔗 Connect to EKS Clusters

### 1. Update kubeconfig for Dev
```bash
# Get dev cluster name
cd environments/dev
terraform output eks_cluster_name

# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name [cluster-name]

# Verify connection
kubectl get nodes
```

### 2. Update kubeconfig for Production
```bash
# Get production cluster name
cd environments/production
terraform output eks_cluster_name

# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name [cluster-name]

# Verify connection
kubectl get nodes
```

## 🚀 Deploy Microservices

### 1. Deploy Kong API Gateway
```bash
# Deploy Kong to dev cluster
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/kong-deployment.yaml

# Verify deployment
kubectl get pods -n kong
kubectl get services -n kong
```

### 2. Deploy Sample Services
```bash
# Deploy user service
kubectl apply -f k8s/user-service.yaml

# Deploy product service
kubectl apply -f k8s/product-service.yaml

# Deploy order service
kubectl apply -f k8s/order-service.yaml

# Verify all services
kubectl get pods
kubectl get services
```

## 🔧 GitHub Actions Setup

### 1. Add Repository Secrets
Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions**

#### Required Secrets:
```
AWS_ACCESS_KEY_ID: [Your AWS Access Key]
AWS_SECRET_ACCESS_KEY: [Your AWS Secret Key]
AWS_ROLE_ARN: [Your AWS Role ARN - optional]
SLACK_WEBHOOK_URL: [Your Slack webhook - optional]
INFRACOST_API_KEY: [Your Infracost API key - optional]
```

### 2. Add Repository Variables
Go to **Settings** → **Secrets and variables** → **Actions** → **Variables** tab

#### Required Variables:
```
TF_VERSION: 1.6.0
AWS_REGION: us-east-1
ENVIRONMENT: dev
```

### 3. Test CI/CD Pipeline
```bash
# Create a test branch
git checkout -b test-ci-cd

# Make a small change
echo "# Test" >> README.md

# Commit and push
git add .
git commit -m "Test CI/CD pipeline"
git push origin test-ci-cd

# Create PR to dev branch
# Check GitHub Actions tab for workflow execution
```

## 💰 Cost Monitoring Setup

### 1. Infracost Setup (Optional)
```bash
# Sign up at https://infracost.io/cloud
# Get your API key
# Add to GitHub secrets as INFRACOST_API_KEY
```

### 2. AWS Cost Explorer
```bash
# Enable Cost Explorer in AWS Console
# Go to: AWS Console → Cost Management → Cost Explorer
# Set up monthly budget alerts
```

### 3. AWS Budgets
```bash
# Create budget in AWS Console
# Go to: AWS Console → Cost Management → Budgets
# Set monthly budget limit (e.g., $100)
# Configure alerts at 80% and 100% of budget
```

## ✅ Verification

### 1. Infrastructure Verification
```bash
# Check EKS clusters
aws eks list-clusters

# Check S3 buckets
aws s3 ls

# Check DynamoDB tables
aws dynamodb list-tables

# Check VPCs
aws ec2 describe-vpcs
```

### 2. Application Verification
```bash
# Check Kong API Gateway
kubectl get services -n kong

# Test API endpoints
curl http://[kong-external-ip]/status

# Check microservices
kubectl get pods
kubectl get services
```

### 3. CI/CD Verification
```bash
# Check GitHub Actions
# Go to: GitHub → Actions tab
# Verify workflows are running
# Check for any failed runs
```

## 🎯 Next Steps

After completing this setup:

1. **Deploy your applications** to the EKS clusters
2. **Configure monitoring** and alerting
3. **Set up backup strategies** for production
4. **Review security** configurations
5. **Monitor costs** and optimize as needed

## 🔧 Troubleshooting

### Common Issues

#### Terraform State Issues
```bash
# If state is locked
terraform force-unlock [lock-id]

# If state is corrupted
terraform refresh
```

#### EKS Connection Issues
```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name [cluster-name]

# Check cluster status
aws eks describe-cluster --name [cluster-name]
```

#### Node Group Issues
```bash
# Check node group status
aws eks describe-nodegroup --cluster-name [cluster-name] --nodegroup-name [nodegroup-name]

# Check instance types
aws ec2 describe-instance-types --instance-types t3.small
```

### Getting Help
- Check [Troubleshooting Guide](TROUBLESHOOTING.md)
- Review [Architecture Documentation](ARCHITECTURE.md)
- Open an issue for support

## 📝 Summary

This setup creates a complete, production-ready infrastructure with:

- ✅ **EKS clusters** for both dev and production
- ✅ **VPC and networking** with proper security
- ✅ **Terraform state management** with S3 and DynamoDB
- ✅ **CI/CD pipeline** with GitHub Actions
- ✅ **Cost monitoring** with Infracost
- ✅ **Security** with IAM roles and policies

**Total setup time: ~2-3 hours**
**Monthly cost: ~$53 for dev, ~$80 for production**

Your infrastructure is now ready for development and production use! 🚀
