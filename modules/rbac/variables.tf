# -----------------------------------------------------------------------------
# Variables: rbac
# -----------------------------------------------------------------------------

variable "scope" {
  description = "The scope at which the role assignment applies."
  type        = string
}

variable "role_definition_name" {
  description = "The name of the built-in role to assign."
  type        = string
}

variable "principal_id" {
  description = "The principal ID to assign the role to."
  type        = string
}
