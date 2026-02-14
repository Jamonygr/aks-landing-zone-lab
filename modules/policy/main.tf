# -----------------------------------------------------------------------------
# Module: policy
# Description: Assigns an Azure Policy to a scope (e.g., AKS pod security baseline)
# -----------------------------------------------------------------------------

resource "azurerm_resource_policy_assignment" "this" {
  name                 = var.name
  resource_id          = var.scope
  policy_definition_id = var.policy_definition_id
  parameters           = var.parameters
}
