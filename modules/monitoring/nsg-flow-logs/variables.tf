# -----------------------------------------------------------------------------
# Variables: monitoring/nsg-flow-logs
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name of the flow log resource."
  type        = string
}

variable "network_watcher_name" {
  description = "Name of the Network Watcher."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group containing the Network Watcher."
  type        = string
}

variable "nsg_id" {
  description = "ID of the Network Security Group to enable flow logs for."
  type        = string
}

variable "storage_account_id" {
  description = "ID of the storage account for flow log data."
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace for traffic analytics."
  type        = string
}

variable "retention_days" {
  description = "Number of days to retain flow log data."
  type        = number
  default     = 30
}
