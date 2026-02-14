# -----------------------------------------------------------------------------
# Variables: policy
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name of the policy assignment."
  type        = string
}

variable "scope" {
  description = "Resource ID to assign the policy to."
  type        = string
}

variable "policy_definition_id" {
  description = "ID of the policy definition or initiative to assign."
  type        = string
}

variable "parameters" {
  description = "JSON-encoded parameters for the policy assignment."
  type        = string
  default     = null
}
