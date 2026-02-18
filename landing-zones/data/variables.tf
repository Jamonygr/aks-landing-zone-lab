#--------------------------------------------------------------
# AKS Landing Zone - Data Module Variables
#--------------------------------------------------------------

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for resource deployment (VNet/PE region)"
  type        = string
  default     = "eastus"
}

variable "data_location" {
  description = "Azure region for database resources (SQL). Uses a different region if the primary has capacity issues."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    project    = "aks-landing-zone"
    managed_by = "terraform"
  }
}

variable "enable_sql_database" {
  description = "Toggle to deploy Azure SQL Database - adds ~$5/mo (Basic 5 DTU)"
  type        = bool
  default     = false
}

variable "private_endpoints_subnet_id" {
  description = "Subnet ID for private endpoints"
  type        = string
}

variable "hub_vnet_id" {
  description = "Resource ID of the hub VNet for private DNS zone links"
  type        = string
}

variable "spoke_vnet_id" {
  description = "Resource ID of the spoke VNet for private DNS zone links"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for diagnostics"
  type        = string
  default     = ""
}

variable "enable_diagnostics" {
  description = "Enable diagnostic settings for databases (must be known at plan time)"
  type        = bool
  default     = true
}

variable "key_vault_id" {
  description = "Resource ID of the Key Vault for storing connection strings"
  type        = string
}

variable "workload_identity_principal_id" {
  description = "Principal ID of the workload identity for DB role assignments"
  type        = string
}

variable "aad_admin_login" {
  description = "Azure AD admin login name for SQL Server"
  type        = string
  default     = "AKS Lab Admin"
}
