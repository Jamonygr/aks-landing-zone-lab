<div align="center">
  <img src="../images/guide-security.svg" alt="Security Guide" width="900"/>
</div>

<div align="center">

[![Calico](https://img.shields.io/badge/Network_Policy-Calico-blue?style=for-the-badge)](.)
[![PSA](https://img.shields.io/badge/Pod_Security-Admission-green?style=for-the-badge)](.)
[![Key Vault](https://img.shields.io/badge/Secrets-Key_Vault-purple?style=for-the-badge)](.)

</div>

# 🔒 Security Guide

Hands-on security validation for the current AKS lab setup.

---

## 1. Network Policy Validation

Apply policies:

```powershell
kubectl apply -f k8s/security/network-policies.yaml
kubectl get networkpolicies -A
```

Expected policy coverage:
- `lab-apps`: deny-all, DNS egress, ingress controller allow, DB egress allow
- `lab-monitoring`: deny-all, DNS egress, monitoring egress allow
- `lab-ingress`: deny-all, DNS egress, backend egress allow, external ingress allow
- `lab-security`: deny-all, DNS egress

Quick checks:

```powershell
# DNS should work from a restricted namespace
kubectl run dns-test -n lab-apps --image=busybox:1.36 --restart=Never -- nslookup kubernetes.default
kubectl logs -n lab-apps dns-test
kubectl delete pod -n lab-apps dns-test

# Cross-namespace call should fail without explicit allow from source namespace
kubectl run cross-ns-test -n lab-monitoring --image=busybox:1.36 --restart=Never -- wget -qO- --timeout=5 http://hello-web.lab-apps.svc.cluster.local
kubectl logs -n lab-monitoring cross-ns-test
kubectl delete pod -n lab-monitoring cross-ns-test
```

---

## 2. Pod Security Admission (PSA)

Apply PSA namespace labels:

```powershell
kubectl apply -f k8s/security/pod-security-admission.yaml
kubectl get ns lab-apps --show-labels
kubectl get ns lab-monitoring --show-labels
```

Current enforcement:
- `lab-apps`: `restricted`
- `lab-monitoring`: `baseline`

Test restricted enforcement:

```powershell
kubectl run priv-test -n lab-apps --image=nginx:alpine --restart=Never --overrides='{
  "spec": {
    "containers": [{
      "name": "priv-test",
      "image": "nginx:alpine",
      "securityContext": { "privileged": true }
    }]
  }
}'
```

Expected: rejected by PSA in `lab-apps`.

---

## 3. Key Vault + CSI Secrets Store

Security landing zone deploys:
- Key Vault (RBAC-enabled)
- CSI Secrets Store driver
- Azure provider for CSI

Check outputs:

```powershell
terraform output key_vault_name
terraform output key_vault_uri
terraform output workload_identity_client_id
terraform output tenant_id
```

Deploy sample consumer:

```powershell
kubectl apply -f k8s/apps/secret-consumer.yaml
kubectl get pod -n lab-apps secret-consumer
kubectl logs -n lab-apps secret-consumer
```

Important:
- `k8s/apps/secret-consumer.yaml` requires filling `userAssignedIdentityID`, `keyvaultName`, and `tenantId` before it can pull real Key Vault secrets.

---

## 4. Azure Policy And Governance

Check AKS-scoped assignments:

```powershell
$clusterId = az aks show -g rg-spoke-aks-networking-dev -n aks-akslab-dev --query id -o tsv
az policy assignment list --scope $clusterId -o table
```

Expected assignment intent:
- Pod Security Baseline (built-in initiative)
- Custom policy for resource limits
- Custom policy for ACR image source

All current assignments are configured in `Audit` effect.

---

## 5. Defender For Containers (Optional)

Enable via env tfvars:

```hcl
enable_defender = true
```

Apply:

```powershell
.\scripts\deploy.ps1 -Environment prod
```

Then review alerts in Defender for Cloud.

---

## 6. Security Checklist

- Network policies applied and active in all lab namespaces
- PSA labels present for `lab-apps` and `lab-monitoring`
- Key Vault reachable through configured identities
- Policy assignments visible at AKS scope
- ACR admin disabled
- Optional Defender enabled only when needed

---

<div align="center">

**[⬅ Wiki Home](../README.md)** · **[Architecture Security Model](../architecture/security-model.md)**

</div>
