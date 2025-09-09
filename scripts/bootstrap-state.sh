#!/bin/bash
# =============================================================================
# TERRAFORM STATE BOOTSTRAP SCRIPT
# =============================================================================
# This script creates the necessary AWS resources for Terraform state management
# Run this script once before initializing Terraform backends

set -e

# Configuration
AWS_REGION="us-east-1"
PROJECT_NAME="farmers-market"
ENVIRONMENTS=("dev" "prod")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if AWS CLI is installed and configured
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS CLI is not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    log_success "AWS CLI is configured"
}

# Create S3 bucket for Terraform state
create_s3_bucket() {
    local env=$1
    local bucket_name="${PROJECT_NAME}-terraform-state-${env}"
    
    log_info "Creating S3 bucket: ${bucket_name}"
    
    # Check if bucket already exists
    if aws s3api head-bucket --bucket "${bucket_name}" 2>/dev/null; then
        log_warning "Bucket ${bucket_name} already exists"
        return 0
    fi
    
    # Create bucket
    if [ "${AWS_REGION}" = "us-east-1" ]; then
        aws s3api create-bucket --bucket "${bucket_name}" --region "${AWS_REGION}"
    else
        aws s3api create-bucket --bucket "${bucket_name}" --region "${AWS_REGION}" --create-bucket-configuration LocationConstraint="${AWS_REGION}"
    fi
    
    # Enable versioning
    aws s3api put-bucket-versioning --bucket "${bucket_name}" --versioning-configuration Status=Enabled
    
    # Enable server-side encryption
    aws s3api put-bucket-encryption --bucket "${bucket_name}" --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }'
    
    # Block public access
    aws s3api put-public-access-block --bucket "${bucket_name}" --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
    
    # Enable access logging
    aws s3api put-bucket-logging --bucket "${bucket_name}" --bucket-logging-status '{
        "LoggingEnabled": {
            "TargetBucket": "'${bucket_name}'-logs",
            "TargetPrefix": "access-logs/"
        }
    }'
    
    log_success "S3 bucket ${bucket_name} created successfully"
}

# Create DynamoDB table for state locking
create_dynamodb_table() {
    local env=$1
    local table_name="${PROJECT_NAME}-terraform-locks-${env}"
    
    log_info "Creating DynamoDB table: ${table_name}"
    
    # Check if table already exists
    if aws dynamodb describe-table --table-name "${table_name}" --region "${AWS_REGION}" 2>/dev/null; then
        log_warning "DynamoDB table ${table_name} already exists"
        return 0
    fi
    
    # Create table
    aws dynamodb create-table \
        --table-name "${table_name}" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
        --region "${AWS_REGION}"
    
    # Wait for table to be active
    aws dynamodb wait table-exists --table-name "${table_name}" --region "${AWS_REGION}"
    
    log_success "DynamoDB table ${table_name} created successfully"
}

# Create KMS key for state encryption
create_kms_key() {
    local env=$1
    local key_alias="alias/terraform-state-key-${env}"
    
    log_info "Creating KMS key: ${key_alias}"
    
    # Check if key already exists
    if aws kms describe-key --key-id "${key_alias}" --region "${AWS_REGION}" 2>/dev/null; then
        log_warning "KMS key ${key_alias} already exists"
        return 0
    fi
    
    # Create KMS key
    local key_id=$(aws kms create-key \
        --description "Terraform state encryption key for ${env} environment" \
        --region "${AWS_REGION}" \
        --query 'KeyMetadata.KeyId' \
        --output text)
    
    # Create alias
    aws kms create-alias --alias-name "${key_alias}" --target-key-id "${key_id}" --region "${AWS_REGION}"
    
    log_success "KMS key ${key_alias} created successfully"
}

# Create IAM policy for Terraform state access
create_iam_policy() {
    local env=$1
    local policy_name="${PROJECT_NAME}-terraform-state-policy-${env}"
    
    log_info "Creating IAM policy: ${policy_name}"
    
    # Check if policy already exists
    if aws iam get-policy --policy-arn "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/${policy_name}" 2>/dev/null; then
        log_warning "IAM policy ${policy_name} already exists"
        return 0
    fi
    
    # Create policy document
    cat > "/tmp/terraform-state-policy-${env}.json" << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketVersioning",
                "s3:GetBucketLogging",
                "s3:GetBucketEncryption"
            ],
            "Resource": "arn:aws:s3:::${PROJECT_NAME}-terraform-state-${env}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject"
            ],
            "Resource": "arn:aws:s3:::${PROJECT_NAME}-terraform-state-${env}/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:DeleteItem"
            ],
            "Resource": "arn:aws:dynamodb:${AWS_REGION}:*:table/${PROJECT_NAME}-terraform-locks-${env}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "kms:Encrypt",
                "kms:Decrypt",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:DescribeKey"
            ],
            "Resource": "arn:aws:kms:${AWS_REGION}:*:key/*",
            "Condition": {
                "StringEquals": {
                    "kms:ViaService": "s3.${AWS_REGION}.amazonaws.com"
                }
            }
        }
    ]
}
EOF
    
    # Create policy
    aws iam create-policy \
        --policy-name "${policy_name}" \
        --policy-document file://"/tmp/terraform-state-policy-${env}.json" \
        --description "Policy for Terraform state management in ${env} environment"
    
    # Clean up
    rm "/tmp/terraform-state-policy-${env}.json"
    
    log_success "IAM policy ${policy_name} created successfully"
}

# Main execution
main() {
    log_info "Starting Terraform state bootstrap for project: ${PROJECT_NAME}"
    log_info "Region: ${AWS_REGION}"
    log_info "Environments: ${ENVIRONMENTS[*]}"
    
    # Check prerequisites
    check_aws_cli
    
    # Create resources for each environment
    for env in "${ENVIRONMENTS[@]}"; do
        log_info "Setting up resources for ${env} environment..."
        
        create_s3_bucket "${env}"
        create_dynamodb_table "${env}"
        create_kms_key "${env}"
        create_iam_policy "${env}"
        
        log_success "Environment ${env} setup completed"
    done
    
    log_success "Terraform state bootstrap completed successfully!"
    log_info "Next steps:"
    log_info "1. Attach the IAM policies to your user/role"
    log_info "2. Run 'terraform init' in each environment directory"
    log_info "3. Run 'terraform plan' to verify configuration"
}

# Run main function
main "$@"
