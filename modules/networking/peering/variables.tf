# -----------------------------------------------------------------------------
# Variables: networking/peering
# -----------------------------------------------------------------------------

variable "source_vnet_name" {
  description = "Name of the source virtual network."
  type        = string
}

variable "source_vnet_id" {
  description = "ID of the source virtual network."
  type        = string
}

variable "source_rg" {
  description = "Resource group of the source virtual network."
  type        = string
}

variable "dest_vnet_name" {
  description = "Name of the destination virtual network."
  type        = string
}

variable "dest_vnet_id" {
  description = "ID of the destination virtual network."
  type        = string
}

variable "dest_rg" {
  description = "Resource group of the destination virtual network."
  type        = string
}

variable "allow_forwarded_traffic" {
  description = "Allow forwarded traffic between peered VNets."
  type        = bool
  default     = true
}

variable "allow_gateway_transit" {
  description = "Allow gateway transit on the source peering."
  type        = bool
  default     = false
}
