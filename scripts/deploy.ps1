#Requires -Version 5.1
<#
.SYNOPSIS
    Deploy the AKS Landing Zone Lab infrastructure with Terraform.

.DESCRIPTION
    Runs terraform init, plan, and (after confirmation) apply using the
    specified environment tfvars file. Prints Terraform outputs on success.

.PARAMETER Environment
    Target environment (dev, lab, prod, staging). Default: dev.

.PARAMETER AutoApprove
    Skip confirmation prompt and apply automatically.

.PARAMETER PlanOnly
    Only run terraform plan without applying.

.EXAMPLE
    .\scripts\deploy.ps1 -Environment dev

.EXAMPLE
    .\scripts\deploy.ps1 -Environment lab -AutoApprove

.EXAMPLE
    .\scripts\deploy.ps1 -Environment prod -PlanOnly
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet("dev", "lab", "prod", "staging")]
    [string]$Environment = "dev",

    [Parameter()]
    [switch]$AutoApprove,

    [Parameter()]
    [switch]$PlanOnly
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
$planFile   = Join-Path $rootDir "tfplan-$Environment"
$stateKey   = "aks-landing-zone-lab-$Environment.tfstate"

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          AKS Landing Zone Lab - Deploy ($Environment)              ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ── Validate tfvars ──────────────────────────────────────────────────────────

if (-not (Test-Path $tfvarsFile)) {
    Write-Err "Variable file not found: $tfvarsFile"
    Write-Err "Available environments:"
    Get-ChildItem (Join-Path $rootDir "environments") -Filter "*.tfvars" | ForEach-Object {
        Write-Err "  - $($_.BaseName)"
    }
    exit 1
}

Write-Info "Environment: $Environment"
Write-Info "Tfvars file: $tfvarsFile"
Write-Info "State key:  $stateKey"
Write-Host ""

# ── Terraform Init ───────────────────────────────────────────────────────────

Write-Info "Running terraform init..."
Push-Location $rootDir
try {
    terraform init -input=false -reconfigure -backend-config="key=$stateKey"
    if ($LASTEXITCODE -ne 0) {
        Write-Err "terraform init failed."
        exit 1
    }
    Write-Success "terraform init succeeded."
    Write-Host ""

    # ── Terraform Plan ───────────────────────────────────────────────────────

    Write-Info "Running terraform plan..."
    terraform plan -var-file="$tfvarsFile" -out="$planFile" -input=false
    if ($LASTEXITCODE -ne 0) {
        Write-Err "terraform plan failed."
        exit 1
    }
    Write-Success "terraform plan succeeded. Plan saved to: $planFile"
    Write-Host ""

    if ($PlanOnly) {
        Write-Info "PlanOnly mode - skipping apply."
        exit 0
    }

    # ── Confirm Apply ────────────────────────────────────────────────────────

    if (-not $AutoApprove) {
        Write-Warn "You are about to apply changes to the '$Environment' environment."
        $confirm = Read-Host "  Type 'yes' to continue"
        if ($confirm -ne "yes") {
            Write-Warn "Apply cancelled by user."
            exit 0
        }
    }

    # ── Terraform Apply ─────────────────────────────────────────────────────

    Write-Host ""
    Write-Info "Running terraform apply..."
    terraform apply -input=false "$planFile"
    if ($LASTEXITCODE -ne 0) {
        Write-Err "terraform apply failed."
        exit 1
    }
    Write-Success "terraform apply succeeded."
    Write-Host ""

    # ── Print Outputs ────────────────────────────────────────────────────────

    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║          Deployment Outputs                                  ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""

    $outputs = terraform output -json 2>$null | ConvertFrom-Json
    if ($outputs) {
        $outputs.PSObject.Properties | ForEach-Object {
            $name  = $_.Name
            $value = $_.Value.value
            if ($value) {
                Write-Host "  $($name): " -ForegroundColor White -NoNewline
                Write-Host "$value" -ForegroundColor Green
            }
        }
    }

    Write-Host ""
    Write-Info "Next step:  .\scripts\get-credentials.ps1 -Environment $Environment"
    Write-Host ""

} catch {
    Write-Err "Deployment failed: $_"
    exit 1
} finally {
    Pop-Location
    # Clean up plan file
    if (Test-Path $planFile) {
        Remove-Item $planFile -Force -ErrorAction SilentlyContinue
    }
}
