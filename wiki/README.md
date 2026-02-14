# AKS Landing Zone Lab — Wiki

Welcome to the AKS Landing Zone Lab wiki. This project deploys an enterprise-grade AKS environment on Azure using hub-spoke networking, Infrastructure as Code (Terraform), and Kubernetes best practices.

**Budget**: ~$80–100/mo (dev) | **Region**: East US | **Kubernetes**: 1.29

---

## Quick Links

### Getting Started
- [Lab Guide](../docs/lab-guide.md) — 8-day step-by-step lab exercises
- [Cost Optimization](../docs/cost-optimization.md) — Budget management and teardown

### Architecture
- [Architecture Overview](architecture/overview.md)
- [Network Topology](architecture/network-topology.md) — Hub-spoke design, IP plan, traffic flows
- [Security Model](architecture/security-model.md) — Identity, policies, secrets, Defender

### Landing Zones
- [Landing Zones Overview](landing-zones/README.md) — The 6 landing zone modules

### Modules
- [Module Index](modules/README.md) — All reusable Terraform modules

### Reference
- [Naming Conventions](reference/naming-conventions.md) — Resource naming standards
- [Variables Reference](reference/variables.md) — All Terraform input variables
- [Outputs Reference](reference/outputs.md) — All Terraform outputs

### Guides
- [Monitoring Guide](../docs/monitoring-guide.md) — Log Analytics, KQL, Container Insights
- [Security Guide](../docs/security-guide.md) — Network policies, PSA, Key Vault
- [Chaos Engineering Guide](../docs/chaos-guide.md) — Chaos Mesh experiments
- [GitOps Guide](../docs/gitops-guide.md) — Flux v2 setup and workflow
- [Troubleshooting](../docs/troubleshooting.md) — Common errors and fixes

---

## Project Structure

```
AKS/
├── main.tf                    # Root module - orchestrates all landing zones
├── variables.tf               # All input variables
├── outputs.tf                 # Cluster info, endpoints, kubeconfig
├── locals.tf                  # Naming, tags, computed values
├── backend.tf                 # Azure Storage remote state
├── providers.tf               # azurerm, azuread, helm, kubernetes
├── environments/              # Per-environment variable files
│   ├── dev.tfvars             # Budget-safe defaults (~$80-100/mo)
│   ├── lab.tfvars             # Extended features (~$105-130/mo)
│   └── prod.tfvars            # Production settings
├── landing-zones/             # 6 landing zone modules
│   ├── networking/            # Hub-spoke VNets, peering, NSGs
│   ├── aks-platform/          # AKS cluster, ACR, ingress
│   ├── management/            # Log Analytics, alerts, budgets
│   ├── security/              # Key Vault, policies, Defender
│   ├── governance/            # Custom Azure Policies
│   └── identity/              # Workload Identity, managed identities
├── modules/                   # 14 reusable Terraform modules
├── k8s/                       # Kubernetes manifests
│   ├── namespaces/            # Namespace definitions, quotas, RBAC
│   ├── apps/                  # 13 sample workloads
│   ├── security/              # Network policies, PSA
│   ├── autoscaling/           # HPA, KEDA, load tests
│   ├── storage/               # StorageClasses
│   ├── monitoring/            # Prometheus scrape configs
│   ├── chaos/                 # Chaos Mesh experiments
│   ├── backup/                # Velero schedules
│   └── gitops/                # Flux v2 configuration
├── scripts/                   # PowerShell operational scripts
├── docs/                      # Documentation
└── wiki/                      # Wiki pages (this directory)
```

---

## Environment Comparison

| Setting | Dev | Lab | Prod |
|---------|-----|-----|------|
| Budget | ~$100/mo | ~$130/mo | Variable |
| Prometheus | OFF | ON | ON |
| Grafana | OFF | ON | ON |
| Defender | OFF | OFF | ON |
| KEDA | OFF | ON | ON |
| DNS Zone | OFF | ON | ON |
| Azure Files | OFF | ON | ON |
| Firewall | OFF | OFF | ON |

---

## Contributing

1. Create a feature branch from `main`
2. Make changes and test with `terraform plan -var-file="environments/dev.tfvars"`
3. Submit a pull request
4. CI runs `terraform fmt -check`, `terraform validate`, and `terraform plan`
