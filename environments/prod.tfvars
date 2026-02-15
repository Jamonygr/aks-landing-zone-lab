# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Prod Environment - All Features (Reference Only)                           ║
# ║  Estimated cost: ~$1,000+/mo (all toggles ON incl. Firewall)               ║
# ║  ⚠️  NOT recommended for learning - use dev or lab environments            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

environment  = "prod"
location     = "eastus"
project_name = "akslab"
owner        = "Jamon"

# ─── Networking ───────────────────────────────────────────────────────────────
hub_vnet_cidr       = "10.0.0.0/16"
spoke_aks_vnet_cidr = "10.1.0.0/16"

# ─── AKS ──────────────────────────────────────────────────────────────────────
kubernetes_version       = "1.32"
system_node_pool_vm_size = "Standard_B2s"
user_node_pool_vm_size   = "Standard_B4ms"
system_node_pool_min     = 2
system_node_pool_max     = 3
user_node_pool_min       = 2
user_node_pool_max       = 5

# ─── Alerting ─────────────────────────────────────────────────────────────────
alert_email   = "admin@example.com"
budget_amount = 1200

# ─── Optional Toggles (all ON) ───────────────────────────────────────────────
enable_firewall           = true
enable_managed_prometheus = true
enable_managed_grafana    = true
enable_defender           = true
enable_dns_zone           = true
dns_zone_name             = "akslab-prod.example.com"
enable_cluster_alerts     = true
enable_keda               = true
enable_azure_files        = true
enable_app_insights       = true


