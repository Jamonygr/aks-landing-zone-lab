# -----------------------------------------------------------------------------
# Variables: monitoring/diagnostic-settings
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name of the diagnostic setting."
  type        = string
}

variable "target_resource_id" {
  description = "ID of the target resource to monitor."
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace to send diagnostics to."
  type        = string
}

variable "log_categories" {
  description = "List of log categories to enable."
  type        = list(string)
  default     = []
}

variable "metric_categories" {
  description = "List of metric categories to enable."
  type        = list(string)
  default     = ["AllMetrics"]
}
