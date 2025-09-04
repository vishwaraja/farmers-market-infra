# 🚀 Deployment Guide - Farmers Market Infrastructure

This guide provides detailed instructions for deploying the Farmers Market infrastructure across different environments.

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Bootstrap Process](#bootstrap-process)
- [Environment Configuration](#environment-configuration)
- [Deployment Steps](#deployment-steps)
- [Post-Deployment](#post-deployment)
- [Environment-Specific Notes](#environment-specific-notes)
- [Troubleshooting](#troubleshooting)

## 🔧 Prerequisites

### Required Tools and Versions

| Tool | Version | Purpose |
|------|---------|---------|
| Terraform | >= 1.5.0 | Infrastructure provisioning |
| AWS CLI | >= 2.0 | AWS API interactions |
| kubectl | >= 1.28 | Kubernetes cluster management |
| Git | Latest | Version control |

### AWS Account Setup

1. **Create AWS Account** (if not exists)
2. **Configure IAM User** with required permissions:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "eks:*",
           "ec2:*",
           "iam:*",
           "s3:*",
           "dynamodb:*",
           "kms:*",
           "logs:*",
           "cloudwatch:*"
         ],
         "Resource": "*"
       }
     ]
   }
   ```
3. **Configure AWS CLI**:
   ```bash
   aws configure
   # Enter Access Key ID, Secret Access Key, Region (us-east-1), Output format (json)
   ```

### Local Environment Setup

```bash
# Clone repository
git clone <repository-url>
cd farmers-market-infra

# Verify tools
terraform version
aws --version
kubectl version --client
```

## 🏗️ Bootstrap Process

The bootstrap process creates the necessary AWS resources for Terraform state management.

### Automated Bootstrap

```bash
# Bootstrap dev environment
./scripts/bootstrap.sh dev

# Bootstrap production environment
./scripts/bootstrap.sh production --region us-east-1

# Force recreation (if needed)
./scripts/bootstrap.sh dev --force
```

### Manual Bootstrap

If you prefer manual setup or need custom configuration:

```bash
# Create S3 bucket for state
aws s3api create-bucket --bucket farmers-market-terraform-state-dev --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning --bucket farmers-market-terraform-state-dev --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption --bucket farmers-market-terraform-state-dev --server-side-encryption-configuration '{
  "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
}'

# Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name farmers-market-terraform-locks-dev \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5

# Create KMS key for encryption
aws kms create-key --description "Terraform state encryption key for dev"
aws kms create-alias --alias-name alias/terraform-state-key-dev --target-key-id <key-id>
```

## ⚙️ Environment Configuration

### Development Environment

1. **Copy example variables**:
   ```bash
   cd environments/dev
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Customize variables** in `terraform.tfvars`:
   ```hcl
   # Basic configuration
   environment = "dev"
   aws_region  = "us-east-1"
   project_name = "farmers-market"
   
   # Networking
   vpc_cidr = "10.0.0.0/16"
   availability_zone_count = 2
   
   # EKS Configuration
   cluster_name = "farmers-market-dev"
   instance_types = ["t3.small"]
   capacity_type = "SPOT"
   desired_size = 1
   ```

### Production Environment

1. **Copy example variables**:
   ```bash
   cd environments/production
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Customize variables** in `terraform.tfvars`:
   ```hcl
   # Basic configuration
   environment = "production"
   aws_region  = "us-east-1"
   project_name = "farmers-market"
   
   # Networking
   vpc_cidr = "10.1.0.0/16"
   availability_zone_count = 3
   single_nat_gateway = false
   
   # EKS Configuration
   cluster_name = "farmers-market-prod"
   instance_types = ["t3.medium"]
   capacity_type = "ON_DEMAND"
   desired_size = 3
   cluster_endpoint_public_access = false
   ```

## 🚀 Deployment Steps

### Step 1: Initialize Terraform

```bash
# Using deployment script
./scripts/deploy.sh dev init

# Or manually
cd environments/dev
terraform init
```

### Step 2: Plan Deployment

```bash
# Using deployment script
./scripts/deploy.sh dev plan

# Or manually
terraform plan
```

### Step 3: Apply Changes

```bash
# Using deployment script (interactive)
./scripts/deploy.sh dev apply

# Using deployment script (auto-approve)
./scripts/deploy.sh dev apply --yes

# Or manually
terraform apply
```

### Step 4: Verify Deployment

```bash
# Check cluster status
aws eks describe-cluster --name farmers-market-dev --region us-east-1

# Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name farmers-market-dev

# Verify nodes
kubectl get nodes

# Check system pods
kubectl get pods -A
```

## 🎯 Post-Deployment

### Configure kubectl

```bash
# Get cluster information
cd environments/dev
terraform output cluster_info

# Configure kubectl
aws eks update-kubeconfig --region $(terraform output -raw aws_region) --name $(terraform output -raw cluster_name)

# Verify connection
kubectl get nodes
```

### Deploy Sample Application

```bash
# Create namespace
kubectl create namespace farmers-market

# Deploy sample nginx
kubectl create deployment nginx --image=nginx --namespace=farmers-market

# Expose service
kubectl expose deployment nginx --port=80 --type=LoadBalancer --namespace=farmers-market

# Check status
kubectl get services --namespace=farmers-market
```

### Set Up Monitoring

```bash
# Enable Container Insights
aws eks update-cluster-config --name farmers-market-dev --logging '{
  "enable": [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
}'
```

## 🌍 Environment-Specific Notes

### Development Environment

**Characteristics:**
- Minimal resources for cost optimization
- Spot instances for 60-70% cost savings
- Public endpoint for easy access
- Single NAT Gateway
- 1-2 availability zones

**Cost:** ~$30-50/month

**Use Cases:**
- Development and testing
- Feature validation
- Integration testing

### Production Environment

**Characteristics:**
- Production-ready resources
- On-demand instances for stability
- Private endpoint for security
- Multiple NAT Gateways for HA
- 3 availability zones

**Cost:** ~$200-300/month

**Use Cases:**
- Production workloads
- Customer-facing services
- High availability requirements

## 🔧 Troubleshooting

### Common Issues and Solutions

#### 1. Terraform State Issues

**Problem:** State file conflicts or corruption

**Solution:**
```bash
# Re-initialize backend
terraform init -reconfigure

# Import existing resources
terraform import aws_instance.example i-1234567890abcdef0

# Refresh state
terraform refresh
```

#### 2. EKS Cluster Creation Fails

**Problem:** Cluster creation times out or fails

**Solution:**
```bash
# Check IAM permissions
aws sts get-caller-identity

# Verify subnet configuration
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-xxxxx"

# Check security groups
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=vpc-xxxxx"
```

#### 3. Node Group Issues

**Problem:** Nodes fail to join cluster

**Solution:**
```bash
# Check node group status
aws eks describe-nodegroup --cluster-name farmers-market-dev --nodegroup-name primary

# View CloudWatch logs
aws logs describe-log-groups --log-group-name-prefix /aws/eks/farmers-market-dev

# Check instance status
aws ec2 describe-instances --filters "Name=tag:kubernetes.io/cluster/farmers-market-dev,Values=owned"
```

#### 4. kubectl Connection Issues

**Problem:** Cannot connect to cluster

**Solution:**
```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name farmers-market-dev

# Verify cluster endpoint
aws eks describe-cluster --name farmers-market-dev --query 'cluster.endpoint'

# Check security groups
aws ec2 describe-security-groups --filters "Name=group-name,Values=*eks-cluster*"
```

### Debugging Commands

```bash
# Terraform debugging
export TF_LOG=DEBUG
terraform plan

# AWS CLI debugging
aws configure set cli_log_level debug

# kubectl debugging
kubectl get events --sort-by=.metadata.creationTimestamp
kubectl describe nodes
kubectl logs -n kube-system <pod-name>
```

### Getting Help

1. **Check AWS CloudTrail** for API call logs
2. **Review Terraform state** for resource status
3. **Use AWS Support** for infrastructure issues
4. **Check GitHub Issues** for known problems
5. **Contact Platform Team** for assistance

## 📊 Monitoring and Maintenance

### Regular Tasks

1. **Update Kubernetes version** (quarterly)
2. **Review and update instance types** (as needed)
3. **Monitor costs** (monthly)
4. **Update security patches** (monthly)
5. **Backup Terraform state** (before major changes)

### Cost Monitoring

```bash
# Set up billing alerts
aws budgets create-budget --account-id <account-id> --budget '{
  "BudgetName": "Farmers Market Dev",
  "BudgetLimit": {"Amount": "100", "Unit": "USD"},
  "TimeUnit": "MONTHLY",
  "BudgetType": "COST"
}'
```

### Security Updates

```bash
# Update EKS cluster
aws eks update-cluster-version --name farmers-market-dev --kubernetes-version 1.29

# Update node group
aws eks update-nodegroup-version --cluster-name farmers-market-dev --nodegroup-name primary
```

---

**Next Steps:** After successful deployment, proceed to the [Architecture Guide](ARCHITECTURE.md) for detailed infrastructure understanding.
