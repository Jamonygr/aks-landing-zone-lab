# -----------------------------------------------------------------------------
# Outputs: aks
# -----------------------------------------------------------------------------

output "id" {
  description = "The ID of the AKS cluster."
  value       = azurerm_kubernetes_cluster.this.id
}

output "name" {
  description = "The name of the AKS cluster."
  value       = azurerm_kubernetes_cluster.this.name
}

output "fqdn" {
  description = "The FQDN of the AKS cluster."
  value       = azurerm_kubernetes_cluster.this.fqdn
}

output "kube_config_host" {
  description = "The Kubernetes cluster server host."
  value       = azurerm_kubernetes_cluster.this.kube_config[0].host
  sensitive   = true
}

output "kube_config_client_certificate" {
  description = "Base64 encoded public certificate for client auth."
  value       = azurerm_kubernetes_cluster.this.kube_config[0].client_certificate
  sensitive   = true
}

output "kube_config_client_key" {
  description = "Base64 encoded private key for client auth."
  value       = azurerm_kubernetes_cluster.this.kube_config[0].client_key
  sensitive   = true
}

output "kube_config_cluster_ca_certificate" {
  description = "Base64 encoded CA certificate for the cluster."
  value       = azurerm_kubernetes_cluster.this.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

output "kubelet_identity_object_id" {
  description = "Object ID of the kubelet managed identity."
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

output "oidc_issuer_url" {
  description = "The OIDC issuer URL of the cluster."
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "node_resource_group" {
  description = "The auto-generated resource group for AKS nodes."
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}
