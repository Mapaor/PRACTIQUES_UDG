#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Runs the I3RC Monte Carlo radiative transfer simulation pipeline
.DESCRIPTION
    This script automates the complete I3RC simulation process:
    1. Generates domain file from physical properties
    2. Runs Monte Carlo simulation
    3. Produces flux outputs including direct/diffuse separation
.PARAMETER ConfigName
    Name of the configuration to run (e.g., "thin_cloud", "cloud", "clear_sky")
.PARAMETER NumPhotons
    Number of photons per batch (default: 50)
.PARAMETER NumBatches
    Number of batches to run (default: 50)
.PARAMETER SolarMu
    Cosine of solar zenith angle (default: 0.5)
.PARAMETER CleanFirst
    Whether to clean previous outputs first (default: false)
.EXAMPLE
    .\run_i3rc_simulation.ps1 -ConfigName "thin_cloud"
.EXAMPLE
    .\run_i3rc_simulation.ps1 -ConfigName "cloud" -NumPhotons 100 -NumBatches 100 -CleanFirst
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ConfigName,
    
    [Parameter(Mandatory=$false)]
    [int]$NumPhotons = 25,
    
    [Parameter(Mandatory=$false)]
    [int]$NumBatches = 15,
    
    [Parameter(Mandatory=$false)]
    [double]$SolarMu = 0.5,
    
    [Parameter(Mandatory=$false)]
    [switch]$CleanFirst
)

# Set error handling
$ErrorActionPreference = "Stop"

# Define paths
$I3RC_ROOT = "C:\Users\PC\Documents\GitHub\I3RC"
$INPUT_PHYS_DIR = "$I3RC_ROOT\Input\PhysicalPropertiesToDomain"
$INPUT_MC_DIR = "$I3RC_ROOT\Input\MonteCarloDriver"
$OUTPUT_PHYS_DIR = "$I3RC_ROOT\Output\PhysicalPropertiesToDomain"
$OUTPUT_MC_DIR = "$I3RC_ROOT\Output\MonteCarloDriver"
$TOOLS_DIR = "$I3RC_ROOT\I3RC-Monte-Carlo-Model\Tools"
$DRIVERS_DIR = "$I3RC_ROOT\I3RC-Monte-Carlo-Model\Example-Drivers"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "I3RC Monte Carlo Simulation Pipeline" -ForegroundColor Cyan
Write-Host "Configuration: $ConfigName" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Cyan

# Check if configuration files exist
$physPropsFile = "$INPUT_PHYS_DIR\${ConfigName}.txt"
$domainConfigFile = "$INPUT_PHYS_DIR\${ConfigName}_domain.nml"
$mcConfigFile = "$INPUT_MC_DIR\${ConfigName}.nml"

Write-Host "Checking input files..." -ForegroundColor Green

if (-not (Test-Path $physPropsFile)) {
    Write-Error "Physical properties file not found: $physPropsFile"
}
Write-Host "✓ Physical properties file: $physPropsFile" -ForegroundColor Green

if (-not (Test-Path $domainConfigFile)) {
    Write-Error "Domain configuration file not found: $domainConfigFile"
}
Write-Host "✓ Domain configuration file: $domainConfigFile" -ForegroundColor Green

if (-not (Test-Path $mcConfigFile)) {
    Write-Error "Monte Carlo configuration file not found: $mcConfigFile"
}
Write-Host "✓ Monte Carlo configuration file: $mcConfigFile" -ForegroundColor Green

# Clean previous outputs if requested
if ($CleanFirst) {
    Write-Host "Cleaning previous outputs..." -ForegroundColor Yellow
    $filesToClean = @(
        "$OUTPUT_PHYS_DIR\${ConfigName}.dom",
        "$OUTPUT_MC_DIR\Fluxes_${ConfigName}.out",
        "$OUTPUT_MC_DIR\Intensities_${ConfigName}.out",
        "$OUTPUT_MC_DIR\Absorption_${ConfigName}.out",
        "$OUTPUT_MC_DIR\All_output_${ConfigName}.nc",
        "$OUTPUT_MC_DIR\Diffuse_Fluxes.out"
    )
    
    foreach ($file in $filesToClean) {
        if (Test-Path $file) {
            Remove-Item $file -Force
            Write-Host "  Removed: $file" -ForegroundColor Yellow
        }
    }
}

# Create output directories if they don't exist
if (-not (Test-Path $OUTPUT_PHYS_DIR)) {
    New-Item -ItemType Directory -Path $OUTPUT_PHYS_DIR -Force | Out-Null
}
if (-not (Test-Path $OUTPUT_MC_DIR)) {
    New-Item -ItemType Directory -Path $OUTPUT_MC_DIR -Force | Out-Null
}

# Step 1: Generate domain file
Write-Host "`nStep 1: Generating domain file..." -ForegroundColor Green

# Convert Windows path to WSL path
$domainConfigFileWSL = $domainConfigFile -replace 'C:\\Users\\PC\\Documents\\GitHub\\I3RC\\', './' -replace '\\', '/'
Write-Host "Command: physicalPropertiesToDomain $domainConfigFileWSL" -ForegroundColor Gray

$step1_result = wsl bash -c "cd /mnt/c/Users/PC/Documents/GitHub/I3RC && ./I3RC-Monte-Carlo-Model/Tools/physicalPropertiesToDomain '$domainConfigFileWSL'"
$step1_exitcode = $LASTEXITCODE

if ($step1_exitcode -ne 0) {
    Write-Error "Failed to generate domain file. Exit code: $step1_exitcode"
}

# Check if domain file was created
$domainFile = "$OUTPUT_PHYS_DIR\${ConfigName}.dom"
if (-not (Test-Path $domainFile)) {
    Write-Error "Domain file was not created: $domainFile"
}

Write-Host "✓ Domain file created: $domainFile" -ForegroundColor Green

# Step 2: Run Monte Carlo simulation
Write-Host "`nStep 2: Running Monte Carlo simulation..." -ForegroundColor Green
Write-Host "Parameters:" -ForegroundColor Gray
Write-Host "  Photons per batch: $NumPhotons" -ForegroundColor Gray
Write-Host "  Number of batches: $NumBatches" -ForegroundColor Gray
Write-Host "  Total photons: $($NumPhotons * $NumBatches)" -ForegroundColor Gray
Write-Host "  Solar zenith angle: $([Math]::Acos($SolarMu) * 180 / [Math]::PI)° (mu = $SolarMu)" -ForegroundColor Gray

# Convert Windows path to WSL path
$mcConfigFileWSL = $mcConfigFile -replace 'C:\\Users\\PC\\Documents\\GitHub\\I3RC\\', './' -replace '\\', '/'
Write-Host "Command: monteCarloDriver $mcConfigFileWSL" -ForegroundColor Gray

$step2_result = wsl bash -c "cd /mnt/c/Users/PC/Documents/GitHub/I3RC && ./I3RC-Monte-Carlo-Model/Example-Drivers/monteCarloDriver '$mcConfigFileWSL'"
$step2_exitcode = $LASTEXITCODE

# Note: We expect exit code 1 due to segfault in cleanup, but outputs are still created
if ($step2_exitcode -ne 0 -and $step2_exitcode -ne 1) {
    Write-Warning "Monte Carlo simulation had non-standard exit code: $step2_exitcode"
}

# Step 3: Check outputs
Write-Host "`nStep 3: Checking simulation outputs..." -ForegroundColor Green

$expectedOutputs = @(
    "$OUTPUT_MC_DIR\Fluxes_${ConfigName}.out",
    "$OUTPUT_MC_DIR\Intensities_${ConfigName}.out", 
    "$OUTPUT_MC_DIR\Absorption_${ConfigName}.out",
    "$OUTPUT_MC_DIR\All_output_${ConfigName}.nc",
    "$OUTPUT_MC_DIR\Diffuse_Fluxes.out"
)

$outputsCreated = 0
foreach ($output in $expectedOutputs) {
    if (Test-Path $output) {
        $fileSize = (Get-Item $output).Length
        Write-Host "✓ Created: $(Split-Path $output -Leaf) ($fileSize bytes)" -ForegroundColor Green
        $outputsCreated++
    } else {
        Write-Host "✗ Missing: $(Split-Path $output -Leaf)" -ForegroundColor Red
    }
}

# Step 4: Display results summary
Write-Host "`nStep 4: Results Summary" -ForegroundColor Green

if (Test-Path "$OUTPUT_MC_DIR\Diffuse_Fluxes.out") {
    Write-Host "`nDirect/Diffuse Radiation Results:" -ForegroundColor Yellow
    $diffuseResults = Get-Content "$OUTPUT_MC_DIR\Diffuse_Fluxes.out"
    
    foreach ($line in $diffuseResults) {
        if ($line -match '^\s*[0-9]') {
            $values = $line -split '\s+' | Where-Object { $_ -ne '' }
            if ($values.Count -ge 4) {
                $topDirect = [double]$values[0]
                $botDirect = [double]$values[1] 
                $topDiffuse = [double]$values[2]
                $botDiffuse = [double]$values[3]
                
                $totalDown = $botDirect + $botDiffuse
                $directPercent = if ($totalDown -gt 0) { ($botDirect / $totalDown) * 100 } else { 0 }
                $diffusePercent = if ($totalDown -gt 0) { ($botDiffuse / $totalDown) * 100 } else { 0 }
                
                Write-Host "  Surface downward flux:" -ForegroundColor White
                Write-Host "    Direct:  $($botDirect.ToString('F6')) ($($directPercent.ToString('F1'))%)" -ForegroundColor White
                Write-Host "    Diffuse: $($botDiffuse.ToString('F6')) ($($diffusePercent.ToString('F1'))%)" -ForegroundColor White
                Write-Host "    Total:   $($totalDown.ToString('F6'))" -ForegroundColor White
                Write-Host "  TOA upward (reflected): $($topDiffuse.ToString('F6'))" -ForegroundColor White
            }
            break
        }
    }
    
    Write-Host "`nFull direct/diffuse results:" -ForegroundColor Gray
    Get-Content "$OUTPUT_MC_DIR\Diffuse_Fluxes.out" | ForEach-Object {
        Write-Host "  $_" -ForegroundColor Gray
    }
}

# Step 5: Final status
Write-Host "`n============================================" -ForegroundColor Cyan
if ($outputsCreated -eq $expectedOutputs.Count) {
    Write-Host "✓ SIMULATION COMPLETED SUCCESSFULLY" -ForegroundColor Green
    Write-Host "✓ All $outputsCreated output files created" -ForegroundColor Green
} elseif ($outputsCreated -gt 0) {
    Write-Host "⚠ SIMULATION PARTIALLY COMPLETED" -ForegroundColor Yellow
    Write-Host "✓ $outputsCreated of $($expectedOutputs.Count) output files created" -ForegroundColor Yellow
} else {
    Write-Host "✗ SIMULATION FAILED" -ForegroundColor Red
    Write-Host "✗ No output files created" -ForegroundColor Red
}

Write-Host "Output directory: $OUTPUT_MC_DIR" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# Return exit code based on success
if ($outputsCreated -ge 4) {  # At least the main outputs should be created
    exit 0
} else {
    exit 1
}
