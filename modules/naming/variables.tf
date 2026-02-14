# -----------------------------------------------------------------------------
# Variables: naming
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Name of the project (used as naming prefix)."
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)."
  type        = string
}

variable "location" {
  description = "Azure region short name (e.g., eastus, westus2)."
  type        = string
}
