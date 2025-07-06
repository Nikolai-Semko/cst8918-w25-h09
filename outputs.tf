# Output values for the AKS Terraform configuration

# Kubeconfig file content (as required by the assignment)
output "kube_config" {
  description = "Raw kubeconfig file for connecting to the AKS cluster"
  value       = azurerm_kubernetes_cluster.app.kube_config_raw
  sensitive   = true
}

# AKS cluster information
output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.app.name
}

output "aks_cluster_id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.app.id
}

output "aks_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.app.fqdn
}

output "aks_node_resource_group" {
  description = "Auto-generated resource group which contains the resources for this managed Kubernetes cluster"
  value       = azurerm_kubernetes_cluster.app.node_resource_group
}

# Resource group information
output "resource_group_name" {
  description = "Name of the resource group containing the AKS cluster"
  value       = azurerm_resource_group.aks.name
}

output "resource_group_location" {
  description = "Location of the resource group containing the AKS cluster"
  value       = azurerm_resource_group.aks.location
}

# Kubernetes version
output "kubernetes_version" {
  description = "Version of Kubernetes used by the AKS cluster"
  value       = azurerm_kubernetes_cluster.app.kubernetes_version
}

# Identity information
output "aks_identity_principal_id" {
  description = "Principal ID of the system assigned identity of the AKS cluster"
  value       = azurerm_kubernetes_cluster.app.identity[0].principal_id
}

output "aks_identity_tenant_id" {
  description = "Tenant ID of the system assigned identity of the AKS cluster"
  value       = azurerm_kubernetes_cluster.app.identity[0].tenant_id
}

# Instructions for connecting to the cluster
output "kubectl_connection_command" {
  description = "Command to save kubeconfig and connect to the cluster"
  value = <<-EOF
    # Save the kubeconfig file
    terraform output -raw kube_config > ./kubeconfig
    
    # Set the KUBECONFIG environment variable
    export KUBECONFIG=./kubeconfig
    
    # Test the connection
    kubectl get nodes
    
    # Deploy the sample application
    kubectl apply -f sample-app.yaml
    
    # Check the deployment
    kubectl get pods
    kubectl get services
  EOF
}

# Azure CLI commands for alternative cluster access
output "azure_cli_commands" {
  description = "Alternative Azure CLI commands to access the cluster"
  value = <<-EOF
    # Get credentials using Azure CLI
    az aks get-credentials --resource-group ${azurerm_resource_group.aks.name} --name ${azurerm_kubernetes_cluster.app.name}
    
    # Test the connection
    kubectl get nodes
  EOF
}