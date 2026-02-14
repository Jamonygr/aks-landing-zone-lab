# -----------------------------------------------------------------------------
# Variables: networking/route-table
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name of the route table."
  type        = string
}

variable "location" {
  description = "Azure region for the route table."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "routes" {
  description = "List of route objects."
  type = list(object({
    name                   = string
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = optional(string)
  }))
  default = []
}

variable "subnet_id" {
  description = "ID of the subnet to associate the route table with."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to the route table."
  type        = map(string)
  default     = {}
}
