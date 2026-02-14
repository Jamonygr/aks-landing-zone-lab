# -----------------------------------------------------------------------------
# Variables: storage
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name of the storage account (must be globally unique, lowercase alphanumeric)."
  type        = string
}

variable "location" {
  description = "Azure region for the storage account."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "account_tier" {
  description = "Performance tier of the storage account."
  type        = string
  default     = "Standard"
}

variable "replication_type" {
  description = "Replication type for the storage account."
  type        = string
  default     = "LRS"
}

variable "tags" {
  description = "Tags to apply to the storage account."
  type        = map(string)
  default     = {}
}
