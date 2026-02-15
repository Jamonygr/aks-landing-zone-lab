#--------------------------------------------------------------
# AKS Landing Zone - AKS Platform Module Variables
#--------------------------------------------------------------

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for resource deployment"
  type        = string
  default     = "eastus2"
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    project    = "aks-landing-zone"
    managed_by = "terraform"
  }
}

variable "resource_group_name" {
  description = "Name of the resource group for AKS resources"
  type        = string
}

variable "aks_system_subnet_id" {
  description = "Subnet ID for the AKS system node pool"
  type        = string
}

variable "aks_user_subnet_id" {
  description = "Subnet ID for the AKS user node pool"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for monitoring and diagnostics"
  type        = string
}

variable "acr_name" {
  description = "Name of the Azure Container Registry (must be globally unique, alphanumeric)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{5,50}$", var.acr_name))
    error_message = "ACR name must be 5-50 lowercase alphanumeric characters."
  }
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "aks-landing-zone-dev"
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
  default     = "akslz"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the AKS cluster"
  type        = string
  default     = null
}

variable "system_node_vm_size" {
  description = "VM size for the system node pool"
  type        = string
  default     = "Standard_B2s"
}

variable "system_node_min_count" {
  description = "Minimum number of nodes in the system pool"
  type        = number
  default     = 1
}

variable "system_node_max_count" {
  description = "Maximum number of nodes in the system pool"
  type        = number
  default     = 2
}

variable "user_node_vm_size" {
  description = "VM size for the user node pool"
  type        = string
  default     = "Standard_B2s"
}

variable "user_node_min_count" {
  description = "Minimum number of nodes in the user pool"
  type        = number
  default     = 1
}

variable "user_node_max_count" {
  description = "Maximum number of nodes in the user pool"
  type        = number
  default     = 3
}

variable "enable_dns_zone" {
  description = "Toggle to create an Azure DNS zone and A records for ingress"
  type        = bool
  default     = false
}

variable "dns_zone_name" {
  description = "DNS zone name (required if enable_dns_zone is true)"
  type        = string
  default     = "aks.example.com"
}
