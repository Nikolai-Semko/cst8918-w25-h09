# Terraform variables for AKS cluster deployment
# CST8918 - H09 Assignment

# Azure region for resources
location = "East US"

# Environment designation
environment = "dev"

# Project name for resource naming
project_name = "aks-store"

# Kubernetes version (use latest stable)
kubernetes_version = "1.28.3"

# Node configuration as per assignment requirements
node_count     = 2           # Initial number of nodes
min_node_count = 1           # Minimum 1 node as required
max_node_count = 3           # Maximum 3 nodes as required

# VM size as specified in assignment
vm_size = "Standard_B2s"

# Enable auto-scaling
enable_auto_scaling = true

# Monitoring and policy
enable_monitoring    = true
enable_azure_policy  = true

# Network configuration
network_plugin = "kubenet"

# Log Analytics retention
log_analytics_retention_days = 30