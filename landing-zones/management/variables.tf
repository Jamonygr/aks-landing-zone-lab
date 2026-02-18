#--------------------------------------------------------------
# AKS Landing Zone - Management Module Variables
#--------------------------------------------------------------

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for resource deployment"
  type        = string
  default     = "eastus2"
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    project    = "aks-landing-zone"
    managed_by = "terraform"
  }
}

variable "cluster_id" {
  description = "Resource ID of the AKS cluster for diagnostic settings and alerts"
  type        = string
  default     = null
}

variable "enable_cluster_alerts" {
  description = "Enable cluster-dependent diagnostics and alert rules"
  type        = bool
  default     = false
}

variable "enable_managed_prometheus" {
  description = "Toggle to deploy Azure Managed Prometheus workspace"
  type        = bool
  default     = false
}

variable "enable_managed_grafana" {
  description = "Toggle to deploy Azure Managed Grafana instance"
  type        = bool
  default     = false

  validation {
    condition     = !var.enable_managed_grafana || var.enable_managed_prometheus
    error_message = "enable_managed_grafana requires enable_managed_prometheus = true."
  }
}

variable "alert_email" {
  description = "Email address to receive alert notifications"
  type        = string
  default     = "admin@example.com"

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.alert_email))
    error_message = "alert_email must be a valid email address."
  }
}

variable "log_analytics_daily_quota_gb" {
  description = "Daily ingestion quota in GB for Log Analytics workspace (-1 for unlimited)"
  type        = number
  default     = 1
}

variable "budget_amount" {
  description = "Monthly budget threshold in USD"
  type        = number
  default     = 100
}
