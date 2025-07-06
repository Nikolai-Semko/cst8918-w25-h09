# CST8918 - H09 Assignment Instructions

## 📋 Step-by-Step Execution Guide

### Prerequisites Setup

#### 1. Install Required Tools

**Terraform:**
```bash
# Windows (using Chocolatey)
choco install terraform

# Windows (using Scoop)
scoop install terraform

# macOS (using Homebrew)
brew install terraform

# Or download from: https://www.terraform.io/downloads
```

**Azure CLI:**
```bash
# Windows
winget install Microsoft.AzureCLI

# macOS
brew install azure-cli

# Or download from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
```

**kubectl:**
```bash
# Windows
winget install Kubernetes.kubectl

# macOS
brew install kubectl

# Or download from: https://kubernetes.io/docs/tasks/tools/
```

#### 2. Azure Authentication

```bash
# Login to Azure
az login

# List available subscriptions
az account list --output table

# Set active subscription (if you have multiple)
az account set --subscription "Your-Subscription-ID"

# Verify current subscription
az account show
```

### Project Setup

#### 3. Create Repository

```bash
# Create new repository on GitHub named: cst8918-w25-h09
# Clone the repository locally
git clone https://github.com/YOUR_USERNAME/cst8918-w25-h09.git
cd cst8918-w25-h09
```

#### 4. Create Project Files

Create the following files with content from the artifacts:

1. **main.tf** - AKS cluster configuration
2. **variables.tf** - Variable definitions
3. **outputs.tf** - Output values including kubeconfig
4. **versions.tf** - Provider requirements
5. **terraform.tfvars** - Variable values
6. **sample-app.yaml** - Kubernetes application manifests
7. **.gitignore** - Git ignore file
8. **README.md** - Project documentation
9. **deploy.sh** / **deploy.ps1** - Deployment scripts

### Deployment Process

#### 5. Deploy Infrastructure

**Option A: Using Terraform manually**

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan deployment
terraform plan

# Apply configuration
terraform apply
# Type 'yes' when prompted
```

**Option B: Using deployment script**

```bash
# Linux/macOS
chmod +x deploy.sh
./deploy.sh deploy

# Windows PowerShell
.\deploy.ps1 -Action deploy
```

#### 6. Connect to AKS Cluster

```bash
# Extract kubeconfig
terraform output -raw kube_config > ./kubeconfig

# Set KUBECONFIG environment variable
export KUBECONFIG=./kubeconfig

# Test connection
kubectl get nodes
```

**Expected output:**
```
NAME                                STATUS   ROLES   AGE   VERSION
aks-default-12345678-vmss000000    Ready    agent   5m    v1.28.3
aks-default-12345678-vmss000001    Ready    agent   5m    v1.28.3
```

#### 7. Deploy Sample Application

```bash
# Deploy the application
kubectl apply -f sample-app.yaml

# Verify deployment
kubectl get pods
kubectl get services

# Wait for pods to be ready
kubectl wait --for=condition=ready pod --all --timeout=300s
```

**Expected output:**
```
NAME                               READY   STATUS    RESTARTS   AGE
order-service-xxx                  1/1     Running   0          2m
product-service-xxx                1/1     Running   0          2m
rabbitmq-xxx                       1/1     Running   0          2m
store-front-xxx                    1/1     Running   0          2m
```

#### 8. Access the Application

```bash
# Get LoadBalancer external IP
kubectl get service store-front

# Wait for EXTERNAL-IP to be assigned
# Open browser to http://EXTERNAL-IP
```

### Verification Steps

#### 9. Test Application Components

```bash
# Check all pods are running
kubectl get pods

# Check services
kubectl get services

# Check deployments
kubectl get deployments

# View pod logs (if needed)
kubectl logs -f deployment/store-front
kubectl logs -f deployment/order-service
kubectl logs -f deployment/product-service
kubectl logs -f deployment/rabbitmq
```

#### 10. Test Application Functionality

1. **Frontend Access**: Open browser to LoadBalancer IP
2. **RabbitMQ Management**: Access http://EXTERNAL-IP:15672 (username/password)
3. **Application Flow**: Test placing orders through the web interface

### Documentation Requirements

#### 11. Capture Screenshots

Take screenshots of:

1. **Terraform apply output** showing successful AKS creation
2. **kubectl get nodes** showing cluster nodes
3. **kubectl get pods** showing all pods running
4. **kubectl get services** showing LoadBalancer with external IP
5. **Web browser** showing the store application
6. **Azure Portal** showing the AKS cluster
7. **RabbitMQ Management interface**

#### 12. Document Outputs

Save the following information:

```bash
# Save Terraform outputs
terraform output > terraform-outputs.txt

# Save cluster information
kubectl cluster-info > cluster-info.txt

# Save resource information
kubectl get all -o wide > kubernetes-resources.txt

# Save node information
kubectl describe nodes > nodes-info.txt
```

### Assignment Submission

#### 13. Prepare Repository

```bash
# Add all files
git add .

# Commit changes
git commit -m "Complete H09 assignment - AKS cluster with sample application"

# Push to GitHub
git push origin main
```

#### 14. Verify Repository Contents

Ensure your repository contains:

- ✅ All Terraform files (main.tf, variables.tf, outputs.tf, versions.tf)
- ✅ terraform.tfvars with configuration
- ✅ sample-app.yaml with Kubernetes manifests
- ✅ README.md with documentation
- ✅ .gitignore file
- ✅ Screenshots in docs/ folder
- ✅ Output files showing successful deployment

#### 15. Submit Assignment

1. **Repository URL**: Submit GitHub repository URL to Brightspace
2. **Repository Name**: Must be `cst8918-w25-h09`
3. **Include**: Brief description of deployment process and any challenges faced

### Cleanup (Important!)

#### 16. Clean Up Resources

```bash
# Delete Kubernetes application
kubectl delete -f sample-app.yaml

# Wait for cleanup
sleep 30

# Destroy infrastructure
terraform destroy
# Type 'yes' when prompted
```

**Or using script:**
```bash
# Linux/macOS
./deploy.sh cleanup

# Windows PowerShell
.\deploy.ps1 -Action cleanup
```

### Troubleshooting Common Issues

#### Issue 1: Terraform Provider Authentication
```bash
# Re-login to Azure
az login
az account set --subscription "Your-Subscription-ID"
```

#### Issue 2: Pods Stuck in Pending
```bash
# Check node resources
kubectl describe nodes

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp
```

#### Issue 3: LoadBalancer IP Not Assigned
```bash
# Check Azure Load Balancer provisioning
kubectl describe service store-front

# Verify Azure subscription limits
az vm list-usage --location "East US"
```

#### Issue 4: Application Not Accessible
```bash
# Check all services
kubectl get services -o wide

# Check pod status
kubectl get pods -o wide

# Check logs
kubectl logs -f deployment/store-front
```

### Assignment Grading Criteria

Your assignment will be evaluated on:

1. **Infrastructure (40%)**
   - ✅ AKS cluster created with correct specifications
   - ✅ Proper Terraform configuration
   - ✅ Working kubeconfig output

2. **Application Deployment (30%)**
   - ✅ Sample application deployed successfully
   - ✅ All components running (frontend, backends, message broker)
   - ✅ Application accessible via LoadBalancer

3. **Documentation (20%)**
   - ✅ Complete README with instructions
   - ✅ Screenshots showing working deployment
   - ✅ Proper Git repository structure

4. **Code Quality (10%)**
   - ✅ Clean, well-commented Terraform code
   - ✅ Proper variable usage
   - ✅ Following best practices

### Tips for Success

1. **Test Early**: Deploy and test your configuration early to identify issues
2. **Monitor Costs**: AKS clusters incur charges - clean up promptly
3. **Document Everything**: Take screenshots during deployment process
4. **Version Control**: Commit changes frequently with meaningful messages
5. **Resource Limits**: Be aware of Azure subscription limits for VM cores
6. **Network Patience**: LoadBalancer IP assignment can take 5-10 minutes

---

**Good luck with your assignment! 🚀**

Remember to clean up your resources to avoid unnecessary Azure charges.