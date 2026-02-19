<div align="center">

<img src="wiki/images/hero.svg" alt="AKS Landing Zone Lab" width="100%"/>

<br/>

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5-844fba?style=for-the-badge&logo=terraform&logoColor=white)](#quick-start)
[![AzureRM](https://img.shields.io/badge/AzureRM-~%3E4.0-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white)](#latest-configuration)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.32-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)](#latest-configuration)
[![Runbook](https://img.shields.io/badge/Runbook-1000_Pages-ff4ea8?style=for-the-badge)](#learning-hub-app-and-fused-runbook)

Infrastructure as code for AKS landing zones, plus a full web app to run the lab operationally.

[Quick Start](#quick-start) | [Latest Configuration](#latest-configuration) | [Environments](#environments) | [Docs](#documentation)

</div>

## What This Repository Contains

- Terraform landing zones for an enterprise-style AKS foundation
- Kubernetes manifests for apps, autoscaling, security, storage, monitoring, chaos, and GitOps
- PowerShell automation for bootstrap, deploy, build, workloads, and destroy
- Next.js Learning Hub app with module tracking, journal APIs, and fused module runbooks

## Latest Configuration

Current baseline from this repo:

| Area | Value |
|:--|:--|
| Terraform | `>= 1.5.0` |
| Providers | `azurerm ~> 4.0`, `helm ~> 2.12`, `random ~> 3.5` |
| AKS version | `1.32` |
| Landing zones | 7 total (`data` is optional) |
| Terraform modules | 16 top-level modules + 11 nested submodules |
| Runbook model | 1000 pages, 50 modules, 20 pages per module |
| Runbook location | `app/src/lib/wiki.ts` rendered under `/labs` |

## Architecture

<div align="center">
<img src="wiki/images/architecture-overview.svg" alt="Architecture Overview" width="100%"/>
</div>

<div align="center">
<img src="wiki/images/deployment-flow.svg" alt="Deployment Flow" width="100%"/>
</div>

Core network plan:

| Network | CIDR | Purpose |
|:--|:--|:--|
| Hub VNet | `10.0.0.0/16` | Shared services and management |
| Spoke VNet | `10.1.0.0/16` | AKS system/user/ingress workloads |
| Pod CIDR | `192.168.0.0/16` | Azure CNI Overlay pods |
| Service CIDR | `172.16.0.0/16` | ClusterIP services |

## Environments

Values below are aligned with `environments/dev.tfvars`, `environments/lab.tfvars`, and `environments/prod.tfvars`.

| Setting | Dev | Lab | Prod |
|:--|:--:|:--:|:--:|
| File | `environments/dev.tfvars` | `environments/lab.tfvars` | `environments/prod.tfvars` |
| Budget (`budget_amount`) | `100` USD/mo | `130` USD/mo | `1200` USD/mo |
| Node pools (system/user min-max) | `1-2` / `1-3` | `1-2` / `1-3` | `2-3` / `2-5` |
| VM sizes | `B2s` / `B2s` | `B2s` / `B2s` | `B2s` / `B4ms` |
| Managed Prometheus | Off | On | On |
| Managed Grafana | Off | On | On |
| Defender for Containers | Off | Off | On |
| DNS zone | Off | On | On |
| SQL database | Off | On (`eastus2`) | On (`eastus2`) |
| Azure Firewall | Off | Off | On |
| KEDA | Off | On | On |
| Azure Files | Off | On | On |
| App Insights | Off | Off | On |

## Quick Start

Prereqs:

- Azure CLI
- Terraform >= 1.5
- kubectl
- Helm
- PowerShell 7+

Deploy infra (lab):

```powershell
az login
az account set --subscription "<subscription-id>"

.\scripts\deploy.ps1 -Environment lab
.\scripts\get-credentials.ps1 -Environment lab
```

Build and deploy app workloads:

```powershell
.\scripts\build-app.ps1 -Environment lab -Tag latest
.\scripts\deploy-workloads.ps1 -Environment lab -ImageTag latest
```

Notes about workload deploy behavior:

- `scripts/deploy-workloads.ps1` renders manifest tokens from Terraform outputs.
- It validates unresolved template tokens before apply.
- It skips `autoscaling/keda-scaledobject.yaml` if KEDA CRDs are not installed.

Destroy environment:

```powershell
.\scripts\destroy.ps1 -Environment lab -AutoApprove
```

State backend cleanup is intentionally manual:

```powershell
az group delete --name rg-terraform-state --yes
```

## Learning Hub App And Fused Runbook

The wiki/runbook model is fused under Modules in the app:

- `1000` generated runbook pages
- grouped into `50` modules with `20` pages each
- page and module completion tracking in browser storage
- module-level status/checkpoint tracking backed by SQL APIs (with in-memory fallback)

Start at:

- `/labs` for module tracker + runbook index
- `/labs#module-runbook` for module/page navigation
- `/journal` for operations entries

## Repository Structure

```text
aks-landing-zone-lab/
├── environments/                # dev/lab/prod tfvars
├── landing-zones/               # networking, aks-platform, management, security, governance, identity, data
├── modules/                     # 16 reusable Terraform modules
├── k8s/                         # apps, autoscaling, security, monitoring, storage, chaos, gitops, backup
├── scripts/                     # deploy/destroy/build/workload operations
├── app/                         # Next.js AKS Learning Hub web app
└── wiki/                        # documentation and SVG diagrams
```

## Documentation

- `wiki/README.md`
- `wiki/landing-zones/README.md`
- `wiki/modules/README.md`
- `wiki/guides/lab-guide.md`
- `wiki/reference/variables.md`

## Validation

```powershell
terraform fmt -check -recursive
terraform validate
terraform plan -var-file="environments/lab.tfvars"
```

## License

MIT (`LICENSE`)
