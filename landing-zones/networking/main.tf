#--------------------------------------------------------------
# AKS Landing Zone - Networking Module
# Hub-Spoke Network Topology for AKS
#--------------------------------------------------------------

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.85"
    }
  }
}

#--------------------------------------------------------------
# Resource Groups
#--------------------------------------------------------------

resource "azurerm_resource_group" "hub" {
  name     = "rg-hub-networking-${var.environment}"
  location = var.location
  tags     = var.tags
}

resource "azurerm_resource_group" "spoke" {
  name     = "rg-spoke-aks-networking-${var.environment}"
  location = var.location
  tags     = var.tags
}

#--------------------------------------------------------------
# Hub Virtual Network
#--------------------------------------------------------------

resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub-${var.environment}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  address_space       = [var.hub_vnet_cidr]
  tags                = var.tags
}

resource "azurerm_subnet" "management" {
  name                 = "snet-management"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [cidrsubnet(var.hub_vnet_cidr, 8, 0)] # 10.0.0.0/24
}

resource "azurerm_subnet" "shared_services" {
  name                 = "snet-shared-services"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [cidrsubnet(var.hub_vnet_cidr, 8, 1)] # 10.0.1.0/24
}

resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [cidrsubnet(var.hub_vnet_cidr, 8, 2)] # 10.0.2.0/24
}

#--------------------------------------------------------------
# Spoke Virtual Network (AKS)
#--------------------------------------------------------------

resource "azurerm_virtual_network" "spoke_aks" {
  name                = "vnet-spoke-aks-${var.environment}"
  location            = azurerm_resource_group.spoke.location
  resource_group_name = azurerm_resource_group.spoke.name
  address_space       = [var.spoke_aks_vnet_cidr]
  tags                = var.tags
}

resource "azurerm_subnet" "aks_system" {
  name                 = "snet-aks-system"
  resource_group_name  = azurerm_resource_group.spoke.name
  virtual_network_name = azurerm_virtual_network.spoke_aks.name
  address_prefixes     = [cidrsubnet(var.spoke_aks_vnet_cidr, 8, 0)] # 10.1.0.0/24
}

resource "azurerm_subnet" "aks_user" {
  name                 = "snet-aks-user"
  resource_group_name  = azurerm_resource_group.spoke.name
  virtual_network_name = azurerm_virtual_network.spoke_aks.name
  address_prefixes     = [cidrsubnet(var.spoke_aks_vnet_cidr, 8, 1)] # 10.1.1.0/24
}

resource "azurerm_subnet" "ingress" {
  name                 = "snet-ingress"
  resource_group_name  = azurerm_resource_group.spoke.name
  virtual_network_name = azurerm_virtual_network.spoke_aks.name
  address_prefixes     = [cidrsubnet(var.spoke_aks_vnet_cidr, 8, 2)] # 10.1.2.0/24
}

#--------------------------------------------------------------
# Network Security Groups
#--------------------------------------------------------------

resource "azurerm_network_security_group" "aks_system" {
  name                = "nsg-aks-system-${var.environment}"
  location            = azurerm_resource_group.spoke.location
  resource_group_name = azurerm_resource_group.spoke.name
  tags                = var.tags

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

}

resource "azurerm_network_security_group" "aks_user" {
  name                = "nsg-aks-user-${var.environment}"
  location            = azurerm_resource_group.spoke.location
  resource_group_name = azurerm_resource_group.spoke.name
  tags                = var.tags

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

}

resource "azurerm_network_security_group" "ingress" {
  name                = "nsg-ingress-${var.environment}"
  location            = azurerm_resource_group.spoke.location
  resource_group_name = azurerm_resource_group.spoke.name
  tags                = var.tags

  security_rule {
    name                       = "AllowHTTPInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTPSInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

#--------------------------------------------------------------
# NSG Associations
#--------------------------------------------------------------

resource "azurerm_subnet_network_security_group_association" "aks_system" {
  subnet_id                 = azurerm_subnet.aks_system.id
  network_security_group_id = azurerm_network_security_group.aks_system.id
}

resource "azurerm_subnet_network_security_group_association" "aks_user" {
  subnet_id                 = azurerm_subnet.aks_user.id
  network_security_group_id = azurerm_network_security_group.aks_user.id
}

resource "azurerm_subnet_network_security_group_association" "ingress" {
  subnet_id                 = azurerm_subnet.ingress.id
  network_security_group_id = azurerm_network_security_group.ingress.id
}

#--------------------------------------------------------------
# Route Tables
#--------------------------------------------------------------

resource "azurerm_route_table" "spoke_aks" {
  name                = "rt-spoke-aks-${var.environment}"
  location            = azurerm_resource_group.spoke.location
  resource_group_name = azurerm_resource_group.spoke.name
  tags                = var.tags

  dynamic "route" {
    for_each = var.enable_firewall ? [1] : []
    content {
      name                   = "to-hub"
      address_prefix         = var.hub_vnet_cidr
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = azurerm_firewall.hub[0].ip_configuration[0].private_ip_address
    }
  }

  route {
    name                   = "to-internet"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = var.enable_firewall ? "VirtualAppliance" : "Internet"
    next_hop_in_ip_address = var.enable_firewall ? azurerm_firewall.hub[0].ip_configuration[0].private_ip_address : null
  }
}

resource "azurerm_subnet_route_table_association" "aks_system" {
  subnet_id      = azurerm_subnet.aks_system.id
  route_table_id = azurerm_route_table.spoke_aks.id
}

resource "azurerm_subnet_route_table_association" "aks_user" {
  subnet_id      = azurerm_subnet.aks_user.id
  route_table_id = azurerm_route_table.spoke_aks.id
}

#--------------------------------------------------------------
# VNet Peering
#--------------------------------------------------------------

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                         = "peer-hub-to-spoke-aks"
  resource_group_name          = azurerm_resource_group.hub.name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke_aks.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                         = "peer-spoke-aks-to-hub"
  resource_group_name          = azurerm_resource_group.spoke.name
  virtual_network_name         = azurerm_virtual_network.spoke_aks.name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = false
}

#--------------------------------------------------------------
# Azure Firewall (Optional - Basic SKU)
#--------------------------------------------------------------

resource "azurerm_public_ip" "firewall" {
  count               = var.enable_firewall ? 1 : 0
  name                = "pip-fw-hub-${var.environment}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_firewall_policy" "hub" {
  count               = var.enable_firewall ? 1 : 0
  name                = "fwpol-hub-${var.environment}"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  sku                 = "Basic"
  tags                = var.tags
}

resource "azurerm_firewall" "hub" {
  count               = var.enable_firewall ? 1 : 0
  name                = "fw-hub-${var.environment}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Basic"
  firewall_policy_id  = azurerm_firewall_policy.hub[0].id
  tags                = var.tags

  ip_configuration {
    name                 = "fw-ip-config"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall[0].id
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "aks_rules" {
  count              = var.enable_firewall ? 1 : 0
  name               = "fwpol-rcg-aks-${var.environment}"
  firewall_policy_id = azurerm_firewall_policy.hub[0].id
  priority           = 100

  network_rule_collection {
    name     = "aks-network-rules"
    priority = 100
    action   = "Allow"

    rule {
      name                  = "allow-aks-api"
      protocols             = ["TCP"]
      source_addresses      = [var.spoke_aks_vnet_cidr]
      destination_addresses = ["AzureCloud"]
      destination_ports     = ["443", "9000"]
    }

    rule {
      name                  = "allow-ntp"
      protocols             = ["UDP"]
      source_addresses      = [var.spoke_aks_vnet_cidr]
      destination_addresses = ["*"]
      destination_ports     = ["123"]
    }
  }
}

#--------------------------------------------------------------
# Diagnostic Settings
#--------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "hub_vnet" {
  count                      = var.log_analytics_workspace_id != "" ? 1 : 0
  name                       = "diag-hub-vnet-${var.environment}"
  target_resource_id         = azurerm_virtual_network.hub.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "spoke_vnet" {
  count                      = var.log_analytics_workspace_id != "" ? 1 : 0
  name                       = "diag-spoke-vnet-${var.environment}"
  target_resource_id         = azurerm_virtual_network.spoke_aks.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "nsg_aks_system" {
  count                      = var.log_analytics_workspace_id != "" ? 1 : 0
  name                       = "diag-nsg-aks-system-${var.environment}"
  target_resource_id         = azurerm_network_security_group.aks_system.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}

resource "azurerm_monitor_diagnostic_setting" "firewall" {
  count                      = var.enable_firewall && var.log_analytics_workspace_id != "" ? 1 : 0
  name                       = "diag-fw-hub-${var.environment}"
  target_resource_id         = azurerm_firewall.hub[0].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AzureFirewallApplicationRule"
  }

  enabled_log {
    category = "AzureFirewallNetworkRule"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

