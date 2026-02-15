# AKS Landing Zone Lab

<p align="center">
  <img src="docs/images/hero.svg" alt="AKS Landing Zone Lab hero" width="100%" />
</p>

<p align="center">
  <img alt="Terraform >=1.5" src="https://img.shields.io/badge/Terraform-%3E%3D1.5-1f2937?style=for-the-badge&logo=terraform&logoColor=white" />
  <img alt="Azure AKS" src="https://img.shields.io/badge/Azure-AKS-0ea5e9?style=for-the-badge&logo=microsoftazure&logoColor=white" />
  <img alt="PowerShell Ops Scripts" src="https://img.shields.io/badge/PowerShell-Automation-0f766e?style=for-the-badge&logo=powershell&logoColor=white" />
  <img alt="License MIT" src="https://img.shields.io/badge/License-MIT-111827?style=for-the-badge" />
</p>

Opinionated AKS platform lab built with Terraform and organized as landing zones: networking, AKS platform, management, security, governance, and identity.

## Contents

- [What You Get](#what-you-get)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Terraform Workflow](#terraform-workflow)
- [Environment Profiles](#environment-profiles)
- [Cost Controls](#cost-controls)
- [Operations Commands](#operations-commands)
- [Repository Layout](#repository-layout)
- [Validation and Known Issues](#validation-and-known-issues)
- [Documentation](#documentation)

## What You Get

| Area | Included |
|---|---|
| Networking | Hub-spoke VNets, subnet segmentation, NSGs, route tables, optional Azure Firewall |
| AKS Platform | AKS cluster with system/user pools, Azure CNI Overlay, Calico, OIDC, workload identity |
| Ingress + Registry | NGINX ingress controller with static public IP, ACR + `AcrPull` role assignment |
| Observability | Log Analytics, AKS diagnostics, metric and query-based alerts, budget alerts |
| Security | Policy baseline assignment, Key Vault, CSI Secrets Store, optional Defender |
| Governance + Identity | Custom policy definitions/assignments, managed identities, federated identity credentials |

## Architecture

![Architecture overview](docs/images/architecture-overview.svg)

```mermaid
graph TB
    INTERNET((Internet))

    subgraph HUB["Hub VNet 10.0.0.0/16"]
        HUB_MGMT["snet-management<br/>10.0.0.0/24"]
        HUB_SHARED["snet-shared-services<br/>10.0.1.0/24"]
        HUB_FW["AzureFirewallSubnet<br/>10.0.2.0/24 (optional)"]
    end

    subgraph SPOKE["Spoke VNet 10.1.0.0/16"]
        SPOKE_SYS["snet-aks-system<br/>10.1.0.0/24"]
        SPOKE_USER["snet-aks-user<br/>10.1.1.0/24"]
        SPOKE_ING["snet-ingress<br/>10.1.2.0/24"]
    end

    subgraph AKS["AKS Cluster"]
        SYSPOOL["System Node Pool"]
        USERPOOL["User Node Pool"]
        NGINX["NGINX Ingress"]
    end

    subgraph AZ["Azure Services"]
        ACR["Azure Container Registry"]
        LAW["Log Analytics"]
        KV["Key Vault"]
    end

    HUB <-->|VNet peering| SPOKE
    INTERNET --> SPOKE_ING --> NGINX --> USERPOOL
    SPOKE_SYS --> SYSPOOL
    SPOKE_USER --> USERPOOL
    AKS --> ACR
    AKS --> LAW
    AKS --> KV
```

![Deployment flow](docs/images/deployment-flow.svg)

## Quick Start

1. Bootstrap tools, Azure login, and Terraform backend.

```powershell
.\scripts\bootstrap.ps1
```

2. Deploy infrastructure.

```powershell
.\scripts\deploy.ps1 -Environment dev
```

3. Pull kubeconfig and verify cluster access.

```powershell
.\scripts\get-credentials.ps1 -Environment dev
kubectl get nodes
```

4. Deploy sample workloads.

```powershell
.\scripts\deploy-workloads.ps1
```

5. Pause and resume to reduce lab cost.

```powershell
.\scripts\stop-lab.ps1 -Environment dev
.\scripts\start-lab.ps1 -Environment dev
.\scripts\cost-check.ps1 -Environment dev
```

6. Destroy when finished.

```powershell
.\scripts\cleanup-workloads.ps1 -AutoApprove
.\scripts\destroy.ps1 -Environment dev
```

## Terraform Workflow

```powershell
terraform init
terraform plan  -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"
terraform output kubeconfig_command
```

Useful outputs:

```powershell
terraform output cluster_name
terraform output cluster_fqdn
terraform output ingress_public_ip
terraform output acr_login_server
```

## Environment Profiles

| File | Purpose | Typical Cost Profile |
|---|---|---|
| `environments/dev.tfvars` | budget-safe defaults | lower cost |
| `environments/lab.tfvars` | broader feature coverage | medium cost |
| `environments/prod.tfvars` | reference profile with most toggles enabled | high cost |

Important behavior:

- `enable_dns_zone = true` requires `dns_zone_name`.
- Scripts currently support `dev`, `lab`, and `prod`.

## Cost Controls

Primary spend levers:

- `enable_firewall`
- `enable_managed_prometheus`
- `enable_managed_grafana`
- `enable_defender`
- `enable_dns_zone`
- `enable_cluster_alerts`

Review and tune in:

- `environments/dev.tfvars`
- `environments/lab.tfvars`
- `environments/prod.tfvars`

## Operations Commands

```powershell
# Deploy / update
.\scripts\deploy.ps1 -Environment lab

# Access cluster
.\scripts\get-credentials.ps1 -Environment lab

# Validate IaC
terraform fmt -check -recursive
terraform validate

# Cost / lifecycle
.\scripts\cost-check.ps1 -Environment lab
.\scripts\stop-lab.ps1 -Environment lab
.\scripts\start-lab.ps1 -Environment lab
```

## Repository Layout

```text
AKS/
|- backend.tf
|- providers.tf
|- main.tf
|- variables.tf
|- locals.tf
|- outputs.tf
|- environments/              # environment tfvars
|- landing-zones/             # networking, aks-platform, management, security, governance, identity
|- modules/                   # reusable Terraform modules
|- k8s/                       # Kubernetes manifests
|- scripts/                   # bootstrap, deploy, destroy, ops scripts
|- docs/                      # architecture and operations guides
|- wiki/                      # deeper reference content
```

## Validation and Known Issues

Current validation checks:

- `terraform validate` passes.
- `terraform fmt -check -recursive` currently flags `landing-zones/governance/main.tf`.
- `terraform plan -var-file="environments/lab.tfvars" -lock=false -refresh=false -no-color` currently shows pending additions (`41 to add, 0 to change, 0 to destroy`).

Known issues worth fixing before multi-environment use:

- `backend.tf` uses a single remote state key (`aks-landing-zone-lab.tfstate`) for all environments.
- Several provider deprecation warnings are present (`metric` blocks in diagnostic settings, `enable_rbac_authorization` in Key Vault).

## Documentation

- `docs/lab-guide.md`
- `docs/architecture.md`
- `docs/monitoring-guide.md`
- `docs/security-guide.md`
- `docs/cost-optimization.md`
- `docs/chaos-guide.md`
- `docs/gitops-guide.md`
- `docs/troubleshooting.md`

## License

MIT
