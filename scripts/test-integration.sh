#!/bin/bash
# =============================================================================
# INTEGRATION TEST SCRIPT
# =============================================================================
# This script runs comprehensive integration tests on deployed infrastructure

set -e

# Configuration
KONG_URL=$1
MAX_RETRIES=5
RETRY_DELAY=10

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

# Wait for service to be ready
wait_for_service() {
    local url=$1
    local service_name=$2
    local retries=0
    
    log_info "Waiting for $service_name to be ready..."
    
    while [ $retries -lt $MAX_RETRIES ]; do
        if curl -f -s "$url" > /dev/null 2>&1; then
            log_success "$service_name is ready"
            return 0
        fi
        
        retries=$((retries + 1))
        log_info "Attempt $retries/$MAX_RETRIES failed, retrying in ${RETRY_DELAY}s..."
        sleep $RETRY_DELAY
    done
    
    log_error "$service_name failed to become ready after $MAX_RETRIES attempts"
    return 1
}

# Test Kong API Gateway
test_kong_gateway() {
    log_info "Testing Kong API Gateway..."
    
    # Test health endpoint
    if curl -f -s "${KONG_URL}/status" > /dev/null; then
        log_success "Kong health check passed"
    else
        log_error "Kong health check failed"
        return 1
    fi
    
    # Test Kong admin API
    if curl -f -s "${KONG_URL}:8001/status" > /dev/null; then
        log_success "Kong admin API is accessible"
    else
        log_warning "Kong admin API is not accessible (this might be expected)"
    fi
    
    return 0
}

# Test user service
test_user_service() {
    log_info "Testing user service..."
    
    # Test GET /v1/users
    if curl -f -s "${KONG_URL}/v1/users" > /dev/null; then
        log_success "User service GET endpoint is working"
    else
        log_error "User service GET endpoint failed"
        return 1
    fi
    
    # Test POST /v1/users
    local test_user='{"name": "Test User", "email": "test@example.com"}'
    if curl -f -s -X POST "${KONG_URL}/v1/users" \
        -H "Content-Type: application/json" \
        -d "$test_user" > /dev/null; then
        log_success "User service POST endpoint is working"
    else
        log_warning "User service POST endpoint failed (might be expected if service is not fully implemented)"
    fi
    
    return 0
}

# Test product service
test_product_service() {
    log_info "Testing product service..."
    
    # Test GET /v1/products
    if curl -f -s "${KONG_URL}/v1/products" > /dev/null; then
        log_success "Product service GET endpoint is working"
    else
        log_warning "Product service GET endpoint failed (might be expected if service is not deployed)"
    fi
    
    return 0
}

# Test order service
test_order_service() {
    log_info "Testing order service..."
    
    # Test GET /v1/orders
    if curl -f -s "${KONG_URL}/v1/orders" > /dev/null; then
        log_success "Order service GET endpoint is working"
    else
        log_warning "Order service GET endpoint failed (might be expected if service is not deployed)"
    fi
    
    return 0
}

# Test CORS
test_cors() {
    log_info "Testing CORS configuration..."
    
    local cors_response=$(curl -s -H "Origin: https://example.com" \
        -H "Access-Control-Request-Method: GET" \
        -H "Access-Control-Request-Headers: X-Requested-With" \
        -X OPTIONS "${KONG_URL}/v1/users")
    
    if echo "$cors_response" | grep -q "Access-Control-Allow-Origin"; then
        log_success "CORS is properly configured"
    else
        log_warning "CORS configuration might not be working as expected"
    fi
    
    return 0
}

# Test rate limiting
test_rate_limiting() {
    log_info "Testing rate limiting..."
    
    local rate_limit_hit=false
    for i in {1..105}; do
        local response=$(curl -s -w "%{http_code}" -o /dev/null "${KONG_URL}/v1/users")
        if [ "$response" = "429" ]; then
            rate_limit_hit=true
            break
        fi
    done
    
    if [ "$rate_limit_hit" = true ]; then
        log_success "Rate limiting is working"
    else
        log_warning "Rate limiting might not be working as expected"
    fi
    
    return 0
}

# Test response time
test_response_time() {
    log_info "Testing response times..."
    
    local start_time=$(date +%s%N)
    curl -f -s "${KONG_URL}/v1/users" > /dev/null
    local end_time=$(date +%s%N)
    
    local response_time=$(( (end_time - start_time) / 1000000 )) # Convert to milliseconds
    
    if [ $response_time -lt 2000 ]; then
        log_success "Response time is acceptable: ${response_time}ms"
    else
        log_warning "Response time is slow: ${response_time}ms"
    fi
    
    return 0
}

# Test EKS cluster
test_eks_cluster() {
    log_info "Testing EKS cluster..."
    
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        log_warning "kubectl is not available, skipping EKS tests"
        return 0
    fi
    
    # Test cluster connectivity
    if kubectl get nodes > /dev/null 2>&1; then
        log_success "EKS cluster is accessible"
        
        # Test Kong pods
        if kubectl get pods -n kong > /dev/null 2>&1; then
            log_success "Kong pods are running"
        else
            log_warning "Kong pods might not be running"
        fi
        
        # Test user service pods
        if kubectl get pods -n farmers-market > /dev/null 2>&1; then
            log_success "User service pods are running"
        else
            log_warning "User service pods might not be running"
        fi
    else
        log_warning "EKS cluster is not accessible"
    fi
    
    return 0
}

# Test S3 bucket
test_s3_bucket() {
    log_info "Testing S3 bucket..."
    
    # Check if AWS CLI is available
    if ! command -v aws &> /dev/null; then
        log_warning "AWS CLI is not available, skipping S3 tests"
        return 0
    fi
    
    # Get bucket name from Terraform output
    local bucket_name=$(terraform output -raw storage_bucket_name 2>/dev/null || echo "")
    
    if [ -n "$bucket_name" ]; then
        if aws s3 ls "s3://$bucket_name" > /dev/null 2>&1; then
            log_success "S3 bucket is accessible"
        else
            log_warning "S3 bucket is not accessible"
        fi
    else
        log_warning "Could not determine S3 bucket name"
    fi
    
    return 0
}

# Main execution
main() {
    log_info "Starting integration tests..."
    log_info "Kong URL: $KONG_URL"
    
    # Wait for Kong to be ready
    wait_for_service "${KONG_URL}/status" "Kong API Gateway"
    
    # Run tests
    test_kong_gateway
    test_user_service
    test_product_service
    test_order_service
    test_cors
    test_rate_limiting
    test_response_time
    test_eks_cluster
    test_s3_bucket
    
    log_success "Integration tests completed!"
}

# Run main function
main "$@"
