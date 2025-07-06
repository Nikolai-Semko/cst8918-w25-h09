#!/bin/bash

# Deployment script for AKS cluster and sample application
# CST8918 - H09 Assignment

set -e  # Exit on any error

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

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI is not installed. Please install Azure CLI first."
        exit 1
    fi
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    # Check if logged in to Azure
    if ! az account show &> /dev/null; then
        log_error "Not logged in to Azure. Please run 'az login' first."
        exit 1
    fi
    
    log_success "All prerequisites are met!"
}

# Deploy infrastructure
deploy_infrastructure() {
    log_info "Deploying AKS infrastructure with Terraform..."
    
    # Initialize Terraform
    log_info "Initializing Terraform..."
    terraform init
    
    # Validate configuration
    log_info "Validating Terraform configuration..."
    terraform validate
    
    # Plan deployment
    log_info "Creating Terraform plan..."
    terraform plan -out=tfplan
    
    # Apply deployment
    log_info "Applying Terraform configuration..."
    terraform apply tfplan
    
    log_success "Infrastructure deployment completed!"
}

# Configure kubectl
configure_kubectl() {
    log_info "Configuring kubectl to connect to AKS cluster..."
    
    # Extract kubeconfig from Terraform output
    log_info "Extracting kubeconfig..."
    terraform output -raw kube_config > ./kubeconfig
    
    # Check if kubeconfig has eof markers and remove them
    if grep -q "<<EOF" ./kubeconfig; then
        log_warning "Removing EOF markers from kubeconfig..."
        sed -i '1d;$d' ./kubeconfig
    fi
    
    # Set KUBECONFIG environment variable
    export KUBECONFIG=./kubeconfig
    
    # Test connection
    log_info "Testing connection to AKS cluster..."
    if kubectl get nodes; then
        log_success "Successfully connected to AKS cluster!"
    else
        log_error "Failed to connect to AKS cluster."
        exit 1
    fi
    
    # Display cluster information
    log_info "Cluster information:"
    kubectl cluster-info
}

# Deploy sample application
deploy_application() {
    log_info "Deploying sample application..."
    
    # Apply the sample application
    kubectl apply -f sample-app.yaml
    
    log_info "Waiting for pods to be ready..."
    kubectl wait --for=condition=ready pod --all --timeout=300s
    
    log_success "Sample application deployed successfully!"
    
    # Display application status
    log_info "Application status:"
    kubectl get pods
    kubectl get services
    
    # Get LoadBalancer IP
    log_info "Waiting for LoadBalancer IP to be assigned..."
    external_ip=""
    while [ -z $external_ip ]; do
        external_ip=$(kubectl get service store-front --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}")
        [ -z "$external_ip" ] && sleep 10
    done
    
    log_success "Application is accessible at: http://$external_ip"
    log_info "You can also check the RabbitMQ management interface at: http://$external_ip:15672"
    log_info "RabbitMQ credentials: username/password"
}

# Main deployment function
main() {
    log_info "Starting AKS deployment process..."
    
    check_prerequisites
    deploy_infrastructure
    configure_kubectl
    deploy_application
    
    log_success "🎉 Deployment completed successfully!"
    log_info "Next steps:"
    echo "1. Access the application at the LoadBalancer IP shown above"
    echo "2. Monitor your application: kubectl get pods"
    echo "3. View logs: kubectl logs -f deployment/store-front"
    echo "4. Scale applications: kubectl scale deployment store-front --replicas=3"
    echo "5. When done, clean up: terraform destroy"
}

# Cleanup function
cleanup() {
    log_info "Cleaning up resources..."
    
    # Delete application first
    if [ -f "sample-app.yaml" ]; then
        log_info "Deleting sample application..."
        kubectl delete -f sample-app.yaml --ignore-not-found=true
    fi
    
    # Wait a bit for cleanup
    sleep 30
    
    # Destroy infrastructure
    log_info "Destroying infrastructure..."
    terraform destroy -auto-approve
    
    # Clean up local files
    rm -f ./kubeconfig
    rm -f tfplan
    
    log_success "Cleanup completed!"
}

# Handle script arguments
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "cleanup")
        cleanup
        ;;
    "app-only")
        configure_kubectl
        deploy_application
        ;;
    *)
        echo "Usage: $0 [deploy|cleanup|app-only]"
        echo "  deploy    - Deploy infrastructure and application (default)"
        echo "  cleanup   - Clean up all resources"
        echo "  app-only  - Deploy only the application (infrastructure must exist)"
        exit 1
        ;;
esac