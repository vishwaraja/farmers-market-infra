#!/bin/bash

# =============================================================================
# VALIDATION SCRIPT - FARMERS MARKET INFRASTRUCTURE
# =============================================================================
# This script validates the Terraform configuration and infrastructure

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
CHECK_ALL=false
VALIDATE_TERRAFORM=true
VALIDATE_AWS=true
VALIDATE_KUBERNETES=true

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
Usage: $0 [OPTIONS] [ENVIRONMENT]

Validate Farmers Market infrastructure configuration and deployment

ARGUMENTS:
    ENVIRONMENT    Target environment (dev, staging, production) [optional]

OPTIONS:
    -h, --help         Show this help message
    -a, --all          Check all environments
    --terraform-only   Only validate Terraform configuration
    --aws-only         Only validate AWS resources
    --k8s-only         Only validate Kubernetes cluster

EXAMPLES:
    $0                          # Validate all environments
    $0 dev                      # Validate dev environment
    $0 --all                    # Validate all environments
    $0 dev --terraform-only     # Only validate Terraform for dev

VALIDATION CHECKS:
    - Terraform configuration syntax
    - AWS credentials and permissions
    - Infrastructure deployment status
    - Kubernetes cluster connectivity
    - Resource health and status

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
    
    local missing_tools=()
    
    # Check required tools
    command -v terraform &> /dev/null || missing_tools+=("terraform")
    command -v aws &> /dev/null || missing_tools+=("aws")
    command -v kubectl &> /dev/null || missing_tools+=("kubectl")
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_info "Please install the missing tools and try again"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured or invalid"
        print_info "Please run 'aws configure' to set up credentials"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to validate Terraform configuration
validate_terraform() {
    local env=$1
    local env_dir="$PROJECT_ROOT/environments/$env"
    
    print_info "Validating Terraform configuration for $env environment..."
    
    if [[ ! -d "$env_dir" ]]; then
        print_error "Environment directory not found: $env_dir"
        return 1
    fi
    
    cd "$env_dir"
    
    # Check if terraform.tfvars exists
    if [[ ! -f "terraform.tfvars" ]]; then
        print_warning "terraform.tfvars not found in $env_dir"
        if [[ -f "terraform.tfvars.example" ]]; then
            print_info "Copying terraform.tfvars.example to terraform.tfvars"
            cp terraform.tfvars.example terraform.tfvars
        else
            print_error "terraform.tfvars.example not found"
            return 1
        fi
    fi
    
    # Initialize Terraform
    print_info "Initializing Terraform..."
    if ! terraform init -backend=false; then
        print_error "Terraform initialization failed"
        return 1
    fi
    
    # Validate configuration
    print_info "Validating Terraform configuration..."
    if ! terraform validate; then
        print_error "Terraform validation failed"
        return 1
    fi
    
    # Format check
    print_info "Checking Terraform formatting..."
    if ! terraform fmt -check -diff; then
        print_warning "Terraform files are not properly formatted"
        print_info "Run 'terraform fmt' to fix formatting issues"
    fi
    
    print_success "Terraform validation passed for $env environment"
    return 0
}

# Function to validate AWS resources
validate_aws() {
    local env=$1
    
    print_info "Validating AWS resources for $env environment..."
    
    # Check if cluster exists
    local cluster_name="farmers-market-$env"
    if ! aws eks describe-cluster --name "$cluster_name" --region us-east-1 &> /dev/null; then
        print_warning "EKS cluster $cluster_name not found or not accessible"
        return 1
    fi
    
    # Get cluster status
    local cluster_status=$(aws eks describe-cluster --name "$cluster_name" --region us-east-1 --query 'cluster.status' --output text)
    if [[ "$cluster_status" != "ACTIVE" ]]; then
        print_error "EKS cluster $cluster_name is not active (status: $cluster_status)"
        return 1
    fi
    
    # Check node groups
    print_info "Checking node groups..."
    local nodegroups=$(aws eks list-nodegroups --cluster-name "$cluster_name" --region us-east-1 --query 'nodegroups' --output text)
    if [[ -z "$nodegroups" ]]; then
        print_error "No node groups found for cluster $cluster_name"
        return 1
    fi
    
    # Check node group status
    for nodegroup in $nodegroups; do
        local ng_status=$(aws eks describe-nodegroup --cluster-name "$cluster_name" --nodegroup-name "$nodegroup" --region us-east-1 --query 'nodegroup.status' --output text)
        if [[ "$ng_status" != "ACTIVE" ]]; then
            print_error "Node group $nodegroup is not active (status: $ng_status)"
            return 1
        fi
        print_success "Node group $nodegroup is active"
    done
    
    # Check VPC
    print_info "Checking VPC..."
    local vpc_id=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=*$env*farmers-market*vpc" --query 'Vpcs[0].VpcId' --output text)
    if [[ "$vpc_id" == "None" || -z "$vpc_id" ]]; then
        print_error "VPC not found for $env environment"
        return 1
    fi
    print_success "VPC $vpc_id found"
    
    print_success "AWS resources validation passed for $env environment"
    return 0
}

# Function to validate Kubernetes cluster
validate_kubernetes() {
    local env=$1
    
    print_info "Validating Kubernetes cluster for $env environment..."
    
    local cluster_name="farmers-market-$env"
    
    # Update kubeconfig
    if ! aws eks update-kubeconfig --region us-east-1 --name "$cluster_name"; then
        print_error "Failed to update kubeconfig for cluster $cluster_name"
        return 1
    fi
    
    # Check cluster connectivity
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster $cluster_name"
        return 1
    fi
    
    # Check nodes
    print_info "Checking cluster nodes..."
    local node_count=$(kubectl get nodes --no-headers | wc -l)
    if [[ $node_count -eq 0 ]]; then
        print_error "No nodes found in cluster $cluster_name"
        return 1
    fi
    
    local ready_nodes=$(kubectl get nodes --no-headers | grep -c "Ready")
    if [[ $ready_nodes -ne $node_count ]]; then
        print_warning "Not all nodes are ready ($ready_nodes/$node_count)"
    else
        print_success "All $node_count nodes are ready"
    fi
    
    # Check system pods
    print_info "Checking system pods..."
    local system_pods=$(kubectl get pods -n kube-system --no-headers | wc -l)
    if [[ $system_pods -eq 0 ]]; then
        print_error "No system pods found"
        return 1
    fi
    
    local running_pods=$(kubectl get pods -n kube-system --no-headers | grep -c "Running")
    if [[ $running_pods -ne $system_pods ]]; then
        print_warning "Not all system pods are running ($running_pods/$system_pods)"
    else
        print_success "All $system_pods system pods are running"
    fi
    
    print_success "Kubernetes cluster validation passed for $env environment"
    return 0
}

# Function to validate single environment
validate_single_environment() {
    local env=$1
    local failed=0
    
    print_info "Validating $env environment..."
    
    if [[ "$VALIDATE_TERRAFORM" == true ]]; then
        if ! validate_terraform "$env"; then
            failed=1
        fi
    fi
    
    if [[ "$VALIDATE_AWS" == true ]]; then
        if ! validate_aws "$env"; then
            failed=1
        fi
    fi
    
    if [[ "$VALIDATE_KUBERNETES" == true ]]; then
        if ! validate_kubernetes "$env"; then
            failed=1
        fi
    fi
    
    if [[ $failed -eq 0 ]]; then
        print_success "All validations passed for $env environment"
    else
        print_error "Some validations failed for $env environment"
    fi
    
    return $failed
}

# Function to validate all environments
validate_all_environments() {
    local failed=0
    
    print_info "Validating all environments..."
    
    for env in dev staging production; do
        if [[ -d "$PROJECT_ROOT/environments/$env" ]]; then
            if ! validate_single_environment "$env"; then
                failed=1
            fi
        else
            print_warning "Environment $env not found, skipping"
        fi
    done
    
    return $failed
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -a|--all)
            CHECK_ALL=true
            shift
            ;;
        --terraform-only)
            VALIDATE_AWS=false
            VALIDATE_KUBERNETES=false
            shift
            ;;
        --aws-only)
            VALIDATE_TERRAFORM=false
            VALIDATE_KUBERNETES=false
            shift
            ;;
        --k8s-only)
            VALIDATE_TERRAFORM=false
            VALIDATE_AWS=false
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

# Main execution
print_info "Starting Farmers Market infrastructure validation"

check_prerequisites

# Determine what to validate
if [[ "$CHECK_ALL" == true ]]; then
    validate_all_environments
elif [[ -n "$ENVIRONMENT" ]]; then
    validate_environment "$ENVIRONMENT"
    validate_single_environment "$ENVIRONMENT"
else
    validate_all_environments
fi

if [[ $? -eq 0 ]]; then
    print_success "All validations completed successfully!"
else
    print_error "Some validations failed. Please review the output above."
    exit 1
fi
