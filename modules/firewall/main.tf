# -----------------------------------------------------------------------------
# Module: firewall
# Description: Creates an Azure Firewall with a public IP
# -----------------------------------------------------------------------------

resource "azurerm_public_ip" "fw" {
  name                = "${var.name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

resource "azurerm_firewall" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = var.sku_tier

  ip_configuration {
    name                 = "fw-ip-config"
    subnet_id            = var.subnet_id
    public_ip_address_id = azurerm_public_ip.fw.id
  }

  tags = var.tags
}
