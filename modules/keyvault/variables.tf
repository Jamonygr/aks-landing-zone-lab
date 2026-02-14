# -----------------------------------------------------------------------------
# Variables: keyvault
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name of the Key Vault (must be globally unique)."
  type        = string
}

variable "location" {
  description = "Azure region for the Key Vault."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID."
  type        = string
}

variable "sku_name" {
  description = "SKU name for the Key Vault."
  type        = string
  default     = "standard"
}

variable "principal_ids" {
  description = "List of principal IDs to grant Key Vault Secrets User role."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to t he Key Vault."
  type        = map(string)
  default     = {}
}
