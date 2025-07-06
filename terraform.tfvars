# Terraform variables for AKS cluster deployment
# CST8918 - H09 Assignment

# Azure region for resources (using East US for better compatibility)
location = "East US"

# Environment designation
environment = "dev"

# Project name for resource naming
project_name = "aks-store"

# Kubernetes version (use latest stable version for Free tier)
kubernetes_version = "1.33.1"

# Node configuration as per assignment requirements
node_count     = 2           # Initial number of nodes
min_node_count = 1           # Minimum 1 node as required
max_node_count = 3           # Maximum 3 nodes as required

# VM size as specified in assignment
vm_size = "Standard_B2s"

# Enable auto-scaling
enable_auto_scaling = true

# Network configuration (simple)
network_plugin = "kubenet"