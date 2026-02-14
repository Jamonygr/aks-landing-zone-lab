# -----------------------------------------------------------------------------
# Variables: networking/subnet
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name of the subnet."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "virtual_network_name" {
  description = "Name of the parent virtual network."
  type        = string
}

variable "address_prefixes" {
  description = "Address prefixes for the subnet."
  type        = list(string)
}

variable "service_endpoints" {
  description = "List of service endpoints to associate with the subnet."
  type        = list(string)
  default     = []
}

variable "delegation" {
  description = "Optional subnet delegation configuration."
  type = object({
    name                    = string
    service_delegation_name = string
    actions                 = list(string)
  })
  default = null
}
