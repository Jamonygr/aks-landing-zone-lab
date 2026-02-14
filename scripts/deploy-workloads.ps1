#Requires -Version 5.1
<#
.SYNOPSIS
    Deploy Kubernetes workloads to the AKS cluster.

.DESCRIPTION
    Applies all K8s manifests from the k8s/ directory in a logical order:
    namespaces -> security -> storage -> apps -> monitoring -> autoscaling.
    Waits for deployments to become ready and prints a status summary.

.PARAMETER ManifestRoot
    Root directory containing K8s manifests. Default: k8s/ relative to repo root.

.PARAMETER Namespace
    Override namespace for all manifests. If omitted, uses namespace in manifests.

.PARAMETER DryRun
    Perform a dry-run without actually applying.

.PARAMETER WaitTimeout
    Timeout in seconds for waiting on deployments. Default: 120.

.EXAMPLE
    .\scripts\deploy-workloads.ps1

.EXAMPLE
    .\scripts\deploy-workloads.ps1 -DryRun

.EXAMPLE
    .\scripts\deploy-workloads.ps1 -WaitTimeout 300
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$ManifestRoot,

    [Parameter()]
    [string]$Namespace,

    [Parameter()]
    [switch]$DryRun,

    [Parameter()]
    [int]$WaitTimeout = 120
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Helpers ──────────────────────────────────────────────────────────────────

function Write-Info    { param([string]$Msg) Write-Host "[INFO]    $Msg" -ForegroundColor Cyan }
function Write-Success { param([string]$Msg) Write-Host "[OK]      $Msg" -ForegroundColor Green }
function Write-Warn    { param([string]$Msg) Write-Host "[WARN]    $Msg" -ForegroundColor Yellow }
function Write-Err     { param([string]$Msg) Write-Host "[ERROR]   $Msg" -ForegroundColor Red }

# ── Resolve paths ────────────────────────────────────────────────────────────

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$rootDir   = Split-Path -Parent $scriptDir

if (-not $ManifestRoot) {
    $ManifestRoot = Join-Path $rootDir "k8s"
}

if (-not (Test-Path $ManifestRoot)) {
    Write-Err "Manifest directory not found: $ManifestRoot"
    exit 1
}

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          AKS Landing Zone Lab - Deploy Workloads            ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Warn "DRY RUN mode - no changes will be applied."
    Write-Host ""
}

# ── Verify kubectl works ────────────────────────────────────────────────────

Write-Info "Verifying kubectl connection..."
try {
    kubectl cluster-info 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "kubectl not connected" }
    Write-Success "Connected to cluster: $(kubectl config current-context 2>$null)"
} catch {
    Write-Err "Cannot connect to Kubernetes cluster."
    Write-Err "Run .\scripts\get-credentials.ps1 first."
    exit 1
}
Write-Host ""

# ── Define apply order ──────────────────────────────────────────────────────

$applyOrder = @(
    @{ Name = "Namespaces";  Path = "namespaces"  }
    @{ Name = "Security";    Path = "security"    }
    @{ Name = "Storage";     Path = "storage"     }
    @{ Name = "Apps";        Path = "apps"        }
    @{ Name = "Monitoring";  Path = "monitoring"  }
    @{ Name = "Autoscaling"; Path = "autoscaling" }
)

$results = @()

foreach ($stage in $applyOrder) {
    $stageDir = Join-Path $ManifestRoot $stage.Path

    if (-not (Test-Path $stageDir)) {
        Write-Warn "Skipping '$($stage.Name)' - directory not found: $stageDir"
        $results += @{ Stage = $stage.Name; Status = "Skipped"; Files = 0 }
        continue
    }

    $yamlFiles = Get-ChildItem -Path $stageDir -Filter "*.yaml" -File | Sort-Object Name
    if ($yamlFiles.Count -eq 0) {
        Write-Warn "Skipping '$($stage.Name)' - no YAML files found."
        $results += @{ Stage = $stage.Name; Status = "Skipped"; Files = 0 }
        continue
    }

    Write-Info "Applying $($stage.Name) ($($yamlFiles.Count) file(s))..."

    $stageSuccess = $true
    foreach ($file in $yamlFiles) {
        $applyArgs = @("apply", "-f", $file.FullName)

        if ($Namespace) {
            $applyArgs += @("--namespace", $Namespace)
        }

        if ($DryRun) {
            $applyArgs += "--dry-run=client"
        }

        try {
            $output = kubectl @applyArgs 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Err "  Failed: $($file.Name)"
                Write-Err "  $output"
                $stageSuccess = $false
            } else {
                $output -split "`n" | Where-Object { $_ } | ForEach-Object {
                    Write-Host "    $_" -ForegroundColor Gray
                }
            }
        } catch {
            Write-Err "  Exception applying $($file.Name): $_"
            $stageSuccess = $false
        }
    }

    if ($stageSuccess) {
        Write-Success "  $($stage.Name) applied successfully."
        $results += @{ Stage = $stage.Name; Status = "Applied"; Files = $yamlFiles.Count }
    } else {
        Write-Warn "  $($stage.Name) had errors."
        $results += @{ Stage = $stage.Name; Status = "Errors"; Files = $yamlFiles.Count }
    }
    Write-Host ""
}

# ── Wait for deployments ────────────────────────────────────────────────────

if (-not $DryRun) {
    Write-Info "Waiting for deployments to be ready (timeout: ${WaitTimeout}s)..."
    Write-Host ""

    try {
        $deployments = kubectl get deployments --all-namespaces --output json 2>$null | ConvertFrom-Json
        if ($deployments -and $deployments.items.Count -gt 0) {
            $allReady = $true
            foreach ($dep in $deployments.items) {
                $depName = $dep.metadata.name
                $depNs   = $dep.metadata.namespace

                # Skip kube-system deployments
                if ($depNs -eq "kube-system") { continue }

                Write-Info "  Waiting for $depNs/$depName..."
                kubectl rollout status deployment/$depName -n $depNs --timeout="${WaitTimeout}s" 2>$null
                if ($LASTEXITCODE -ne 0) {
                    Write-Warn "  $depNs/$depName not ready within timeout."
                    $allReady = $false
                } else {
                    Write-Success "  $depNs/$depName is ready."
                }
            }

            if ($allReady) {
                Write-Success "All deployments are ready."
            } else {
                Write-Warn "Some deployments did not become ready within the timeout."
            }
        } else {
            Write-Info "No deployments found to wait for."
        }
    } catch {
        Write-Warn "Could not check deployment status: $_"
    }
}

# ── Status summary ──────────────────────────────────────────────────────────

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║          Workload Deployment Summary                         ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

foreach ($result in $results) {
    $statusColor = switch ($result.Status) {
        "Applied"  { "Green" }
        "Skipped"  { "Yellow" }
        "Errors"   { "Red" }
        default    { "White" }
    }
    Write-Host "  $($result.Stage.PadRight(14))" -NoNewline -ForegroundColor White
    Write-Host "$($result.Status.PadRight(10))" -NoNewline -ForegroundColor $statusColor
    Write-Host "($($result.Files) files)" -ForegroundColor Gray
}

Write-Host ""

if (-not $DryRun) {
    Write-Info "Quick checks:"
    Write-Host "  kubectl get pods --all-namespaces" -ForegroundColor Gray
    Write-Host "  kubectl get svc --all-namespaces" -ForegroundColor Gray
    Write-Host "  kubectl get ingress --all-namespaces" -ForegroundColor Gray
}

Write-Host ""
