# CST8918 - H09: Azure Kubernetes Service (AKS) Cluster with Terraform

This project creates an Azure Kubernetes Service (AKS) cluster using Terraform and deploys a multi-tier sample application.

## 🏗️ Architecture

The solution includes:

- **AKS Cluster**: Azure Kubernetes Service with auto-scaling (1-3 nodes)
- **Sample Application**: Multi-tier web application with:
  - **Frontend**: Vue.js store front
  - **Backend Services**: Node.js order service and Rust product service  
  - **Message Broker**: RabbitMQ for async messaging
  - **Monitoring**: Azure Monitor and Log Analytics

## 📋 Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.0
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- Azure subscription with appropriate permissions

## 🚀 Quick Start

### Step 1: Azure Authentication

```bash
# Login to Azure
az login

# Set your subscription (if you have multiple)
az account set --subscription "Your-Subscription-ID"

# Verify your account
az account show
```

### Step 2: Deploy Infrastructure

```bash
# Clone the repository
git clone <your-repo-url>
cd cst8918-w25-h09

# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Deploy the infrastructure
terraform apply
```

### Step 3: Connect to AKS Cluster

```bash
# Save the kubeconfig file
terraform output -raw kube_config > ./kubeconfig

# Set KUBECONFIG environment variable
export KUBECONFIG=./kubeconfig

# Verify connection to cluster
kubectl get nodes
```

**Alternative method using Azure CLI:**
```bash
# Get AKS credentials using Azure CLI
az aks get-credentials --resource-group $(terraform output -raw resource_group_name) --name $(terraform output -raw aks_cluster_name)

# Test connection
kubectl get nodes
```

### Step 4: Deploy Sample Application

```bash
# Deploy the sample application
kubectl apply -f sample-app.yaml

# Verify deployment
kubectl get pods
kubectl get services

# Wait for pods to be ready
kubectl wait --for=condition=ready pod --all --timeout=300s
```

### Step 5: Access the Application

```bash
# Get the external IP address of the LoadBalancer
kubectl get service store-front

# Wait for EXTERNAL-IP to be assigned (may take a few minutes)
# Open the application in your browser using the external IP
```

## 📊 Infrastructure Details

### AKS Cluster Configuration

| Setting | Value |
|---------|-------|
| **Kubernetes Version** | Latest stable (1.28.3) |
| **VM Size** | Standard_B2s |
| **Node Count** | 2 (initial) |
| **Min Nodes** | 1 |
| **Max Nodes** | 3 |
| **Auto-scaling** | Enabled |
| **Identity** | SystemAssigned |
| **Network Plugin** | kubenet |

### Application Components

| Component | Description | Port | Image |
|-----------|-------------|------|-------|
| **store-front** | Vue.js frontend | 8080 | Azure Samples |
| **order-service** | Node.js backend | 3000 | Azure Samples |
| **product-service** | Rust backend | 3002 | Azure Samples |
| **rabbitmq** | Message broker | 5672/15672 | RabbitMQ 3.10 |

## 🔧 Management Commands

### Kubernetes Commands

```bash
# View all resources
kubectl get all

# View pods with details
kubectl get pods -o wide

# View services
kubectl get services

# View deployments
kubectl get deployments

# Check pod logs
kubectl logs -f deployment/store-front

# Scale a deployment
kubectl scale deployment store-front --replicas=3

# View resource usage
kubectl top nodes
kubectl top pods
```

### Terraform Commands

```bash
# View current state
terraform show

# View outputs
terraform output

# Update infrastructure
terraform plan
terraform apply

# Destroy infrastructure
terraform destroy
```

## 🔍 Troubleshooting

### Common Issues

#### 1. Pods stuck in Pending state
```bash
# Check node resources
kubectl describe nodes

# Check pod events
kubectl describe pod <pod-name>
```

#### 2. Application not accessible
```bash
# Check service status
kubectl get services

# Check if LoadBalancer is provisioned
kubectl describe service store-front

# Check pod status
kubectl get pods -l app=store-front
```

#### 3. RabbitMQ connection issues
```bash
# Check RabbitMQ logs
kubectl logs -f deployment/rabbitmq

# Test connectivity
kubectl exec -it deployment/order-service -- nc -zv rabbitmq 5672
```

### Health Checks

```bash
# Check cluster health
kubectl get componentstatuses

# Check node status
kubectl get nodes

# Check system pods
kubectl get pods -n kube-system

# View cluster events
kubectl get events --sort-by=.metadata.creationTimestamp
```

## 📈 Monitoring

### Azure Monitor

The AKS cluster is configured with Azure Monitor for containers:

```bash
# View metrics in Azure portal
# Navigate to: AKS cluster → Monitoring → Insights
```

### Kubernetes Dashboard (Optional)

```bash
# Deploy Kubernetes dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# Create admin user and get token
kubectl create serviceaccount dashboard-admin-sa
kubectl create clusterrolebinding dashboard-admin-sa --clusterrole=cluster-admin --serviceaccount=default:dashboard-admin-sa
kubectl describe secret $(kubectl get secret | grep dashboard-admin-sa | awk '{print $1}')

# Start proxy
kubectl proxy

# Access dashboard at:
# http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

## 🧹 Cleanup

### Remove Application

```bash
# Delete the sample application
kubectl delete -f sample-app.yaml

# Verify removal
kubectl get all
```

### Destroy Infrastructure

```bash
# Destroy all Terraform-managed resources
terraform destroy

# Confirm with 'yes' when prompted
```

**Note**: This will delete the entire resource group and all contained resources.

## 📚 Additional Resources

- [Azure Kubernetes Service Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

## 🏷️ Assignment Submission

**Repository Name**: `cst8918-w25-h09`

**Required Deliverables**:
- ✅ Terraform configuration files
- ✅ AKS cluster with specified configuration  
- ✅ Sample application deployment
- ✅ Documentation and screenshots
- ✅ Working kubeconfig output

**Submission**: Submit the GitHub repository URL to Brightspace.

## 📸 Screenshots for Documentation

Capture screenshots of:

1. **Terraform apply** output showing successful AKS creation
2. **kubectl get nodes** showing cluster nodes
3. **kubectl get pods** showing running application pods
4. **kubectl get services** showing LoadBalancer external IP
5. **Web browser** showing the running application
6. **Azure Portal** showing the created AKS cluster and resources

## ⚠️ Important Notes

- **Costs**: AKS clusters incur Azure charges. Remember to clean up resources when done.
- **Security**: This is a development setup. Production deployments require additional security configurations.
- **Scaling**: The cluster is configured for auto-scaling between 1-3 nodes as per assignment requirements.
- **Monitoring**: Azure Monitor is enabled for cluster observability.

---

**CST8918 - DevOps: Infrastructure as Code**  
**Professor**: Robert McKenney  
**Assignment**: H09 - Azure Kubernetes Service with Terraform