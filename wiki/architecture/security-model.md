# Security Model

## Defense-in-Depth Layers

The AKS Landing Zone Lab implements security across six layers, each providing independent protection:

```
  ┌────────────────────────────────────────────────────────┐
  │  Layer 1: Network Perimeter                          │
  │    NSGs per Subnet  ·  Azure Firewall (optional)      │
  ├────────────────────────────────────────────────────────┤
  │  Layer 2: Cluster Network                             │
  │    Calico Network Policies  ·  Default-Deny + Allows  │
  ├────────────────────────────────────────────────────────┤
  │  Layer 3: Pod Security                                │
  │    Pod Security Admission  ·  Resource Limits/Quotas  │
  ├────────────────────────────────────────────────────────┤
  │  Layer 4: Secrets Management                          │
  │    Azure Key Vault  ·  CSI Secrets Store Driver        │
  ├────────────────────────────────────────────────────────┤
  │  Layer 5: Governance                                  │
  │    Azure Policy  ·  Custom Policy Definitions          │
  ├────────────────────────────────────────────────────────┤
  │  Layer 6: Runtime Protection                          │
  │    Defender for Containers (opt)  ·  Audit Logging     │
  └────────────────────────────────────────────────────────┘
```

---

## Layer 1: Network Perimeter (NSGs + Firewall)

### Network Security Groups

Every subnet has a dedicated NSG with a default-deny-all inbound rule as the lowest priority. Only explicitly allowed traffic passes through.

| NSG | Allows Inbound | From |
|-----|----------------|------|
| nsg-aks-system-{env} | TCP 443 | VirtualNetwork |
| nsg-aks-user-{env} | TCP 80, 443 | VirtualNetwork |
| nsg-ingress-{env} | TCP 80, 443 | Internet |

### Azure Firewall (Optional)

When `enable_firewall = true`, all spoke egress routes through the hub firewall:

- **Network Rules**: Allow AKS required FQDN/IP ranges (Azure APIs, Ubuntu updates, MCR)
- **Application Rules**: Allow specific HTTPS targets
- **DNS Proxy**: Centralized DNS resolution and logging
- **Cost**: ~$900/month — OFF by default

---

## Layer 2: Cluster Network (Calico)

AKS uses Calico as the network policy engine, providing L3/L4 pod-level traffic segmentation.

### Default Policies

Every lab namespace has a `default-deny-all` policy that blocks all ingress and egress, followed by specific allow rules:

| Namespace | Policy | Effect |
|-----------|--------|--------|
| lab-apps | `default-deny-all` | Block all ingress/egress |
| lab-apps | `allow-dns-egress` | Allow UDP/TCP 53 for DNS |
| lab-apps | `allow-ingress-controller` | Allow from ingress-nginx namespace |
| lab-monitoring | `default-deny-all` | Block all ingress/egress |
| lab-monitoring | `allow-dns-egress` | Allow DNS |
| lab-security | `default-deny-all` | Block all ingress/egress |
| lab-security | `allow-dns-egress` | Allow DNS |

### Testing Network Isolation

```powershell
# Verify DNS works (should succeed)
kubectl exec -n lab-apps deploy/dns-test -- nslookup kubernetes.default

# Verify cross-namespace is blocked (should timeout)
kubectl run test -n lab-monitoring --image=busybox:1.36 --restart=Never \
  -- wget -qO- --timeout=5 http://hello-web.lab-apps.svc.cluster.local
```

---

## Layer 3: Pod Security (PSA)

Pod Security Admission enforces [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/) at the namespace level.

### Enforcement Levels

| Namespace | `enforce` | `audit` | `warn` |
|-----------|-----------|---------|--------|
| lab-apps | baseline | restricted | restricted |
| lab-monitoring | baseline | baseline | baseline |
| lab-security | restricted | restricted | restricted |

### What Each Level Blocks

| Control | `baseline` | `restricted` |
|---------|-----------|-------------|
| Privileged containers | Blocked | Blocked |
| Host networking | Blocked | Blocked |
| Host PID/IPC | Blocked | Blocked |
| HostPath volumes | Blocked | Blocked |
| Privilege escalation | Allowed | Blocked |
| Running as root | Allowed | Blocked |
| Non-core volume types | Allowed | Blocked |
| Seccomp profile required | No | Yes (RuntimeDefault) |

### Resource Quotas and Limit Ranges

Each namespace has resource quotas to prevent resource exhaustion:

```yaml
# Example quota for lab-apps
spec:
  hard:
    requests.cpu: "2"
    requests.memory: 4Gi
    limits.cpu: "4"
    limits.memory: 8Gi
    pods: "20"
```

Limit Ranges set default and maximum resource requests per container:

```yaml
spec:
  limits:
    - default:
        cpu: 200m
        memory: 256Mi
      defaultRequest:
        cpu: 50m
        memory: 64Mi
      type: Container
```

---

## Layer 4: Secrets Management (Key Vault + CSI)

### Architecture

```
Azure Key Vault (RBAC-enabled)
  ├── AKS kubelet identity has "Key Vault Secrets User" role
  │
  └── CSI Secrets Store Provider (DaemonSet)
        └── SecretProviderClass (per application)
              └── Pod mounts secrets as files at /mnt/secrets-store/
```

### Security Properties

| Property | Value |
|----------|-------|
| Authentication | Managed Identity (no stored credentials) |
| Authorization | Azure RBAC (Key Vault Secrets User role) |
| Encryption at rest | Azure-managed keys (AES-256) |
| Soft delete | Enabled (7-day retention) |
| Purge protection | Disabled (lab environment) |
| Network access | Public (lab environment) |
| Secret rotation | CSI driver polls every 2 minutes |

### Best Practices Implemented

- Secrets are **never stored in Kubernetes Secrets** — always in Key Vault
- Pods access secrets via **volume mounts** (files), not environment variables
- The AKS kubelet identity has **least-privilege** access (Secrets User, not Secrets Officer)
- Key Vault uses **RBAC authorization** (not legacy access policies)
- ACR admin is **disabled** — AKS authenticates via AcrPull managed identity role

---

## Layer 5: Governance (Azure Policy)

### Built-in Policy

| Policy | ID | Mode | Effect |
|--------|---|------|--------|
| Pod Security Baseline Standards | `a8640138-9b0a-4a28-b8cb-1666c838647d` | Audit | Reports non-compliant pods |

### Custom Policies

| Policy | Mode | Effect | Description |
|--------|------|--------|-------------|
| Deny Pods Without Resource Limits | Audit | Reports pods missing `resources.limits` | Ensures all pods have CPU and memory limits |
| Enforce ACR Image Source | Audit | Reports images not from project ACR | Prevents pulling from unknown registries |

### Compliance Checking

```powershell
# List all policy assignments on the cluster
$clusterId = az aks show -g rg-spoke-aks-networking-dev -n aks-akslab-dev --query id -o tsv
az policy assignment list --scope $clusterId -o table

# Check compliance state
az policy state summarize --resource $clusterId -o json
```

Azure Policy evaluates compliance every 15 minutes. Non-compliant resources are flagged but not blocked when the effect is `Audit`. Change to `Deny` for enforcement.

---

## Layer 6: Runtime Protection (Defender)

> Optional: `enable_defender = true` (+$7/node/month)

### Capabilities

| Feature | Description |
|---------|-------------|
| Runtime threat detection | Alerts on suspicious processes, file access, network connections |
| Image vulnerability scanning | Scans ACR images for known CVEs with severity ratings |
| Kubernetes audit analysis | Detects anomalous API server calls (e.g., exec into pod, secret access) |
| Binary drift detection | Alerts when executables not present at container start are run |
| Network threat detection | Identifies communication with known malicious IPs |

### Alert Categories

| Category | Example Alerts |
|----------|---------------|
| **Process** | Suspicious process executed in container; Web shell detected |
| **File** | Sensitive file access detected; Crypto mining binary identified |
| **Network** | Connection to known C2 server; DNS tunneling detected |
| **Kubernetes** | Service account token theft; Privileged container created |

---

## Identity Model

### Managed Identities

| Identity | Type | Scope | Purpose |
|----------|------|-------|---------|
| AKS Cluster Identity | System-Assigned | Cluster resource | Manage cluster infrastructure |
| AKS Kubelet Identity | System-Assigned | Node pool | Pull images from ACR, read Key Vault secrets |
| Workload Identity | User-Assigned | lab-apps namespace | Pods authenticate to Azure services without credentials |
| Metrics App Identity | User-Assigned | lab-apps namespace | Metrics app writes to Azure Storage |

### Workload Identity Flow

```
1. Pod starts with service account annotated with managed identity client ID
2. Azure AD token is projected into the pod at a well-known path
3. Pod exchanges the projected token for an Azure AD access token
4. Access token is used to call Azure APIs (Storage, Key Vault, etc.)
```

No credentials are stored in the cluster. The federated identity credential maps:
- **Issuer**: AKS OIDC issuer URL
- **Subject**: `system:serviceaccount:{namespace}:{service-account-name}`
- **Audience**: `api://AzureADTokenExchange`

### RBAC Configuration

| Role | Scope | Bound To | Purpose |
|------|-------|----------|---------|
| AcrPull | ACR | AKS kubelet identity | Pull container images |
| Key Vault Secrets User | Key Vault | AKS kubelet identity | Read secrets |
| Storage Blob Data Contributor | Storage Account | Metrics app identity | Write metrics data |
| Contributor | Subscription | Current user | Deploy infrastructure |

---

## Security Verification Checklist

Run these checks to verify the security posture:

```powershell
# 1. Verify network policies
kubectl get networkpolicies -A
# Expected: default-deny + allow rules per namespace

# 2. Verify PSA labels
kubectl get ns lab-apps -o jsonpath='{.metadata.labels}' | ConvertFrom-Json
# Expected: pod-security.kubernetes.io/enforce: baseline

# 3. Verify Key Vault exists and RBAC is enabled
az keyvault list --query "[?tags.project=='akslab'].{Name:name, RBAC:properties.enableRbacAuthorization}" -o table

# 4. Verify ACR admin is disabled
az acr show -n $(terraform output -raw acr_login_server | ForEach-Object { $_.Split('.')[0] }) --query adminUserEnabled -o tsv
# Expected: false

# 5. Verify RBAC is enabled on AKS
az aks show -g rg-spoke-aks-networking-dev -n aks-akslab-dev --query aadProfile -o json

# 6. Verify Calico is the network policy engine
az aks show -g rg-spoke-aks-networking-dev -n aks-akslab-dev --query networkProfile.networkPolicy -o tsv
# Expected: calico

# 7. Verify Azure Policy assignments
az policy assignment list --scope $(az aks show -g rg-spoke-aks-networking-dev -n aks-akslab-dev --query id -o tsv) --query "[].displayName" -o tsv
```
