#Requires -Version 5.1
<#
.SYNOPSIS
    Destroy the AKS Landing Zone Lab infrastructure.

.DESCRIPTION
    Runs terraform destroy for the specified environment, checks for orphaned
    resources, and prints a cleanup summary.

.PARAMETER Environment
    Target environment (dev, lab, prod, staging). Default: dev.

.PARAMETER AutoApprove
    Skip confirmation prompt and destroy automatically.

.PARAMETER SkipOrphanCheck
    Skip the check for orphaned resources after destroy.

.EXAMPLE
    .\scripts\destroy.ps1 -Environment dev

.EXAMPLE
    .\scripts\destroy.ps1 -Environment lab -AutoApprove
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet("dev", "lab", "prod", "staging")]
    [string]$Environment = "dev",

    [Parameter()]
    [switch]$AutoApprove,

    [Parameter()]
    [switch]$SkipOrphanCheck
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Helpers ──────────────────────────────────────────────────────────────────

function Write-Info    { param([string]$Msg) Write-Host "[INFO]    $Msg" -ForegroundColor Cyan }
function Write-Success { param([string]$Msg) Write-Host "[OK]      $Msg" -ForegroundColor Green }
function Write-Warn    { param([string]$Msg) Write-Host "[WARN]    $Msg" -ForegroundColor Yellow }
function Write-Err     { param([string]$Msg) Write-Host "[ERROR]   $Msg" -ForegroundColor Red }

# ── Resolve paths ────────────────────────────────────────────────────────────

$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Definition
$rootDir    = Split-Path -Parent $scriptDir
$tfvarsFile = Join-Path $rootDir "environments\$Environment.tfvars"
$stateKey   = "aks-landing-zone-lab-$Environment.tfstate"

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Red
Write-Host "║          AKS Landing Zone Lab - DESTROY ($Environment)             ║" -ForegroundColor Red
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Red
Write-Host ""

# ── Validate tfvars ──────────────────────────────────────────────────────────

if (-not (Test-Path $tfvarsFile)) {
    Write-Err "Variable file not found: $tfvarsFile"
    exit 1
}

# ── Warning ──────────────────────────────────────────────────────────────────

Write-Warn "============================================================"
Write-Warn " WARNING: This will PERMANENTLY DELETE all resources in the"
Write-Warn "          '$Environment' environment."
Write-Warn ""
Write-Warn " Resources that will be destroyed include:"
Write-Warn "   - AKS cluster and node pools"
Write-Warn "   - Virtual networks (hub + spoke)"
Write-Warn "   - Azure Container Registry"
Write-Warn "   - Log Analytics workspace"
Write-Warn "   - All associated resource groups"
Write-Warn "   - Network security groups, route tables, etc."
Write-Warn "============================================================"
Write-Host ""

# ── Confirm ──────────────────────────────────────────────────────────────────

if (-not $AutoApprove) {
    $confirm = Read-Host "  Type 'destroy $Environment' to confirm"
    if ($confirm -ne "destroy $Environment") {
        Write-Warn "Destroy cancelled by user."
        exit 0
    }
}

# ── Terraform Destroy ────────────────────────────────────────────────────────

Write-Host ""
Write-Info "Running terraform destroy for '$Environment'..."
Write-Info "Using state key: $stateKey"

Push-Location $rootDir
try {
    terraform init -input=false -reconfigure -backend-config="key=$stateKey" 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Err "terraform init failed."
        exit 1
    }

    $destroyArgs = @("destroy", "-var-file=`"$tfvarsFile`"", "-input=false")
    if ($AutoApprove) {
        $destroyArgs += "-auto-approve"
    }

    terraform destroy -var-file="$tfvarsFile" -input=false -auto-approve:$AutoApprove.IsPresent
    if ($LASTEXITCODE -ne 0) {
        Write-Err "terraform destroy failed."
        Write-Warn "Some resources may still exist. Check the Azure portal."
        exit 1
    }

    Write-Success "terraform destroy completed."
    Write-Host ""

    # ── Check for orphaned resources ─────────────────────────────────────────

    if (-not $SkipOrphanCheck) {
        Write-Info "Checking for orphaned resources..."

        $projectName = "akslab"
        $tagFilter   = "project eq '$projectName' and environment eq '$Environment'"

        # Look for resource groups matching the naming convention
        $orphanedRGs = @()
        $expectedPatterns = @(
            "rg-hub-${projectName}-${Environment}",
            "rg-spoke-aks-${projectName}-${Environment}",
            "rg-management-${projectName}-${Environment}"
        )

        foreach ($pattern in $expectedPatterns) {
            $rgCheck = az group exists --name $pattern 2>$null
            if ($rgCheck -eq "true") {
                $orphanedRGs += $pattern
            }
        }

        # Also check for MC_ resource groups (AKS managed)
        $mcGroups = az group list --query "[?starts_with(name, 'MC_') && contains(name, '$projectName')].name" --output tsv 2>$null
        if ($mcGroups) {
            $mcGroups -split "`n" | Where-Object { $_ } | ForEach-Object {
                $orphanedRGs += $_
            }
        }

        if ($orphanedRGs.Count -gt 0) {
            Write-Warn "Found $($orphanedRGs.Count) potentially orphaned resource group(s):"
            foreach ($rg in $orphanedRGs) {
                Write-Warn "  - $rg"
            }
            Write-Host ""
            Write-Warn "To delete orphaned resource groups manually:"
            foreach ($rg in $orphanedRGs) {
                Write-Host "  az group delete --name $rg --yes --no-wait" -ForegroundColor Yellow
            }
        } else {
            Write-Success "No orphaned resource groups found."
        }
    }

    # ── Summary ──────────────────────────────────────────────────────────────

    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║          Destroy Complete                                    ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Environment:       $Environment" -ForegroundColor White
    Write-Host "  Status:            Destroyed" -ForegroundColor Green
    if (-not $SkipOrphanCheck) {
        Write-Host "  Orphaned RGs:      $($orphanedRGs.Count)" -ForegroundColor $(if ($orphanedRGs.Count -gt 0) { "Yellow" } else { "Green" })
    }
    Write-Host ""
    Write-Info "Terraform state backend (rg-terraform-state) was NOT deleted."
    Write-Info "To remove it:  az group delete --name rg-terraform-state --yes"
    Write-Host ""

} catch {
    Write-Err "Destroy failed: $_"
    exit 1
} finally {
    Pop-Location
}
