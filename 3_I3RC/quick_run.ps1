#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Quick I3RC simulation runner for common configurations
.DESCRIPTION
    Simplified script to run common I3RC configurations with predefined settings
.PARAMETER Config
    Configuration to run: "thin" (thin_cloud), "thick" (cloud), "clear" (clear_sky)
.EXAMPLE
    .\quick_run.ps1 -Config "thin"
    .\quick_run.ps1 -Config "thick"
    .\quick_run.ps1 -Config "clear"
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("thin", "thick", "clear")]
    [string]$Config
)

# Map short names to full configuration names
$configMap = @{
    "thin" = "thin_cloud"
    "thick" = "cloud" 
    "clear" = "clear_sky"
}

$configName = $configMap[$Config]

Write-Host "Running I3RC simulation with $Config cloud configuration..." -ForegroundColor Cyan

# Check if main script exists
$mainScript = "C:\Users\PC\Documents\GitHub\I3RC\run_i3rc_simulation.ps1"
if (-not (Test-Path $mainScript)) {
    Write-Error "Main simulation script not found: $mainScript"
}

# Run the main script
& $mainScript -ConfigName $configName -NumPhotons 50 -NumBatches 50
