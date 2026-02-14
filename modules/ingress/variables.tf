# -----------------------------------------------------------------------------
# Variables: ingress
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name for the ingress resources."
  type        = string
}

variable "location" {
  description = "Azure region for the public IP."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "tags" {
  description = "Tags to apply to the public IP."
  type        = map(string)
  default     = {}
}
