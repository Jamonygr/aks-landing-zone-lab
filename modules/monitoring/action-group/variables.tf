# -----------------------------------------------------------------------------
# Variables: monitoring/action-group
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name of the action group."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "short_name" {
  description = "Short name for the action group (max 12 chars)."
  type        = string
}

variable "email_address" {
  description = "Email address for the email receiver."
  type        = string
}

variable "tags" {
  description = "Tags to apply to the action group."
  type        = map(string)
  default     = {}
}
