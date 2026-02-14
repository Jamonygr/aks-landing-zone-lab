#Requires -Version 5.1
<#
.SYNOPSIS
    Bootstrap the AKS Landing Zone Lab environment.

.DESCRIPTION
    Checks and installs prerequisites (az cli, terraform, kubectl, helm, git),
    logs in to Azure, creates the Terraform remote state backend (resource group,
    storage account, blob container), sets the active subscription, and prints
    a configuration summary.

.PARAMETER SubscriptionId
    Azure subscription ID to use. If omitted, the current default is kept.

.PARAMETER Location
    Azure region for the Terraform state resources. Default: eastus.

.PARAMETER StateResourceGroup
    Resource group name for Terraform state. Default: rg-terraform-state.

.PARAMETER StateStorageAccount
    Storage account name for Terraform state. Default: stakslabtfstate.

.PARAMETER StateContainer
    Blob container name for Terraform state. Default: tfstate.

.EXAMPLE
    .\scripts\bootstrap.ps1

.EXAMPLE
    .\scripts\bootstrap.ps1 -SubscriptionId "00000000-0000-0000-0000-000000000000" -Location "westus2"
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$SubscriptionId,

    [Parameter()]
    [string]$Location = "eastus",

    [Parameter()]
    [string]$StateResourceGroup = "rg-terraform-state",

    [Parameter()]
    [string]$StateStorageAccount = "stakslabtfstate",

    [Parameter()]
    [string]$StateContainer = "tfstate"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Helpers ──────────────────────────────────────────────────────────────────

function Write-Info    { param([string]$Msg) Write-Host "[INFO]    $Msg" -ForegroundColor Cyan }
function Write-Success { param([string]$Msg) Write-Host "[OK]      $Msg" -ForegroundColor Green }
function Write-Warn    { param([string]$Msg) Write-Host "[WARN]    $Msg" -ForegroundColor Yellow }
function Write-Err     { param([string]$Msg) Write-Host "[ERROR]   $Msg" -ForegroundColor Red }

function Test-Command {
    param([string]$Name)
    $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

# ── 1. Check / install prerequisites ────────────────────────────────────────

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          AKS Landing Zone Lab - Bootstrap                   ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$prerequisites = @(
    @{ Name = "az";        DisplayName = "Azure CLI";   InstallHint = "https://aka.ms/installazurecliwindows  or  winget install Microsoft.AzureCLI" }
    @{ Name = "terraform"; DisplayName = "Terraform";   InstallHint = "https://developer.hashicorp.com/terraform/install  or  winget install Hashicorp.Terraform" }
    @{ Name = "kubectl";   DisplayName = "kubectl";     InstallHint = "az aks install-cli  or  winget install Kubernetes.kubectl" }
    @{ Name = "helm";      DisplayName = "Helm";        InstallHint = "https://helm.sh/docs/intro/install/  or  winget install Helm.Helm" }
    @{ Name = "git";       DisplayName = "Git";         InstallHint = "https://git-scm.com/download/win  or  winget install Git.Git" }
)

$missing = @()

foreach ($tool in $prerequisites) {
    if (Test-Command $tool.Name) {
        $version = try { & $tool.Name version 2>$null } catch { "" }
        if (-not $version) { $version = try { & $tool.Name --version 2>$null } catch { "installed" } }
        Write-Success "$($tool.DisplayName) found  ($version)"
    } else {
        Write-Err "$($tool.DisplayName) NOT found"
        Write-Warn "  Install: $($tool.InstallHint)"
        $missing += $tool.DisplayName
    }
}

if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Err "Missing prerequisites: $($missing -join ', ')"
    Write-Err "Install the missing tools and re-run this script."
    exit 1
}

Write-Host ""
Write-Success "All prerequisites satisfied."
Write-Host ""

# ── 2. Azure Login ──────────────────────────────────────────────────────────

Write-Info "Checking Azure login status..."

$account = $null
try {
    $account = az account show --output json 2>$null | ConvertFrom-Json
} catch { }

if (-not $account) {
    Write-Info "Not logged in. Launching 'az login'..."
    az login --output none
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Azure login failed."
        exit 1
    }
    $account = az account show --output json | ConvertFrom-Json
}

Write-Success "Logged in as: $($account.user.name)"
Write-Info "Current subscription: $($account.name) ($($account.id))"

# ── 3. Set subscription ─────────────────────────────────────────────────────

if ($SubscriptionId) {
    Write-Info "Setting subscription to $SubscriptionId..."
    az account set --subscription $SubscriptionId
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Failed to set subscription."
        exit 1
    }
    $account = az account show --output json | ConvertFrom-Json
    Write-Success "Subscription set: $($account.name) ($($account.id))"
}

# ── 4. Create Terraform state backend ───────────────────────────────────────

Write-Host ""
Write-Info "Provisioning Terraform remote-state backend..."

# Resource group
Write-Info "  Creating resource group '$StateResourceGroup' in '$Location'..."
$rgExists = az group exists --name $StateResourceGroup 2>$null
if ($rgExists -eq "true") {
    Write-Warn "  Resource group '$StateResourceGroup' already exists - skipping."
} else {
    az group create --name $StateResourceGroup --location $Location --output none
    if ($LASTEXITCODE -ne 0) { Write-Err "Failed to create resource group."; exit 1 }
    Write-Success "  Resource group created."
}

# Storage account
Write-Info "  Creating storage account '$StateStorageAccount'..."
$saCheck = az storage account show --name $StateStorageAccount --resource-group $StateResourceGroup --output json 2>$null
if ($saCheck) {
    Write-Warn "  Storage account '$StateStorageAccount' already exists - skipping."
} else {
    az storage account create `
        --name $StateStorageAccount `
        --resource-group $StateResourceGroup `
        --location $Location `
        --sku Standard_LRS `
        --kind StorageV2 `
        --min-tls-version TLS1_2 `
        --allow-blob-public-access false `
        --output none
    if ($LASTEXITCODE -ne 0) { Write-Err "Failed to create storage account."; exit 1 }
    Write-Success "  Storage account created."
}

# Blob container
Write-Info "  Creating blob container '$StateContainer'..."
$containerCheck = az storage container exists `
    --name $StateContainer `
    --account-name $StateStorageAccount `
    --auth-mode login `
    --output json 2>$null | ConvertFrom-Json

if ($containerCheck -and $containerCheck.exists -eq $true) {
    Write-Warn "  Blob container '$StateContainer' already exists - skipping."
} else {
    az storage container create `
        --name $StateContainer `
        --account-name $StateStorageAccount `
        --auth-mode login `
        --output none
    if ($LASTEXITCODE -ne 0) { Write-Err "Failed to create blob container."; exit 1 }
    Write-Success "  Blob container created."
}

# ── 5. Summary ──────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║          Bootstrap Complete                                  ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  Subscription:      $($account.name)" -ForegroundColor White
Write-Host "  Subscription ID:   $($account.id)" -ForegroundColor White
Write-Host "  Tenant ID:         $($account.tenantId)" -ForegroundColor White
Write-Host "  State RG:          $StateResourceGroup" -ForegroundColor White
Write-Host "  State Storage:     $StateStorageAccount" -ForegroundColor White
Write-Host "  State Container:   $StateContainer" -ForegroundColor White
Write-Host "  Location:          $Location" -ForegroundColor White
Write-Host ""
Write-Info "Next step:  .\scripts\deploy.ps1 -Environment dev"
Write-Host ""
