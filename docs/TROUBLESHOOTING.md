# Troubleshooting Guide - CST8918 H09

## 🔧 Common Issues and Solutions

### Azure Authentication Issues

#### Problem: "az login" fails or "No subscriptions found"
```bash
# Solution 1: Clear Azure CLI cache
az account clear
az login

# Solution 2: Login with specific tenant
az login --tenant YOUR_TENANT_ID

# Solution 3: Use device code login
az login --use-device-code
```

#### Problem: Insufficient permissions for AKS creation
```bash
# Check your role assignments
az role assignment list --assignee $(az ad signed-in-user show --query objectId -o tsv)

# Required roles:
# - Contributor (or AKS Cluster Admin)
# - User Access Administrator (for managed identity)
```

### Terraform Issues

#### Problem: "Provider registration failed"
```bash
# Register required resource providers
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.Compute
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.Storage

# Check registration status
az provider show --namespace Microsoft.ContainerService --query "registrationState"
```

#### Problem: "Terraform state lock"
```bash
# Force unlock (use with caution)
terraform force-unlock LOCK_ID

# Or delete state file and re-import (advanced)
rm terraform.tfstate*
terraform import azurerm_resource_group.aks /subscriptions/SUB_ID/resourceGroups/RG_NAME
```

#### Problem: "Invalid Kubernetes version"
```bash
# List available versions for your region
az aks get-versions --location "East US" --output table

# Update terraform.tfvars with available version
kubernetes_version = "1.28.3"  # Use actual available version
```

### AKS Cluster Issues

#### Problem: Cluster creation fails with quota exceeded
```bash
# Check VM quota in your region
az vm list-usage --location "East US" --output table

# Request quota increase if needed
# Azure Portal → Subscriptions → Usage + quotas → Request increase
```

#### Problem: Nodes stuck in "NotReady" state
```bash
# Check node status
kubectl describe nodes

# Check system pods
kubectl get pods -n kube-system

# Common solutions:
# 1. Wait 5-10 minutes for initialization
# 2. Check Azure networking configuration
# 3. Verify VM sizes are available in the region
```

#### Problem: Can't connect to cluster after creation
```bash
# Method 1: Use Terraform output
terraform output -raw kube_config > ./kubeconfig
export KUBECONFIG=./kubeconfig

# Method 2: Use Azure CLI
az aks get-credentials --resource-group $(terraform output -raw resource_group_name) --name $(terraform output -raw aks_cluster_name) --overwrite-existing

# Method 3: Verify cluster is running
az aks show --resource-group RG_NAME --name CLUSTER_NAME --query "powerState.code"
```

### Kubernetes Application Issues

#### Problem: Pods stuck in "Pending" state
```bash
# Check events
kubectl describe pod POD_NAME

# Check node resources
kubectl top nodes
kubectl describe nodes

# Common causes:
# 1. Insufficient resources (CPU/Memory)
# 2. Node selector conflicts
# 3. Persistent volume issues
# 4. Image pull failures

# Solutions:
# Scale cluster nodes
kubectl scale --replicas=0 deployment/DEPLOYMENT_NAME
kubectl scale --replicas=1 deployment/DEPLOYMENT_NAME
```

#### Problem: Pods in "CrashLoopBackOff" state
```bash
# Check pod logs
kubectl logs POD_NAME
kubectl logs POD_NAME --previous

# Check pod events
kubectl describe pod POD_NAME

# Common causes:
# 1. Application configuration errors
# 2. Missing dependencies
# 3. Resource limits too low
# 4. Health check failures
```

#### Problem: LoadBalancer external IP remains "Pending"
```bash
# Check service status
kubectl describe service store-front

# Check Azure Load Balancer provisioning
az network lb list --resource-group MC_*

# Common causes:
# 1. Azure networking issues
# 2. Subscription limits
# 3. Regional capacity issues

# Solutions:
# Wait 10-15 minutes
# Check Azure portal for load balancer status
# Try different region if persistent
```

#### Problem: Application not accessible via LoadBalancer IP
```bash
# Verify external IP is assigned
kubectl get service store-front

# Test connectivity to pods directly
kubectl port-forward deployment/store-front 8080:8080
# Access http://localhost:8080

# Check pod readiness
kubectl get pods -l app=store-front

# Check application logs
kubectl logs -f deployment/store-front
```

### Network Connectivity Issues

#### Problem: Services can't communicate internally
```bash
# Test DNS resolution
kubectl run test-pod --image=busybox --rm -it -- nslookup rabbitmq

# Test port connectivity
kubectl run test-pod --image=busybox --rm -it -- nc -zv rabbitmq 5672

# Check service endpoints
kubectl get endpoints

# Verify service selectors match pod labels
kubectl get pods --show-labels
kubectl describe service SERVICE_NAME
```

#### Problem: RabbitMQ connection failures
```bash
# Check RabbitMQ logs
kubectl logs -f deployment/rabbitmq

# Verify RabbitMQ is ready
kubectl exec -it deployment/rabbitmq -- rabbitmq-diagnostics status

# Test connection from order service
kubectl exec -it deployment/order-service -- nc -zv rabbitmq 5672

# Check environment variables
kubectl describe pod $(kubectl get pods -l app=order-service -o jsonpath='{.items[0].metadata.name}')
```

### Performance Issues

#### Problem: Application runs slowly
```bash
# Check resource usage
kubectl top pods
kubectl top nodes

# Check resource limits
kubectl describe pod POD_NAME | grep -A 5 "Limits\|Requests"

# Scale horizontally
kubectl scale deployment store-front --replicas=3

# Scale cluster vertically (add nodes)
az aks scale --resource-group RG_NAME --name CLUSTER_NAME --node-count 3
```

#### Problem: Out of memory errors
```bash
# Check memory usage
kubectl top pods

# Increase memory limits in sample-app.yaml
# memory: "512Mi" → memory: "1Gi"

# Redeploy application
kubectl apply -f sample-app.yaml
```

### Image and Registry Issues

#### Problem: "ImagePullBackOff" errors
```bash
# Check image pull status
kubectl describe pod POD_NAME

# Common causes:
# 1. Image doesn't exist
# 2. Registry authentication issues
# 3. Network connectivity to registry

# Solutions:
# Verify image names in sample-app.yaml
# Check public registry accessibility
# Wait and retry (temporary network issues)
```

### Monitoring and Debugging Commands

#### Essential Debugging Commands
```bash
# Cluster health overview
kubectl get all
kubectl get events --sort-by=.metadata.creationTimestamp

# Node information
kubectl get nodes -o wide
kubectl describe nodes

# Pod debugging
kubectl get pods -o wide
kubectl describe pod POD_NAME
kubectl logs POD_NAME --tail=50
kubectl logs POD_NAME --previous

# Service debugging
kubectl get services -o wide
kubectl describe service SERVICE_NAME
kubectl get endpoints

# Resource usage
kubectl top nodes
kubectl top pods

# Network debugging
kubectl exec -it POD_NAME -- /bin/sh
kubectl port-forward service/SERVICE_NAME LOCAL_PORT:SERVICE_PORT
```

#### Azure-specific debugging
```bash
# Check AKS cluster status
az aks show --resource-group RG_NAME --name CLUSTER_NAME

# Check node resource group
az resource list --resource-group MC_*

# Check load balancer
az network lb list --resource-group MC_*

# Check network security groups
az network nsg list --resource-group MC_*
```

### Recovery Procedures

#### Recover from corrupted kubeconfig
```bash
# Re-generate kubeconfig
az aks get-credentials --resource-group RG_NAME --name CLUSTER_NAME --overwrite-existing

# Or use Terraform output
terraform output -raw kube_config > ./kubeconfig
export KUBECONFIG=./kubeconfig
```

#### Restart failed deployments
```bash
# Restart all pods in deployment
kubectl rollout restart deployment/DEPLOYMENT_NAME

# Delete and recreate pods
kubectl delete pod POD_NAME

# Redeploy application
kubectl delete -f sample-app.yaml
kubectl apply -f sample-app.yaml
```

#### Reset cluster state
```bash
# Delete all applications
kubectl delete -f sample-app.yaml

# Scale cluster to 0 and back (nuclear option)
az aks scale --resource-group RG_NAME --name CLUSTER_NAME --node-count 0
az aks scale --resource-group RG_NAME --name CLUSTER_NAME --node-count 2
```

### Resource Cleanup Issues

#### Problem: Terraform destroy hangs or fails
```bash
# Manual cleanup steps:
# 1. Delete Kubernetes resources first
kubectl delete -f sample-app.yaml

# 2. Delete additional resources manually
kubectl delete all --all

# 3. Force destroy with Terraform
terraform destroy -auto-approve

# 4. Manual Azure cleanup if needed
az group delete --name RG_NAME --yes --no-wait
```

#### Problem: Resources remain after terraform destroy
```bash
# Check for remaining resources
az resource list --resource-group RG_NAME

# Delete resource group manually
az group delete --name RG_NAME --yes

# Clean up Terraform state
rm terraform.tfstate*
rm -rf .terraform/
```

### Best Practices for Troubleshooting

1. **Start Simple**: Test basic connectivity before complex scenarios
2. **Check Logs**: Always examine pod and service logs first
3. **Use kubectl describe**: Provides detailed status and events
4. **Monitor Resources**: Check CPU/memory usage regularly
5. **Network Testing**: Use busybox pods for network debugging
6. **Gradual Scaling**: Scale one component at a time
7. **Clean State**: Sometimes deleting and recreating fixes issues
8. **Documentation**: Keep track of what works and what doesn't

### Getting Help

- **Azure Documentation**: https://docs.microsoft.com/en-us/azure/aks/
- **Kubernetes Documentation**: https://kubernetes.io/docs/
- **Terraform Azure Provider**: https://registry.terraform.io/providers/hashicorp/azurerm/
- **Azure Support**: Use Azure Portal → Support + troubleshooting
- **Community Forums**: Stack Overflow, Reddit r/kubernetes, r/AZURE

Remember: Most issues are temporary and can be resolved with patience and systematic debugging! 🔧