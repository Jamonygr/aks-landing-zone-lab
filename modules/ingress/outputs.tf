# -----------------------------------------------------------------------------
# Outputs: ingress
# -----------------------------------------------------------------------------

output "public_ip_address" {
  description = "The public IP address assigned to the ingress controller."
  value       = azurerm_public_ip.ingress.ip_address
}
