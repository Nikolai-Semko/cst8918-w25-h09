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

  # Network configuration
  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
  }

  # Enable RBAC
  role_based_access_control_enabled = true

  # Azure AD integration (optional but recommended)
  azure_active_directory_role_based_access_control {
    managed            = true
    azure_rbac_enabled = true
  }

  # Add-ons
  # HTTP application routing (not recommended for production)
  http_application_routing_enabled = false
  
  # Enable Azure Policy add-on
  azure_policy_enabled = true
  
  # Enable monitoring
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.aks.id
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "AKS Cluster"
    CreatedBy   = "Terraform"
    Assignment  = "CST8918-H09"
  }

  depends_on = [
    azurerm_role_assignment.aks_network_contributor
  ]
}

# Create Log Analytics Workspace for AKS monitoring
resource "azurerm_log_analytics_workspace" "aks" {
  name                = "law-aks-${var.project_name}-${var.environment}-${random_string.suffix.result}"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "AKS Monitoring"
    CreatedBy   = "Terraform"
    Assignment  = "CST8918-H09"
  }
}

# Create a virtual network for AKS (optional, but good practice)
resource "azurerm_virtual_network" "aks" {
  name                = "vnet-aks-${var.project_name}-${var.environment}-${random_string.suffix.result}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "AKS Network"
    CreatedBy   = "Terraform"
    Assignment  = "CST8918-H09"
  }
}

# Create a subnet for AKS nodes
resource "azurerm_subnet" "aks" {
  name                 = "subnet-aks-nodes"
  resource_group_name  = azurerm_resource_group.aks.name
  virtual_network_name = azurerm_virtual_network.aks.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Assign Network Contributor role to AKS identity
resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = azurerm_virtual_network.aks.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.app.identity[0].principal_id
}