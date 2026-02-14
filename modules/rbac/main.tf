# -----------------------------------------------------------------------------
# Module: rbac
# Description: Creates a generic Azure role assignment
# -----------------------------------------------------------------------------

resource "azurerm_role_assignment" "this" {
  scope                = var.scope
  role_definition_name = var.role_definition_name
  principal_id         = var.principal_id
}
