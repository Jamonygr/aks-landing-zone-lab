#--------------------------------------------------------------
# AKS Landing Zone - Networking Module Outputs
#--------------------------------------------------------------

output "hub_vnet_id" {
  description = "Resource ID of the hub virtual network"
  value       = azurerm_virtual_network.hub.id
}

output "spoke_vnet_id" {
  description = "Resource ID of the AKS spoke virtual network"
  value       = azurerm_virtual_network.spoke_aks.id
}

output "spoke_resource_group_name" {
  description = "Name of the spoke networking resource group"
  value       = azurerm_resource_group.spoke.name
}

output "aks_system_subnet_id" {
  description = "Resource ID of the AKS system node pool subnet"
  value       = azurerm_subnet.aks_system.id
}

output "aks_user_subnet_id" {
  description = "Resource ID of the AKS user node pool subnet"
  value       = azurerm_subnet.aks_user.id
}

output "ingress_subnet_id" {
  description = "Resource ID of the ingress subnet"
  value       = azurerm_subnet.ingress.id
}

output "hub_resource_group_name" {
  description = "Name of the hub networking resource group"
  value       = azurerm_resource_group.hub.name
}
