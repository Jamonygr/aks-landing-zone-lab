<div align="center">
  <img src="../images/wiki-modules.svg" alt="Module Index" width="900"/>
</div>

<div align="center">

[![Modules](https://img.shields.io/badge/Modules-16-purple?style=for-the-badge)](.)
[![Nested](https://img.shields.io/badge/Nested_Submodules-11-blue?style=for-the-badge)](.)
[![Provider](https://img.shields.io/badge/azurerm-~>4.0-green?style=for-the-badge&logo=terraform)](.)

</div>

# 🧩 Module Index

The repository currently contains **16 reusable Terraform modules**.  
In the active root deployment, `landing-zones/data` consumes `modules/sql-database`, which in turn uses `modules/private-endpoint` and `modules/networking/private-dns-zone`.

---

## 📂 Module Directory

```text
modules/
├── acr/
├── aks/
├── cost-management/
├── firewall/
├── firewall-rules/
├── ingress/
├── keyvault/
├── monitoring/
│   ├── action-group/
│   ├── alerts/
│   ├── diagnostic-settings/
│   ├── log-analytics/
│   └── nsg-flow-logs/
├── naming/
├── networking/
│   ├── nsg/
│   ├── peering/
│   ├── private-dns-zone/
│   ├── route-table/
│   ├── subnet/
│   └── vnet/
├── policy/
├── private-endpoint/
├── rbac/
├── resource-group/
├── sql-database/
└── storage/
```

---

## 📚 Module Reference

| Module | Purpose | Current Root Usage |
|--------|---------|--------------------|
| `acr` | Azure Container Registry + role assignment patterns | Reusable (not directly wired) |
| `aks` | AKS cluster and node pool patterns | Reusable (not directly wired) |
| `cost-management` | Subscription budget and notifications | Reusable (not directly wired) |
| `firewall` | Azure Firewall resources | Reusable (not directly wired) |
| `firewall-rules` | Firewall rule collections | Reusable (not directly wired) |
| `ingress` | NGINX ingress Helm deployment | Reusable (not directly wired) |
| `keyvault` | Key Vault with RBAC assignments | Reusable (not directly wired) |
| `monitoring/*` | Log Analytics, alerts, diagnostics, NSG flow logs | Reusable (not directly wired) |
| `naming` | Naming map generation | Reusable (not directly wired) |
| `networking/*` | VNet, subnet, NSG, peering, route table, private DNS | `private-dns-zone` used by `sql-database` |
| `policy` | Azure Policy assignment helper | Reusable (not directly wired) |
| `private-endpoint` | Generic private endpoint resource | Used by `sql-database` |
| `rbac` | Azure role assignment helper | Reusable (not directly wired) |
| `resource-group` | Resource group helper | Reusable (not directly wired) |
| `sql-database` | Azure SQL (Basic), private endpoint, diagnostics | Used by `landing-zones/data` |
| `storage` | Storage account helper | Reusable (not directly wired) |

---

## 🎯 Design Principles

1. Single-responsibility modules
2. Typed inputs with practical defaults
3. Consistent tags from root inputs
4. Useful IDs and endpoints exported as outputs
5. Provider configuration inherited from the root module

---

<div align="center">

**[&larr; Landing Zones](../landing-zones/README.md)** &nbsp;&nbsp;|&nbsp;&nbsp; **[Wiki Home](../README.md)** &nbsp;&nbsp;|&nbsp;&nbsp; **[Reference &rarr;](../reference/naming-conventions.md)**

</div>
