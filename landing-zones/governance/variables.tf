#--------------------------------------------------------------
# AKS Landing Zone - Governance Module Variables
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

variable "cluster_id" {
  description = "Resource ID of the AKS cluster for policy assignments"
  type        = string
}

variable "acr_id" {
  description = "Resource ID of the Azure Container Registry"
  type        = string
}
