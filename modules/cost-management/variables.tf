# -----------------------------------------------------------------------------
# Variables: cost-management
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name of the consumption budget."
  type        = string
}

variable "subscription_id" {
  description = "The subscription ID to scope the budget to."
  type        = string
}

variable "amount" {
  description = "The total budget amount."
  type        = number
}

variable "time_period" {
  description = "The time period for the budget."
  type = object({
    start_date = string
    end_date   = optional(string)
  })
}

variable "notifications" {
  description = "List of notification thresholds and contacts."
  type = list(object({
    operator       = string
    threshold      = number
    threshold_type = string
    contact_emails = list(string)
  }))
}
