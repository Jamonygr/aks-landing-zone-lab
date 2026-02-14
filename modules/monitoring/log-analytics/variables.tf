# -----------------------------------------------------------------------------
# Variables: monitoring/log-analytics
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name of the Log Analytics workspace."
  type        = string
}

variable "location" {
  description = "Azure region for the workspace."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "retention_in_days" {
  description = "Number of days to retain data."
  type        = number
  default     = 30
}

variable "sku" {
  description = "SKU of the Log Analytics workspace."
  type        = string
  default     = "PerGB2018"
}

variable "tags" {
  description = "Tags to apply to the workspace."
  type        = map(string)
  default     = {}
}
