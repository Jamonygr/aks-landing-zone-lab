# Module Index

The AKS Landing Zone Lab contains **14 reusable Terraform modules** (with 5 sub-modules under `monitoring/`), organized for composability and reuse across landing zones.

---

## Module Directory

```
modules/
├── acr/                          # Azure Container Registry
├── aks/                          # AKS Cluster + Node Pools
├── cost-management/              # Subscription Budget
├── firewall/                     # Azure Firewall
├── firewall-rules/               # Firewall Network + Application Rules
├── ingress/                      # NGINX Ingress Controller (Helm)
├── keyvault/                     # Azure Key Vault with RBAC
├── monitoring/
│   ├── action-group/             # Azure Monitor Action Group
│   ├── alerts/                   # Metric Alert Rules
│   ├── diagnostic-settings/      # Diagnostic Settings for any resource
│   ├── log-analytics/            # Log Analytics Workspace + Container Insights
│   └── nsg-flow-logs/            # NSG Flow Logs with Traffic Analytics
├── naming/                       # Resource Naming Convention Generator
├── networking/
│   ├── nsg/                      # Network Security Groups
│   ├── peering/                  # VNet Peering
│   ├── private-dns-zone/         # Private DNS Zone
│   ├── route-table/              # Route Table + UDRs
│   ├── subnet/                   # Subnet
│   └── vnet/                     # Virtual Network
├── policy/                       # Azure Policy Assignment
├── rbac/                         # Azure Role Assignment
├── resource-group/               # Resource Group
└── storage/                      # Azure Storage Account
```

---

## Module Reference

### Core Infrastructure

| Module | Description | Key Resources | Used By |
|--------|------------|---------------|---------|
| **resource-group** | Creates an Azure Resource Group with tags | `azurerm_resource_group` | All landing zones |
| **naming** | Generates standardized resource names using a consistent naming convention | `local.names` map | Root module |
| **storage** | Creates an Azure Storage Account with TLS 1.2 and disabled public blob access | `azurerm_storage_account` | Identity, Backup |

### Networking

| Module | Description | Key Resources | Used By |
|--------|------------|---------------|---------|
| **networking/vnet** | Creates a Virtual Network with address space | `azurerm_virtual_network` | Networking LZ |
| **networking/subnet** | Creates a Subnet within a VNet | `azurerm_subnet` | Networking LZ |
| **networking/peering** | Creates bidirectional VNet peering | `azurerm_virtual_network_peering` | Networking LZ |
| **networking/nsg** | Creates a Network Security Group with configurable rules | `azurerm_network_security_group` | Networking LZ |
| **networking/route-table** | Creates a Route Table with User-Defined Routes | `azurerm_route_table`, `azurerm_route` | Networking LZ |
| **networking/private-dns-zone** | Creates a Private DNS Zone with VNet links | `azurerm_private_dns_zone` | Networking LZ |

### Compute

| Module | Description | Key Resources | Used By |
|--------|------------|---------------|---------|
| **aks** | Creates an AKS cluster with system + user node pools, CNI Overlay, Calico, OIDC, Workload Identity, maintenance window, and auto-scaler profile | `azurerm_kubernetes_cluster`, `azurerm_kubernetes_cluster_node_pool` | AKS Platform LZ |
| **acr** | Creates an Azure Container Registry with AcrPull role assignment for AKS | `azurerm_container_registry`, `azurerm_role_assignment` | AKS Platform LZ |
| **ingress** | Deploys NGINX Ingress Controller via Helm with a static public IP | `azurerm_public_ip`, `helm_release` | AKS Platform LZ |

### Security

| Module | Description | Key Resources | Used By |
|--------|------------|---------------|---------|
| **keyvault** | Creates an Azure Key Vault with RBAC authorization and Key Vault Secrets User role assignments | `azurerm_key_vault`, `azurerm_role_assignment` | Security LZ |
| **policy** | Creates an Azure Policy assignment on a given scope | `azurerm_resource_policy_assignment` | Governance LZ |
| **rbac** | Creates a generic Azure role assignment | `azurerm_role_assignment` | Multiple LZs |
| **firewall** | Creates an Azure Firewall with a Standard public IP | `azurerm_firewall`, `azurerm_public_ip` | Networking LZ |
| **firewall-rules** | Creates firewall network and application rule collections for AKS egress | `azurerm_firewall_network_rule_collection`, `azurerm_firewall_application_rule_collection` | Networking LZ |

### Monitoring

| Module | Description | Key Resources | Used By |
|--------|------------|---------------|---------|
| **monitoring/log-analytics** | Creates a Log Analytics Workspace with Container Insights solution | `azurerm_log_analytics_workspace`, `azurerm_log_analytics_solution` | Management LZ |
| **monitoring/action-group** | Creates an Azure Monitor Action Group with email receiver | `azurerm_monitor_action_group` | Management LZ |
| **monitoring/alerts** | Creates a configurable metric alert with action group integration | `azurerm_monitor_metric_alert` | Management LZ |
| **monitoring/diagnostic-settings** | Creates diagnostic settings for any Azure resource (log categories + metrics) | `azurerm_monitor_diagnostic_setting` | All LZs |
| **monitoring/nsg-flow-logs** | Creates NSG Flow Logs v2 with Traffic Analytics integration | `azurerm_network_watcher_flow_log` | Networking LZ |

### Cost

| Module | Description | Key Resources | Used By |
|--------|------------|---------------|---------|
| **cost-management** | Creates a subscription-level consumption budget with configurable notifications | `azurerm_consumption_budget_subscription` | Management LZ |

---

## Module Design Principles

1. **Single Responsibility**: Each module creates one logical resource or tightly coupled group
2. **Configurable via Variables**: All settings exposed through typed variables with sensible defaults
3. **Tagged**: All resources receive the standard tag set from the root module
4. **Outputs**: Every module exports resource IDs, names, and connection strings for downstream modules
5. **No Provider Configuration**: Modules inherit provider configuration from the root module
6. **Versioned Providers**: Each landing zone pins `azurerm ~> 4.0`

## Creating a New Module

```hcl
# modules/my-module/main.tf
resource "azurerm_my_resource" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# modules/my-module/variables.tf
variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "tags" { type = map(string) ; default = {} }

# modules/my-module/outputs.tf
output "id" { value = azurerm_my_resource.this.id }
output "name" { value = azurerm_my_resource.this.name }
```
