#--------------------------------------------------------------
# AKS Landing Zone - Security Module Variables
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
  description = "Resource ID of the AKS cluster"
  type        = string
}

variable "cluster_identity_id" {
  description = "Principal ID of the AKS cluster managed identity (kubelet identity)"
  type        = string
}

variable "additional_key_vault_secrets_user_object_ids" {
  description = "Additional principal object IDs to grant Key Vault Secrets User access."
  type        = list(string)
  default     = []
}

variable "enable_defender" {
  description = "Toggle to enable Microsoft Defender for Containers"
  type        = bool
  default     = false
}
