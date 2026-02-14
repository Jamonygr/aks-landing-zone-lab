# -----------------------------------------------------------------------------
# Module: cost-management
# Description: Creates a subscription-level consumption budget with notifications
# -----------------------------------------------------------------------------

resource "azurerm_consumption_budget_subscription" "this" {
  name            = var.name
  subscription_id = var.subscription_id
  amount          = var.amount

  time_period {
    start_date = var.time_period.start_date
    end_date   = var.time_period.end_date
  }

  dynamic "notification" {
    for_each = var.notifications
    content {
      operator       = notification.value.operator
      threshold      = notification.value.threshold
      threshold_type = notification.value.threshold_type
      contact_emails = notification.value.contact_emails
      enabled        = true
    }
  }
}
