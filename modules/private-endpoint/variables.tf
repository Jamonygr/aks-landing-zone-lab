# -----------------------------------------------------------------------------
# Variables: private-endpoint
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name of the private endpoint."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the private endpoint will be created."
  type        = string
}

variable "private_connection_resource_id" {
  description = "Resource ID of the service to connect to via private endpoint."
  type        = string
}

variable "subresource_names" {
  description = "List of subresource names for the private endpoint (e.g., sqlServer, Sql)."
  type        = list(string)
}

variable "private_dns_zone_id" {
  description = "ID of the private DNS zone to associate with the endpoint. Empty string to skip."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply."
  type        = map(string)
  default     = {}
}
