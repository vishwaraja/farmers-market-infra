#!/bin/bash

# =============================================================================
# DEPLOYMENT SCRIPT - FARMERS MARKET INFRASTRUCTURE
# =============================================================================
# This script automates the deployment of infrastructure for different environments

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
ACTION=""
AUTO_APPROVE=false
PLAN_ONLY=false

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
Usage: $0 [OPTIONS] ENVIRONMENT ACTION

Deploy Farmers Market infrastructure using Terraform

ARGUMENTS:
    ENVIRONMENT    Target environment (dev, staging, production)
    ACTION         Action to perform (plan, apply, destroy, init)

OPTIONS:
    -h, --help     Show this help message
    -y, --yes      Auto-approve terraform apply/destroy
    -p, --plan     Only run terraform plan (for apply action)

EXAMPLES:
    $0 dev init                    # Initialize dev environment
    $0 dev plan                    # Plan dev environment changes
    $0 dev apply                   # Apply dev environment changes
    $0 dev apply --plan            # Only plan dev environment changes
    $0 production apply --yes      # Auto-approve production deployment

ENVIRONMENTS:
    dev         Development environment (minimal resources, spot instances)
    staging     Staging environment (medium resources, mixed instances)
    production  Production environment (full resources, on-demand instances)

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

# Function to validate action
validate_action() {
    local action=$1
    case $action in
        init|plan|apply|destroy)
            return 0
            ;;
        *)
            print_error "Invalid action: $action"
            print_info "Valid actions: init, plan, apply, destroy"
            exit 1
            ;;
    esac
}

# Function to check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
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
    
    # Check if kubectl is installed (for apply action)
    if [[ "$ACTION" == "apply" ]] && ! command -v kubectl &> /dev/null; then
        print_warning "kubectl is not installed. You may need it to interact with the EKS cluster."
    fi
    
    print_success "Prerequisites check passed"
}

# Function to check if terraform.tfvars exists
check_tfvars() {
    local env_dir="$PROJECT_ROOT/environments/$ENVIRONMENT"
    local tfvars_file="$env_dir/terraform.tfvars"
    
    if [[ ! -f "$tfvars_file" ]]; then
        print_warning "terraform.tfvars not found in $env_dir"
        print_info "Copying terraform.tfvars.example to terraform.tfvars"
        
        if [[ -f "$env_dir/terraform.tfvars.example" ]]; then
            cp "$env_dir/terraform.tfvars.example" "$tfvars_file"
            print_success "Created terraform.tfvars from example"
            print_warning "Please review and customize terraform.tfvars before proceeding"
            read -p "Press Enter to continue or Ctrl+C to abort..."
        else
            print_error "terraform.tfvars.example not found in $env_dir"
            exit 1
        fi
    fi
}

# Function to run terraform command
run_terraform() {
    local env_dir="$PROJECT_ROOT/environments/$ENVIRONMENT"
    local command="$1"
    shift
    
    print_info "Running: terraform $command $*"
    print_info "Working directory: $env_dir"
    
    cd "$env_dir"
    
    case $command in
        init)
            terraform init
            ;;
        plan)
            terraform plan "$@"
            ;;
        apply)
            if [[ "$AUTO_APPROVE" == true ]]; then
                terraform apply -auto-approve "$@"
            else
                terraform apply "$@"
            fi
            ;;
        destroy)
            if [[ "$AUTO_APPROVE" == true ]]; then
                terraform destroy -auto-approve "$@"
            else
                print_warning "This will destroy all resources in the $ENVIRONMENT environment!"
                read -p "Are you sure? Type 'yes' to continue: " confirm
                if [[ "$confirm" == "yes" ]]; then
                    terraform destroy "$@"
                else
                    print_info "Destroy cancelled"
                    exit 0
                fi
            fi
            ;;
    esac
}

# Function to show post-deployment information
show_post_deployment_info() {
    if [[ "$ACTION" == "apply" ]]; then
        print_success "Deployment completed successfully!"
        print_info "To connect to your EKS cluster, run:"
        echo "  aws eks update-kubeconfig --region \$(terraform output -raw aws_region) --name \$(terraform output -raw cluster_name)"
        echo ""
        print_info "To verify the cluster, run:"
        echo "  kubectl get nodes"
        echo "  kubectl get pods -A"
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -y|--yes)
            AUTO_APPROVE=true
            shift
            ;;
        -p|--plan)
            PLAN_ONLY=true
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
        init|plan|apply|destroy)
            if [[ -z "$ACTION" ]]; then
                ACTION="$1"
            else
                print_error "Action already specified: $ACTION"
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

if [[ -z "$ACTION" ]]; then
    print_error "Action is required"
    show_usage
    exit 1
fi

# Validate arguments
validate_environment "$ENVIRONMENT"
validate_action "$ACTION"

# Handle plan-only mode
if [[ "$PLAN_ONLY" == true && "$ACTION" == "apply" ]]; then
    ACTION="plan"
fi

# Main execution
print_info "Starting Farmers Market infrastructure deployment"
print_info "Environment: $ENVIRONMENT"
print_info "Action: $ACTION"

check_prerequisites
check_tfvars

# Run terraform command
run_terraform "$ACTION"

show_post_deployment_info

print_success "Script completed successfully!"
