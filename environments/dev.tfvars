# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Dev Environment - Budget-Safe Defaults                                     ║
# ║  Estimated cost: ~$80-$100/mo always-on, ~$55-$75 with stop/start          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

environment  = "dev"
location     = "eastus"
project_name = "akslab"
owner        = "Jamon"

# ─── Networking ───────────────────────────────────────────────────────────────
hub_vnet_cidr       = "10.0.0.0/16"
spoke_aks_vnet_cidr = "10.1.0.0/16"

# ─── AKS ──────────────────────────────────────────────────────────────────────
kubernetes_version       = "1.32"
system_node_pool_vm_size = "Standard_B2s"
user_node_pool_vm_size   = "Standard_B2s"
system_node_pool_min     = 1
system_node_pool_max     = 2
user_node_pool_min       = 1
user_node_pool_max       = 3

# ─── Alerting ─────────────────────────────────────────────────────────────────
alert_email   = "admin@example.com"
budget_amount = 100

# ─── Optional Toggles (all OFF for budget safety) ────────────────────────────
enable_firewall           = false # +$900/mo
enable_managed_prometheus = false # +$0-5/mo
enable_managed_grafana    = false # +$10/mo
enable_defender           = false # +$7/node/mo
enable_dns_zone           = false # +$0.50/mo
enable_cluster_alerts     = true  # alerts after AKS comes online
enable_keda               = false # free
enable_azure_files        = false # +$1/mo
enable_app_insights       = false # +$0-5/mo


