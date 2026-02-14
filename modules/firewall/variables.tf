# -----------------------------------------------------------------------------
# Variables: firewall
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name of the Azure Firewall."
  type        = string
}

variable "location" {
  description = "Azure region for the firewall."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "subnet_id" {
  description = "ID of the AzureFirewallSubnet."
  type        = string
}

variable "sku_tier" {
  description = "SKU tier for the firewall (Basic, Standard, Premium)."
  type        = string
  default     = "Basic"
}

variable "tags" {
  description = "Tags to apply to firewall resources."
  type        = map(string)
  default     = {}
}
