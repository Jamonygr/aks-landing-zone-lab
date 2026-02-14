# -----------------------------------------------------------------------------
# Variables: networking/nsg
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name of the network security group."
  type        = string
}

variable "location" {
  description = "Azure region for the NSG."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "security_rules" {
  description = "List of security rule objects."
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  default = []
}

variable "subnet_id" {
  description = "ID of the subnet to associate the NSG with."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to the NSG."
  type        = map(string)
  default     = {}
}
