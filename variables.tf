# Variable definitions for AKS Terraform configuration

variable "location" {
  description = "The Azure region where the AKS cluster will be created"
  type        = string
  default     = "East US"
  
  validation {
    condition = contains([
      "East US", "East US 2", "West US", "West US 2", "West US 3",
      "Central US", "North Central US", "South Central US",
      "Canada Central", "Canada East",
      "West Europe", "North Europe", "UK South", "UK West",
      "Germany West Central", "Switzerland North",
      "France Central", "Norway East",
      "Japan East", "Japan West", "Korea Central", "Korea South",
      "Southeast Asia", "East Asia", "Australia East", "Australia Central"
    ], var.location)
    error_message = "Please select a valid Azure region."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = can(regex("^(dev|staging|prod)$", var.environment))
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "aks-store"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,20}$", var.project_name))
    error_message = "Project name must be 3-20 characters and contain only letters, numbers, and hyphens."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version for the AKS cluster"
  type        = string
  default     = "1.28.3"
  
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.kubernetes_version))
    error_message = "Kubernetes version must be in format x.y.z (e.g., 1.28.3)."
  }
}

variable "node_count" {
  description = "Initial number of nodes in the default node pool"
  type        = number
  default     = 2
  
  validation {
    condition     = var.node_count >= 1 && var.node_count <= 10
    error_message = "Node count must be between 1 and 10."
  }
}

variable "min_node_count" {
  description = "Minimum number of nodes in the default node pool when auto-scaling is enabled"
  type        = number
  default     = 1
  
  validation {
    condition     = var.min_node_count >= 1 && var.min_node_count <= 10
    error_message = "Minimum node count must be between 1 and 10."
  }
}

variable "max_node_count" {
  description = "Maximum number of nodes in the default node pool when auto-scaling is enabled"
  type        = number
  default     = 3
  
  validation {
    condition     = var.max_node_count >= 1 && var.max_node_count <= 100
    error_message = "Maximum node count must be between 1 and 100."
  }
}

variable "vm_size" {
  description = "Size of the Virtual Machine for AKS nodes"
  type        = string
  default     = "Standard_B2s"
  
  validation {
    condition = contains([
      "Standard_B2s", "Standard_B2ms", "Standard_B4ms",
      "Standard_D2s_v3", "Standard_D4s_v3", "Standard_D8s_v3",
      "Standard_DS2_v2", "Standard_DS3_v2", "Standard_DS4_v2",
      "Standard_E2s_v3", "Standard_E4s_v3", "Standard_E8s_v3"
    ], var.vm_size)
    error_message = "Please select a valid VM size."
  }
}

variable "enable_auto_scaling" {
  description = "Enable auto-scaling for the default node pool"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable Azure Monitor for the AKS cluster"
  type        = bool
  default     = true
}

variable "enable_azure_policy" {
  description = "Enable Azure Policy add-on for the AKS cluster"
  type        = bool
  default     = true
}

variable "network_plugin" {
  description = "Network plugin to use for networking (kubenet or azure)"
  type        = string
  default     = "kubenet"
  
  validation {
    condition     = contains(["kubenet", "azure"], var.network_plugin)
    error_message = "Network plugin must be either 'kubenet' or 'azure'."
  }
}

variable "log_analytics_retention_days" {
  description = "Number of days to retain logs in Log Analytics workspace"
  type        = number
  default     = 30
  
  validation {
    condition     = var.log_analytics_retention_days >= 30 && var.log_analytics_retention_days <= 730
    error_message = "Log retention must be between 30 and 730 days."
  }
}