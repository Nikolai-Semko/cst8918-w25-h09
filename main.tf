# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Create a random string for unique naming
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Create a resource group for the AKS cluster
resource "azurerm_resource_group" "aks" {
  name     = "rg-aks-${var.project_name}-${var.environment}-${random_string.suffix.result}"
  location = var.location

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "AKS Cluster"
    CreatedBy   = "Terraform"
    Assignment  = "CST8918-H09"
  }
}

# Create Azure Kubernetes Service (AKS) cluster
resource "azurerm_kubernetes_cluster" "app" {
  name                = "aks-${var.project_name}-${var.environment}-${random_string.suffix.result}"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = "aks-${var.project_name}-${random_string.suffix.result}"
  
  # Use the latest Kubernetes version
  kubernetes_version = var.kubernetes_version

  # Default node pool configuration
  default_node_pool {
    name                = "default"
    node_count          = var.node_count
    min_count           = var.min_node_count
    max_count           = var.max_node_count
    vm_size             = var.vm_size
    type                = "VirtualMachineScaleSets"
    enable_auto_scaling = true
    
    # Use availability zones for high availability
    zones = ["1", "2", "3"]
    
    # Node labels
    node_labels = {
      "nodepool-type" = "system"
      "environment"   = var.environment
      "nodepoolos"    = "linux"
    }
    
    # Node taints for system workloads
    tags = {
      "nodepool-type" = "system"
      "environment"   = var.environment
      "nodepoolos"    = "linux"
    }
  }

  # Use SystemAssigned managed identity
  identity {
    type = "SystemAssigned"
  }

  # Network configuration - using kubenet (simpler, no custom networking)
  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
  }

  # Enable RBAC
  role_based_access_control_enabled = true

  # Add-ons
  # HTTP application routing (not recommended for production)
  http_application_routing_enabled = false
  
  # Enable Azure Policy add-on
  azure_policy_enabled = var.enable_azure_policy
  
  # Enable monitoring (optional)
  dynamic "oms_agent" {
    for_each = var.enable_monitoring ? [1] : []
    content {
      log_analytics_workspace_id = azurerm_log_analytics_workspace.aks[0].id
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "AKS Cluster"
    CreatedBy   = "Terraform"
    Assignment  = "CST8918-H09"
  }
}

# Create Log Analytics Workspace for AKS monitoring (optional)
resource "azurerm_log_analytics_workspace" "aks" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "law-aks-${var.project_name}-${var.environment}-${random_string.suffix.result}"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_analytics_retention_days

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "AKS Monitoring"
    CreatedBy   = "Terraform"
    Assignment  = "CST8918-H09"
  }
}