#Requires -Version 5.1
<#
.SYNOPSIS
    Check current Azure costs for the AKS Landing Zone Lab.

.DESCRIPTION
    Queries Azure Cost Management for the current billing period, shows
    a breakdown by resource group, compares against the configured budget,
    and prints a color-coded cost summary.

.PARAMETER Environment
    Target environment (dev, lab, prod, staging). Default: dev.

.PARAMETER BudgetAmount
    Monthly budget threshold in USD. Default: read from tfvars or 100.

.PARAMETER SubscriptionId
    Azure subscription ID. If omitted, uses the current default.

.EXAMPLE
    .\scripts\cost-check.ps1

.EXAMPLE
    .\scripts\cost-check.ps1 -Environment lab -BudgetAmount 130

.EXAMPLE
    .\scripts\cost-check.ps1 -SubscriptionId "00000000-0000-0000-0000-000000000000"
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet("dev", "lab", "prod", "staging")]
    [string]$Environment = "dev",

    [Parameter()]
    [double]$BudgetAmount = 0,

    [Parameter()]
    [string]$SubscriptionId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Helpers ──────────────────────────────────────────────────────────────────

function Write-Info    { param([string]$Msg) Write-Host "[INFO]    $Msg" -ForegroundColor Cyan }
function Write-Success { param([string]$Msg) Write-Host "[OK]      $Msg" -ForegroundColor Green }
function Write-Warn    { param([string]$Msg) Write-Host "[WARN]    $Msg" -ForegroundColor Yellow }
function Write-Err     { param([string]$Msg) Write-Host "[ERROR]   $Msg" -ForegroundColor Red }

# ── Resolve budget from tfvars if not specified ──────────────────────────────

$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Definition
$rootDir    = Split-Path -Parent $scriptDir
$tfvarsFile = Join-Path $rootDir "environments\$Environment.tfvars"

if ($BudgetAmount -le 0 -and (Test-Path $tfvarsFile)) {
    $budgetLine = Get-Content $tfvarsFile | Where-Object { $_ -match '^\s*budget_amount\s*=' }
    if ($budgetLine) {
        $parsed = ($budgetLine -replace '.*=\s*', '' -replace '#.*', '').Trim()
        $BudgetAmount = [double]$parsed
        Write-Info "Budget loaded from $Environment.tfvars: `$$BudgetAmount"
    }
}

if ($BudgetAmount -le 0) {
    $BudgetAmount = 100
    Write-Info "Using default budget: `$$BudgetAmount"
}

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          AKS Landing Zone Lab - Cost Check                  ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ── Get subscription info ────────────────────────────────────────────────────

if ($SubscriptionId) {
    az account set --subscription $SubscriptionId 2>$null
}

$account = az account show --output json 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Err "Not logged in to Azure. Run 'az login' first."
    exit 1
}

$subId   = $account.id
$subName = $account.name

Write-Info "Subscription: $subName ($subId)"
Write-Info "Environment:  $Environment"
Write-Info "Budget:        `$$BudgetAmount/month"
Write-Host ""

# ── Date range for current month ─────────────────────────────────────────────

$today      = Get-Date
$startDate  = Get-Date -Year $today.Year -Month $today.Month -Day 1 -Hour 0 -Minute 0 -Second 0
$endDate    = $today
$daysInMonth = [DateTime]::DaysInMonth($today.Year, $today.Month)
$daysPassed  = $today.Day

$startStr = $startDate.ToString("yyyy-MM-dd")
$endStr   = $endDate.ToString("yyyy-MM-dd")

Write-Info "Period: $startStr to $endStr ($daysPassed of $daysInMonth days)"
Write-Host ""

# ── Query Cost Management API ───────────────────────────────────────────────

Write-Info "Querying Azure Cost Management..."

$projectName = "akslab"
$rgPatterns = @(
    "rg-hub-${projectName}-${Environment}",
    "rg-spoke-aks-${projectName}-${Environment}",
    "rg-management-${projectName}-${Environment}",
    "rg-terraform-state"
)

$totalCost = 0.0
$rgCosts = @()

foreach ($rg in $rgPatterns) {
    try {
        $rgExists = az group exists --name $rg 2>$null
        if ($rgExists -ne "true") {
            $rgCosts += @{ Name = $rg; Cost = 0.0; Status = "Not Found" }
            continue
        }

        # Query cost for this resource group
        $costData = az consumption usage list `
            --start-date $startStr `
            --end-date $endStr `
            --query "[?contains(instanceId, '$rg')].pretaxCost" `
            --output json 2>$null | ConvertFrom-Json

        $rgTotal = 0.0
        if ($costData) {
            foreach ($cost in $costData) {
                $rgTotal += [double]$cost
            }
        }

        $totalCost += $rgTotal
        $rgCosts += @{ Name = $rg; Cost = $rgTotal; Status = "OK" }

    } catch {
        # Fallback: try costmanagement query
        Write-Warn "  Could not query costs for $rg via consumption API."

        try {
            $scope = "/subscriptions/$subId/resourceGroups/$rg"
            $body = @{
                type = "ActualCost"
                timeframe = "Custom"
                timePeriod = @{
                    from = $startStr
                    to   = $endStr
                }
                dataset = @{
                    granularity = "None"
                    aggregation = @{
                        totalCost = @{
                            name     = "Cost"
                            function = "Sum"
                        }
                    }
                }
            } | ConvertTo-Json -Depth 10

            $result = az rest --method post `
                --url "https://management.azure.com${scope}/providers/Microsoft.CostManagement/query?api-version=2023-03-01" `
                --body $body `
                --output json 2>$null | ConvertFrom-Json

            $rgTotal = 0.0
            if ($result -and $result.properties -and $result.properties.rows) {
                foreach ($row in $result.properties.rows) {
                    $rgTotal += [double]$row[0]
                }
            }

            $totalCost += $rgTotal
            $rgCosts += @{ Name = $rg; Cost = $rgTotal; Status = "OK" }
        } catch {
            Write-Warn "  Cost data unavailable for $rg"
            $rgCosts += @{ Name = $rg; Cost = 0.0; Status = "Error" }
        }
    }
}

# ── Also check for MC_ (AKS managed) resource groups ────────────────────────

try {
    $mcGroups = az group list --query "[?starts_with(name, 'MC_') && contains(name, '$projectName')].name" --output tsv 2>$null
    if ($mcGroups) {
        $mcGroups -split "`n" | Where-Object { $_.Trim() } | ForEach-Object {
            $mcRg = $_.Trim()
            try {
                $scope = "/subscriptions/$subId/resourceGroups/$mcRg"
                $body = @{
                    type = "ActualCost"
                    timeframe = "Custom"
                    timePeriod = @{ from = $startStr; to = $endStr }
                    dataset = @{
                        granularity = "None"
                        aggregation = @{
                            totalCost = @{ name = "Cost"; function = "Sum" }
                        }
                    }
                } | ConvertTo-Json -Depth 10

                $result = az rest --method post `
                    --url "https://management.azure.com${scope}/providers/Microsoft.CostManagement/query?api-version=2023-03-01" `
                    --body $body --output json 2>$null | ConvertFrom-Json

                $mcCost = 0.0
                if ($result -and $result.properties -and $result.properties.rows) {
                    foreach ($row in $result.properties.rows) { $mcCost += [double]$row[0] }
                }
                $totalCost += $mcCost
                $rgCosts += @{ Name = $mcRg; Cost = $mcCost; Status = "OK (managed)" }
            } catch {
                $rgCosts += @{ Name = $mcRg; Cost = 0.0; Status = "Error" }
            }
        }
    }
} catch { }

# ── Projected cost ───────────────────────────────────────────────────────────

$projectedCost = if ($daysPassed -gt 0) { ($totalCost / $daysPassed) * $daysInMonth } else { 0.0 }
$budgetPct     = if ($BudgetAmount -gt 0) { ($projectedCost / $BudgetAmount) * 100 } else { 0 }

# ── Print cost breakdown ────────────────────────────────────────────────────

Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║          Cost Breakdown by Resource Group                    ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

foreach ($rgInfo in $rgCosts) {
    $costStr = if ($rgInfo.Status -eq "Not Found") {
        "(not found)"
    } elseif ($rgInfo.Status -eq "Error") {
        "(error)"
    } else {
        "`${0:N2}" -f $rgInfo.Cost
    }

    $color = switch -Wildcard ($rgInfo.Status) {
        "Not Found" { "Gray" }
        "Error"     { "Red" }
        default     { if ($rgInfo.Cost -gt 0) { "White" } else { "Gray" } }
    }

    Write-Host "  $($rgInfo.Name.PadRight(45))" -NoNewline -ForegroundColor White
    Write-Host "$costStr" -ForegroundColor $color
}

Write-Host ""
Write-Host "  $("─" * 58)" -ForegroundColor Gray

# ── Summary ──────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "  Current MTD Spend:   " -NoNewline -ForegroundColor White
Write-Host ("`${0:N2}" -f $totalCost) -ForegroundColor Cyan

Write-Host "  Projected Monthly:   " -NoNewline -ForegroundColor White
$projColor = if ($projectedCost -gt $BudgetAmount) { "Red" } elseif ($projectedCost -gt ($BudgetAmount * 0.8)) { "Yellow" } else { "Green" }
Write-Host ("`${0:N2}" -f $projectedCost) -ForegroundColor $projColor

Write-Host "  Budget:              " -NoNewline -ForegroundColor White
Write-Host ("`${0:N2}" -f $BudgetAmount) -ForegroundColor White

Write-Host "  Budget Utilization:  " -NoNewline -ForegroundColor White
$pctColor = if ($budgetPct -gt 100) { "Red" } elseif ($budgetPct -gt 80) { "Yellow" } else { "Green" }
Write-Host ("{0:N1}%" -f $budgetPct) -ForegroundColor $pctColor

Write-Host ""

# Status message
if ($projectedCost -gt $BudgetAmount) {
    Write-Err "OVER BUDGET - Projected spend exceeds budget by `$$(("{0:N2}" -f ($projectedCost - $BudgetAmount)))!"
    Write-Warn "Consider:"
    Write-Warn "  - Stopping the cluster:  .\scripts\stop-lab.ps1"
    Write-Warn "  - Reducing node counts in $Environment.tfvars"
    Write-Warn "  - Disabling optional features (firewall, grafana, etc.)"
} elseif ($projectedCost -gt ($BudgetAmount * 0.8)) {
    Write-Warn "APPROACHING BUDGET - Projected spend is at $("{0:N0}" -f $budgetPct)% of budget."
    Write-Warn "Monitor usage and consider stopping cluster when not in use."
} else {
    Write-Success "WITHIN BUDGET - Spending is on track."
}

Write-Host ""
Write-Info "Tip: Stop the cluster when not in use to save costs:"
Write-Host "  .\scripts\stop-lab.ps1 -Environment $Environment" -ForegroundColor Gray
Write-Host ""
