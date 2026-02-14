# -----------------------------------------------------------------------------
# Outputs: networking/peering
# -----------------------------------------------------------------------------

output "peering_ids" {
  description = "IDs of both peering resources."
  value = {
    source_to_dest = azurerm_virtual_network_peering.source_to_dest.id
    dest_to_source = azurerm_virtual_network_peering.dest_to_source.id
  }
}
