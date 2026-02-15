#--------------------------------------------------------------
# AKS Landing Zone - AKS Platform Module Outputs
#--------------------------------------------------------------

output "cluster_id" {
  description = "Resource ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.id
}

output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

output "cluster_fqdn" {
  description = "FQDN of the AKS cluster API server"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "kube_config_host" {
  description = "Kubernetes API server host"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].host
  sensitive   = true
}

output "kube_config_client_certificate" {
  description = "Base64-encoded client certificate for cluster authentication"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].client_certificate
  sensitive   = true
}

output "kube_config_client_key" {
  description = "Base64-encoded client key for cluster authentication"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].client_key
  sensitive   = true
}

output "kube_config_cluster_ca" {
  description = "Base64-encoded cluster CA certificate"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

output "kube_admin_config_host" {
  description = "Kubernetes API server host (admin)"
  value       = azurerm_kubernetes_cluster.main.kube_admin_config[0].host
  sensitive   = true
}

output "kube_admin_config_client_certificate" {
  description = "Base64-encoded admin client certificate for cluster authentication"
  value       = azurerm_kubernetes_cluster.main.kube_admin_config[0].client_certificate
  sensitive   = true
}

output "kube_admin_config_client_key" {
  description = "Base64-encoded admin client key for cluster authentication"
  value       = azurerm_kubernetes_cluster.main.kube_admin_config[0].client_key
  sensitive   = true
}

output "kube_admin_config_cluster_ca" {
  description = "Base64-encoded admin cluster CA certificate"
  value       = azurerm_kubernetes_cluster.main.kube_admin_config[0].cluster_ca_certificate
  sensitive   = true
}

output "kubelet_identity_object_id" {
  description = "Object ID of the kubelet managed identity"
  value       = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for workload identity federation"
  value       = azurerm_kubernetes_cluster.main.oidc_issuer_url
}

output "acr_id" {
  description = "Resource ID of the Azure Container Registry"
  value       = azurerm_container_registry.acr.id
}

output "acr_login_server" {
  description = "Login server URL for the Azure Container Registry"
  value       = azurerm_container_registry.acr.login_server
}

output "ingress_public_ip" {
  description = "Public IP address of the NGINX ingress controller"
  value       = azurerm_public_ip.ingress.ip_address
}
