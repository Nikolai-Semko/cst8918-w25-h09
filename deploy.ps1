# PowerShell deployment script for AKS cluster and sample application
# CST8918 - H09 Assignment

param(
    [Parameter()]
    [ValidateSet("deploy", "cleanup", "app-only")]
    [string]$Action = "deploy"
)

# Functions for colored output
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check prerequisites
function Test-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    # Check if terraform is installed
    if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
        Write-Error "Terraform is not installed. Please install Terraform first."
        exit 1
    }
    
    # Check if Azure CLI is installed
    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        Write-Error "Azure CLI is not installed. Please install Azure CLI first."
        exit 1
    }
    
    # Check if kubectl is installed
    if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
        Write-Error "kubectl is not installed. Please install kubectl first."
        exit 1
    }
    
    # Check if logged in to Azure
    try {
        az account show | Out-Null
    }
    catch {
        Write-Error "Not logged in to Azure. Please run 'az login' first."
        exit 1
    }
    
    Write-Success "All prerequisites are met!"
}

# Deploy infrastructure
function Deploy-Infrastructure {
    Write-Info "Deploying AKS infrastructure with Terraform..."
    
    # Initialize Terraform
    Write-Info "Initializing Terraform..."
    terraform init
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Terraform init failed"
        exit 1
    }
    
    # Validate configuration
    Write-Info "Validating Terraform configuration..."
    terraform validate
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Terraform validation failed"
        exit 1
    }
    
    # Plan deployment
    Write-Info "Creating Terraform plan..."
    terraform plan -out=tfplan
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Terraform plan failed"
        exit 1
    }
    
    # Apply deployment
    Write-Info "Applying Terraform configuration..."
    terraform apply tfplan
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Terraform apply failed"
        exit 1
    }
    
    Write-Success "Infrastructure deployment completed!"
}

# Configure kubectl
function Set-KubeConfig {
    Write-Info "Configuring kubectl to connect to AKS cluster..."
    
    # Extract kubeconfig from Terraform output
    Write-Info "Extracting kubeconfig..."
    $kubeconfig = terraform output -raw kube_config
    $kubeconfig | Out-File -FilePath "./kubeconfig" -Encoding UTF8
    
    # Check if kubeconfig has eof markers and remove them
    $content = Get-Content "./kubeconfig"
    if ($content[0] -like "*EOF*") {
        Write-Warning "Removing EOF markers from kubeconfig..."
        $content = $content[1..($content.Length-2)]
        $content | Out-File -FilePath "./kubeconfig" -Encoding UTF8
    }
    
    # Set KUBECONFIG environment variable
    $env:KUBECONFIG = ".\kubeconfig"
    
    # Test connection
    Write-Info "Testing connection to AKS cluster..."
    kubectl get nodes
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to connect to AKS cluster."
        exit 1
    }
    
    Write-Success "Successfully connected to AKS cluster!"
    
    # Display cluster information
    Write-Info "Cluster information:"
    kubectl cluster-info
}

# Deploy sample application
function Deploy-Application {
    Write-Info "Deploying sample application..."
    
    # Apply the sample application
    kubectl apply -f sample-app.yaml
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to deploy sample application"
        exit 1
    }
    
    Write-Info "Waiting for pods to be ready..."
    kubectl wait --for=condition=ready pod --all --timeout=300s
    
    Write-Success "Sample application deployed successfully!"
    
    # Display application status
    Write-Info "Application status:"
    kubectl get pods
    kubectl get services
    
    # Get LoadBalancer IP
    Write-Info "Waiting for LoadBalancer IP to be assigned..."
    do {
        Start-Sleep -Seconds 10
        $externalIp = kubectl get service store-front -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
    } while ([string]::IsNullOrWhiteSpace($externalIp))
    
    Write-Success "Application is accessible at: http://$externalIp"
    Write-Info "You can also check the RabbitMQ management interface at: http://$externalIp:15672"
    Write-Info "RabbitMQ credentials: username/password"
}

# Main deployment function
function Start-Deployment {
    Write-Info "Starting AKS deployment process..."
    
    Test-Prerequisites
    Deploy-Infrastructure
    Set-KubeConfig
    Deploy-Application
    
    Write-Success "🎉 Deployment completed successfully!"
    Write-Info "Next steps:"
    Write-Host "1. Access the application at the LoadBalancer IP shown above" -ForegroundColor Cyan
    Write-Host "2. Monitor your application: kubectl get pods" -ForegroundColor Cyan
    Write-Host "3. View logs: kubectl logs -f deployment/store-front" -ForegroundColor Cyan
    Write-Host "4. Scale applications: kubectl scale deployment store-front --replicas=3" -ForegroundColor Cyan
    Write-Host "5. When done, clean up: terraform destroy" -ForegroundColor Cyan
}

# Cleanup function
function Start-Cleanup {
    Write-Info "Cleaning up resources..."
    
    # Delete application first
    if (Test-Path "sample-app.yaml") {
        Write-Info "Deleting sample application..."
        kubectl delete -f sample-app.yaml --ignore-not-found=true
    }
    
    # Wait a bit for cleanup
    Start-Sleep -Seconds 30
    
    # Destroy infrastructure
    Write-Info "Destroying infrastructure..."
    terraform destroy -auto-approve
    
    # Clean up local files
    if (Test-Path "./kubeconfig") { Remove-Item "./kubeconfig" }
    if (Test-Path "tfplan") { Remove-Item "tfplan" }
    
    Write-Success "Cleanup completed!"
}

# Deploy application only
function Deploy-ApplicationOnly {
    Set-KubeConfig
    Deploy-Application
}

# Main script execution
switch ($Action) {
    "deploy" {
        Start-Deployment
    }
    "cleanup" {
        Start-Cleanup
    }
    "app-only" {
        Deploy-ApplicationOnly
    }
    default {
        Write-Host "Usage: .\deploy.ps1 [-Action <deploy|cleanup|app-only>]" -ForegroundColor Yellow
        Write-Host "  deploy    - Deploy infrastructure and application (default)" -ForegroundColor White
        Write-Host "  cleanup   - Clean up all resources" -ForegroundColor White
        Write-Host "  app-only  - Deploy only the application (infrastructure must exist)" -ForegroundColor White
    }
}