# -----------------------------------------------------------------------------
# Variables: monitoring/alerts
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name of the metric alert."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "scopes" {
  description = "List of resource IDs to scope the alert to."
  type        = list(string)
}

variable "description" {
  description = "Description of the alert."
  type        = string
  default     = ""
}

variable "criteria" {
  description = "Criteria for the metric alert."
  type = object({
    metric_namespace = string
    metric_name      = string
    aggregation      = string
    operator         = string
    threshold        = number
  })
}

variable "action_group_id" {
  description = "ID of the action group to trigger."
  type        = string
}

variable "severity" {
  description = "Severity of the alert (0-4)."
  type        = number
  default     = 3
}

variable "frequency" {
  description = "Evaluation frequency (e.g., PT5M)."
  type        = string
  default     = "PT5M"
}

variable "window_size" {
  description = "Lookback window size (e.g., PT15M)."
  type        = string
  default     = "PT15M"
}
