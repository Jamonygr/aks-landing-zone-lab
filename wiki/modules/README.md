<div align="center">
  <img src="../images/wiki-modules.svg" alt="Module Index" width="900"/>
</div>

<div align="center">

[![Top Level Modules](https://img.shields.io/badge/Top_Level_Modules-16-ff4ea8?style=for-the-badge)](.)
[![Nested Modules](https://img.shields.io/badge/Nested_Submodules-11-39f4ff?style=for-the-badge)](.)
[![Primary Provider](https://img.shields.io/badge/azurerm-~%3E4.0-a56fff?style=for-the-badge&logo=terraform)](.)

</div>

# Module Index

This repository contains **16 top-level Terraform modules** under `modules/`.
Nested reusable components are currently grouped under:

- `modules/networking/*` (6)
- `modules/monitoring/*` (5)

Total nested submodules: **11**.

## Top-Level Module Directories

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
├── naming/
├── networking/
├── policy/
├── private-endpoint/
├── rbac/
├── resource-group/
├── sql-database/
└── storage/
```

## Active Root Usage

Directly from `main.tf` and landing-zone module wiring:

- The root deployment orchestrates landing zones in `landing-zones/*`.
- Inside landing zones, only `landing-zones/data/main.tf` currently consumes a library module directly:
  - `../../modules/sql-database`
- `modules/sql-database` then composes:
  - `modules/private-endpoint`
  - `modules/networking/private-dns-zone`

Most other modules are reusable building blocks available for future decomposition or alternate root compositions.

## Module Purpose Map

| Module | Purpose |
|:--|:--|
| `acr` | ACR patterns and registry configuration |
| `aks` | AKS cluster and node-pool module patterns |
| `cost-management` | Budget and cost notification patterns |
| `firewall` | Azure Firewall resources |
| `firewall-rules` | Firewall policy/rule collections |
| `ingress` | NGINX ingress Helm deployment module |
| `keyvault` | Key Vault and RBAC assignment patterns |
| `monitoring/*` | Alerts, diagnostics, Log Analytics, flow-log integrations |
| `naming` | Naming and convention helpers |
| `networking/*` | VNet, subnet, NSG, route-table, peering, private DNS |
| `policy` | Azure Policy definition/assignment helper |
| `private-endpoint` | Generic private endpoint helper |
| `rbac` | Azure role assignment helper |
| `resource-group` | Resource-group creation helper |
| `sql-database` | Azure SQL + private endpoint + diagnostics composition |
| `storage` | Storage account helpers |

## Design Principles

1. Keep modules single-purpose and composable.
2. Enforce typed inputs with safe defaults.
3. Keep tags and naming consistent from root locals.
4. Export meaningful outputs (IDs, endpoints, names).
5. Let provider config be inherited from root.

## Related Docs

- `../landing-zones/README.md`
- `../README.md`
- `../reference/variables.md`
