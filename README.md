# AKS Landing Zone Lab

![AKS Landing Zone Lab](docs/images/hero.svg)

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5-1f2937?style=for-the-badge&logo=terraform&logoColor=white)](#)
[![Azure AKS](https://img.shields.io/badge/Azure-AKS-0ea5e9?style=for-the-badge&logo=microsoftazure&logoColor=white)](#)
[![PowerShell](https://img.shields.io/badge/PowerShell-Ops-0f766e?style=for-the-badge&logo=powershell&logoColor=white)](#)
[![License MIT](https://img.shields.io/badge/License-MIT-111827?style=for-the-badge)](LICENSE)

Enterprise-style AKS lab deployed with Terraform across modular landing zones:
networking, AKS platform, management, security, governance, and identity.

## Highlights

- Hub-spoke network model for AKS.
- AKS with system/user pools, OIDC, workload identity, Azure RBAC.
- ACR integration with `AcrPull` role assignment.
- NGINX ingress with static public IP.
- Monitoring, alerting, and budget controls.
- Policy and identity foundations for secure workloads.

## Architecture

![Architecture Overview](docs/images/architecture-overview.svg)

![Deployment Flow](docs/images/deployment-flow.svg)

## Quick Start

1. Bootstrap dependencies and backend:

```powershell
.\scripts\bootstrap.ps1
```

2. Deploy infrastructure:

```powershell
.\scripts\deploy.ps1 -Environment dev
```

3. Connect to cluster:

```powershell
.\scripts\get-credentials.ps1 -Environment dev
kubectl get nodes
```

4. Deploy workloads:

```powershell
.\scripts\deploy-workloads.ps1
```

5. Stop/start lab when idle:

```powershell
.\scripts\stop-lab.ps1 -Environment dev
.\scripts\start-lab.ps1 -Environment dev
.\scripts\cost-check.ps1 -Environment dev
```

6. Clean up:

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

## Environment Profiles

| File | Purpose |
|---|---|
| `environments/dev.tfvars` | Lower-cost baseline |
| `environments/lab.tfvars` | More features for testing |
| `environments/prod.tfvars` | Reference profile |

## Operational Commands

```powershell
# validate
terraform fmt -check -recursive
terraform validate

# deploy / access
.\scripts\deploy.ps1 -Environment lab
.\scripts\get-credentials.ps1 -Environment lab

# lifecycle and cost
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
|- environments/
|- landing-zones/
|- modules/
|- k8s/
|- scripts/
|- docs/
|- wiki/
```

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
