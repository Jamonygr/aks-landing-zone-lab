# -----------------------------------------------------------------------------
# Variables: sql-database
# -----------------------------------------------------------------------------

variable "server_name" {
  description = "Name of the Azure SQL Server."
  type        = string
}

variable "database_name" {
  description = "Name of the SQL Database."
  type        = string
  default     = "learninghub"
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "location" {
  description = "Azure region for the SQL Server resource."
  type        = string
}

variable "private_endpoint_location" {
  description = "Azure region for the private endpoint (must match VNet region). Defaults to location."
  type        = string
  default     = ""
}

variable "admin_username" {
  description = "SQL admin username."
  type        = string
  default     = "sqladmin"
}

variable "aad_admin_login" {
  description = "Azure AD admin login name for the SQL Server."
  type        = string
}

variable "aad_admin_object_id" {
  description = "Azure AD admin object ID."
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID."
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the private endpoint."
  type        = string
}

variable "vnet_ids" {
  description = "Map of VNet names to IDs for private DNS zone links."
  type        = map(string)
  default     = {}
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for diagnostics. Empty string to skip."
  type        = string
  default     = ""
}

variable "enable_diagnostics" {
  description = "Whether to enable diagnostic settings. Use this instead of checking workspace ID at plan time."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply."
  type        = map(string)
  default     = {}
}
