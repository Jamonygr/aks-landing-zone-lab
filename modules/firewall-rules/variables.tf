# -----------------------------------------------------------------------------
# Variables: firewall-rules
# -----------------------------------------------------------------------------

variable "name" {
  description = "Base name for the rule collections."
  type        = string
}

variable "firewall_name" {
  description = "Name of the Azure Firewall."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "priority" {
  description = "Base priority for network rule collection (app rules = priority + 100)."
  type        = number
  default     = 200
}

variable "rules" {
  description = "Network and application rules for AKS egress."
  type = object({
    network_rules = list(object({
      name                  = string
      protocols             = list(string)
      source_addresses      = list(string)
      destination_addresses = list(string)
      destination_ports     = list(string)
    }))
    application_rules = list(object({
      name             = string
      source_addresses = list(string)
      protocols = list(object({
        type = string
        port = number
      }))
      target_fqdns = list(string)
    }))
  })
}
