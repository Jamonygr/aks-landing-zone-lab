# -----------------------------------------------------------------------------
# Variables: acr
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name of the container registry (must be globally unique, alphanumeric)."
  type        = string
}

variable "location" {
  description = "Azure region for the container registry."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "sku" {
  description = "SKU tier for the container registry."
  type        = string
  default     = "Basic"
}

variable "principal_id" {
  description = "Principal ID to assign AcrPull role (e.g., AKS kubelet identity)."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to the container registry."
  type        = map(string)
  default     = {}
}
