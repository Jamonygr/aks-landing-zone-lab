# -----------------------------------------------------------------------------
# Module: firewall-rules
# Description: Creates firewall network and application rule collections for AKS egress
# -----------------------------------------------------------------------------

resource "azurerm_firewall_network_rule_collection" "this" {
  name                = "${var.name}-network-rules"
  azure_firewall_name = var.firewall_name
  resource_group_name = var.resource_group_name
  priority            = var.priority
  action              = "Allow"

  dynamic "rule" {
    for_each = var.rules.network_rules
    content {
      name                  = rule.value.name
      protocols             = rule.value.protocols
      source_addresses      = rule.value.source_addresses
      destination_addresses = rule.value.destination_addresses
      destination_ports     = rule.value.destination_ports
    }
  }
}

resource "azurerm_firewall_application_rule_collection" "this" {
  name                = "${var.name}-app-rules"
  azure_firewall_name = var.firewall_name
  resource_group_name = var.resource_group_name
  priority            = var.priority + 100
  action              = "Allow"

  dynamic "rule" {
    for_each = var.rules.application_rules
    content {
      name             = rule.value.name
      source_addresses = rule.value.source_addresses

      dynamic "protocol" {
        for_each = rule.value.protocols
        content {
          type = protocol.value.type
          port = protocol.value.port
        }
      }

      target_fqdns = rule.value.target_fqdns
    }
  }
}
