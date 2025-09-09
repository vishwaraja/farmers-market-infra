# Terraform State Management

This document outlines the industry standard practices for Terraform state management implemented in this project.

## 🏗️ **Architecture Overview**

```
┌─────────────────────────────────────────────────────────────┐
│                    TERRAFORM STATE ARCHITECTURE             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │    DEV      │    │   STAGING   │    │    PROD     │     │
│  │ Environment │    │ Environment │    │ Environment │     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
│         │                   │                   │           │
│         ▼                   ▼                   ▼           │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │ S3 Bucket   │    │ S3 Bucket   │    │ S3 Bucket   │     │
│  │ dev-state   │    │staging-state│    │ prod-state  │     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
│         │                   │                   │           │
│         ▼                   ▼                   ▼           │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │ DynamoDB    │    │ DynamoDB    │    │ DynamoDB    │     │
│  │ dev-locks   │    │staging-locks│    │ prod-locks  │     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 🎯 **Industry Standard Practices**

### **1. Remote State Storage (S3)**

**✅ What We Use:**
- **S3 Backend**: Industry standard for AWS environments
- **Encryption**: AES-256 encryption at rest
- **Versioning**: S3 bucket versioning enabled
- **Access Logging**: S3 access logs for audit trails

**Configuration:**
```hcl
terraform {
  backend "s3" {
    bucket         = "farmers-market-terraform-state-dev"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    kms_key_id     = "alias/terraform-state-key-dev"
  }
}
```

### **2. State Locking (DynamoDB)**

**✅ What We Use:**
- **DynamoDB Table**: Prevents concurrent state modifications
- **Atomic Operations**: Ensures state consistency
- **Lock Timeout**: Automatic lock release on failure

**Configuration:**
```hcl
terraform {
  backend "s3" {
    dynamodb_table = "farmers-market-terraform-locks-dev"
  }
}
```

### **3. Environment Isolation**

**✅ What We Use:**
- **Separate Buckets**: Each environment has its own S3 bucket
- **Separate Keys**: Different state file paths per environment
- **Separate Locks**: Different DynamoDB tables per environment

**Structure:**
```
farmers-market-terraform-state-dev/
├── dev/terraform.tfstate

farmers-market-terraform-state-prod/
├── production/terraform.tfstate
```

### **4. Security Best Practices**

**✅ What We Use:**
- **KMS Encryption**: Customer-managed encryption keys
- **IAM Policies**: Least privilege access principles
- **Bucket Policies**: Restrictive access controls
- **Public Access Block**: All public access blocked

## 🚀 **Setup Instructions**

### **Step 1: Bootstrap State Resources**

Run the bootstrap script to create all necessary AWS resources:

```bash
# Make script executable
chmod +x scripts/bootstrap-state.sh

# Run bootstrap (creates S3 buckets, DynamoDB tables, KMS keys)
./scripts/bootstrap-state.sh
```

### **Step 2: Configure IAM Permissions**

Attach the created IAM policy to your user/role:

```bash
# Get your AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Attach policy to your user
aws iam attach-user-policy \
  --user-name YOUR_USERNAME \
  --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/farmers-market-terraform-state-policy-dev
```

### **Step 3: Initialize Terraform**

```bash
# Navigate to environment directory
cd environments/dev

# Initialize Terraform with S3 backend
terraform init

# Verify configuration
terraform plan
```

## 📋 **State Management Commands**

### **Basic Operations**
```bash
# Initialize backend
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply

# Destroy resources
terraform destroy
```

### **State Operations**
```bash
# List resources in state
terraform state list

# Show specific resource
terraform state show aws_s3_bucket.example

# Move resource in state
terraform state mv aws_s3_bucket.old aws_s3_bucket.new

# Remove resource from state
terraform state rm aws_s3_bucket.example

# Import existing resource
terraform import aws_s3_bucket.example bucket-name
```

### **State Locking**
```bash
# Force unlock (use with caution)
terraform force-unlock LOCK_ID

# Check lock status
terraform plan  # Will show if locked
```

## 🔒 **Security Considerations**

### **1. Access Control**
- **IAM Users**: Use dedicated service accounts
- **IAM Roles**: Prefer roles over users for applications
- **Least Privilege**: Grant minimum required permissions
- **MFA**: Enable MFA for human users

### **2. Encryption**
- **At Rest**: S3 server-side encryption with KMS
- **In Transit**: HTTPS for all API calls
- **Key Management**: Customer-managed KMS keys

### **3. Monitoring**
- **CloudTrail**: Log all API calls
- **S3 Access Logs**: Monitor bucket access
- **DynamoDB Metrics**: Monitor table usage
- **KMS CloudTrail**: Log key usage

## 🏢 **Enterprise Best Practices**

### **1. Multi-Account Strategy**
```bash
# Development Account
terraform {
  backend "s3" {
    bucket = "company-terraform-state-dev"
    key    = "dev/terraform.tfstate"
  }
}

# Production Account
terraform {
  backend "s3" {
    bucket = "company-terraform-state-prod"
    key    = "prod/terraform.tfstate"
  }
}
```

### **2. State File Organization**
```
terraform-state-bucket/
├── dev/
│   ├── terraform.tfstate
│   └── terraform.tfstate.backup
├── staging/
│   ├── terraform.tfstate
│   └── terraform.tfstate.backup
└── prod/
    ├── terraform.tfstate
    └── terraform.tfstate.backup
```

### **3. Backup and Recovery**
- **S3 Versioning**: Automatic backup of state files
- **Cross-Region Replication**: For disaster recovery
- **Regular Backups**: Export state to secure location
- **State Validation**: Regular state file integrity checks

## 🚨 **Troubleshooting**

### **Common Issues**

#### **1. State Lock Issues**
```bash
# Check if state is locked
terraform plan

# Force unlock (use carefully)
terraform force-unlock LOCK_ID
```

#### **2. Backend Configuration Issues**
```bash
# Reconfigure backend
terraform init -reconfigure

# Migrate state
terraform init -migrate-state
```

#### **3. Permission Issues**
```bash
# Check AWS credentials
aws sts get-caller-identity

# Test S3 access
aws s3 ls s3://your-terraform-state-bucket

# Test DynamoDB access
aws dynamodb describe-table --table-name your-locks-table
```

## 📊 **Cost Optimization**

### **S3 Costs**
- **Storage**: ~$0.023 per GB per month
- **Requests**: ~$0.0004 per 1,000 PUT requests
- **Versioning**: Additional storage for old versions

### **DynamoDB Costs**
- **On-Demand**: $1.25 per million read/write requests
- **Provisioned**: $0.25 per hour for 5 RCU/WCU

### **KMS Costs**
- **Customer Keys**: $1 per month per key
- **API Calls**: $0.03 per 10,000 requests

## 🔄 **Migration Strategies**

### **1. Local to Remote State**
```bash
# Initialize with backend
terraform init

# Migrate existing state
terraform init -migrate-state
```

### **2. Backend Migration**
```bash
# Update backend configuration
# Edit backend.tf

# Reinitialize
terraform init -migrate-state
```

### **3. State File Splitting**
```bash
# Use terraform state mv to reorganize
terraform state mv aws_s3_bucket.example module.storage.aws_s3_bucket.example
```

## 📚 **Additional Resources**

- [Terraform Backend Configuration](https://www.terraform.io/docs/backends/)
- [AWS S3 Backend](https://www.terraform.io/docs/backends/types/s3.html)
- [Terraform State Management](https://www.terraform.io/docs/state/)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
