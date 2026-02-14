# -----------------------------------------------------------------------------
# Variables: networking/private-dns-zone
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name of the private DNS zone (e.g., privatelink.azurecr.io)."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "vnet_ids" {
  description = "Map of VNet names to VNet IDs to link to the DNS zone."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to the DNS zone."
  type        = map(string)
  default     = {}
}
