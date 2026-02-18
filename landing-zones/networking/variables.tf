#--------------------------------------------------------------
# AKS Landing Zone - Networking Module Variables
#--------------------------------------------------------------

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "lab", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, lab, staging, prod."
  }
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

variable "hub_vnet_cidr" {
  description = "CIDR block for the hub virtual network"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.hub_vnet_cidr, 0))
    error_message = "hub_vnet_cidr must be a valid CIDR block."
  }
}

variable "spoke_aks_vnet_cidr" {
  description = "CIDR block for the AKS spoke virtual network"
  type        = string
  default     = "10.1.0.0/16"

  validation {
    condition     = can(cidrhost(var.spoke_aks_vnet_cidr, 0))
    error_message = "spoke_aks_vnet_cidr must be a valid CIDR block."
  }
}

variable "enable_firewall" {
  description = "Toggle to deploy Azure Firewall Basic SKU in the hub network"
  type        = bool
  default     = false
}

variable "route_internet_via_firewall" {
  description = "If true and firewall is enabled, route AKS subnet 0.0.0.0/0 through firewall."
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for diagnostic settings (empty string to skip)"
  type        = string
  default     = ""
}
