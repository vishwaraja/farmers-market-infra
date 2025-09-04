#!/bin/bash

# =============================================================================
# BOOTSTRAP SCRIPT - CREATE S3 BACKEND AND DYNAMODB TABLES
# =============================================================================
# This script creates the necessary S3 buckets and DynamoDB tables for
# Terraform state management before running terraform init

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Default values
ENVIRONMENT=""
AWS_REGION="us-east-1"
FORCE=false

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] ENVIRONMENT

Bootstrap Terraform state management resources for Farmers Market infrastructure

ARGUMENTS:
    ENVIRONMENT    Target environment (dev, staging, production)

OPTIONS:
    -h, --help     Show this help message
    -r, --region   AWS region (default: us-east-1)
    -f, --force    Force recreation of existing resources

EXAMPLES:
    $0 dev                    # Bootstrap dev environment
    $0 production --region us-west-2  # Bootstrap production in us-west-2
    $0 staging --force        # Force recreation of staging resources

This script creates:
- S3 bucket for Terraform state storage
- DynamoDB table for state locking
- KMS key for state encryption

EOF
}

# Function to validate environment
validate_environment() {
    local env=$1
    case $env in
        dev|staging|production)
            return 0
            ;;
        *)
            print_error "Invalid environment: $env"
            print_info "Valid environments: dev, staging, production"
            exit 1
            ;;
    esac
}

# Function to check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check if aws cli is installed
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to create S3 bucket
create_s3_bucket() {
    local bucket_name="farmers-market-terraform-state-${ENVIRONMENT}"
    
    print_info "Creating S3 bucket: $bucket_name"
    
    # Check if bucket exists
    if aws s3api head-bucket --bucket "$bucket_name" 2>/dev/null; then
        if [[ "$FORCE" == true ]]; then
            print_warning "Bucket $bucket_name already exists. Force mode enabled, skipping creation."
        else
            print_info "Bucket $bucket_name already exists, skipping creation."
            return 0
        fi
    else
        # Create bucket
        if [[ "$AWS_REGION" == "us-east-1" ]]; then
            aws s3api create-bucket --bucket "$bucket_name"
        else
            aws s3api create-bucket --bucket "$bucket_name" --region "$AWS_REGION" --create-bucket-configuration LocationConstraint="$AWS_REGION"
        fi
        
        # Enable versioning
        aws s3api put-bucket-versioning --bucket "$bucket_name" --versioning-configuration Status=Enabled
        
        # Enable server-side encryption
        aws s3api put-bucket-encryption --bucket "$bucket_name" --server-side-encryption-configuration '{
            "Rules": [
                {
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }
            ]
        }'
        
        # Block public access
        aws s3api put-public-access-block --bucket "$bucket_name" --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
        
        print_success "S3 bucket $bucket_name created successfully"
    fi
}

# Function to create DynamoDB table
create_dynamodb_table() {
    local table_name="farmers-market-terraform-locks-${ENVIRONMENT}"
    
    print_info "Creating DynamoDB table: $table_name"
    
    # Check if table exists
    if aws dynamodb describe-table --table-name "$table_name" --region "$AWS_REGION" 2>/dev/null; then
        if [[ "$FORCE" == true ]]; then
            print_warning "Table $table_name already exists. Force mode enabled, skipping creation."
        else
            print_info "Table $table_name already exists, skipping creation."
            return 0
        fi
    else
        # Create table
        aws dynamodb create-table \
            --table-name "$table_name" \
            --attribute-definitions AttributeName=LockID,AttributeType=S \
            --key-schema AttributeName=LockID,KeyType=HASH \
            --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
            --region "$AWS_REGION"
        
        # Wait for table to be active
        print_info "Waiting for table to become active..."
        aws dynamodb wait table-exists --table-name "$table_name" --region "$AWS_REGION"
        
        print_success "DynamoDB table $table_name created successfully"
    fi
}

# Function to create KMS key
create_kms_key() {
    local key_alias="alias/terraform-state-key-${ENVIRONMENT}"
    
    print_info "Creating KMS key: $key_alias"
    
    # Check if key alias exists
    if aws kms describe-key --key-id "$key_alias" --region "$AWS_REGION" 2>/dev/null; then
        if [[ "$FORCE" == true ]]; then
            print_warning "KMS key $key_alias already exists. Force mode enabled, skipping creation."
        else
            print_info "KMS key $key_alias already exists, skipping creation."
            return 0
        fi
    else
        # Create key
        local key_id=$(aws kms create-key \
            --description "Terraform state encryption key for $ENVIRONMENT environment" \
            --region "$AWS_REGION" \
            --query 'KeyMetadata.KeyId' \
            --output text)
        
        # Create alias
        aws kms create-alias --alias-name "$key_alias" --target-key-id "$key_id" --region "$AWS_REGION"
        
        print_success "KMS key $key_alias created successfully"
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -r|--region)
            AWS_REGION="$2"
            shift 2
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        dev|staging|production)
            if [[ -z "$ENVIRONMENT" ]]; then
                ENVIRONMENT="$1"
            else
                print_error "Environment already specified: $ENVIRONMENT"
                exit 1
            fi
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate required arguments
if [[ -z "$ENVIRONMENT" ]]; then
    print_error "Environment is required"
    show_usage
    exit 1
fi

# Validate arguments
validate_environment "$ENVIRONMENT"

# Main execution
print_info "Starting bootstrap for Farmers Market infrastructure"
print_info "Environment: $ENVIRONMENT"
print_info "AWS Region: $AWS_REGION"

check_prerequisites

# Create resources
create_s3_bucket
create_dynamodb_table
create_kms_key

print_success "Bootstrap completed successfully!"
print_info "You can now run: ./scripts/deploy.sh $ENVIRONMENT init"
