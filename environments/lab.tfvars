# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Lab Environment - Extended Features Enabled                                ║
# ║  Estimated cost: ~$105-$130/mo (excl. Firewall)                            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

environment  = "lab"
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
budget_amount = 130

# ─── Optional Toggles (monitoring ON, firewall OFF) ──────────────────────────
enable_firewall           = false # +$900/mo - leave off unless needed
enable_managed_prometheus = true  # +$0-5/mo
enable_managed_grafana    = true  # +$10/mo
enable_defender           = false # +$7/node/mo
enable_dns_zone           = true  # +$0.50/mo
dns_zone_name             = "akslab-lab.example.com"
enable_cluster_alerts     = true  # alerts after AKS comes online
enable_keda               = true  # free
enable_azure_files        = true  # +$1/mo
enable_app_insights       = false # +$0-5/mo


