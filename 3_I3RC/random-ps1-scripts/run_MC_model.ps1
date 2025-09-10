# PowerShell version of run_MC_model for Windows
# I3RC Monte Carlo Radiative Transfer Model runner

param(
    [switch]$Debug = $false
)

Write-Host "============================================" -ForegroundColor Green
Write-Host "I3RC Monte Carlo Radiative Transfer Model" -ForegroundColor Green  
Write-Host "============================================" -ForegroundColor Green
Write-Host ""

# Check if we're in the right directory
if (-not (Test-Path "I3RC-Monte-Carlo-Model")) {
    Write-Error "Error: I3RC-Monte-Carlo-Model directory not found. Please run this script from the main I3RC directory."
    exit 1
}

# Check if Input directory exists
if (-not (Test-Path "Input")) {
    Write-Error "Error: Input directory not found. Please ensure Input directory exists with configuration files."
    exit 1
}

# Check if Output directory exists, create if not
if (-not (Test-Path "Output")) {
    Write-Host "Creating Output directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path "Output" -Force | Out-Null
    New-Item -ItemType Directory -Path "Output/MakeMieTable" -Force | Out-Null
    New-Item -ItemType Directory -Path "Output/PhysicalPropertiesToDomain" -Force | Out-Null
    New-Item -ItemType Directory -Path "Output/monteCarloDriver" -Force | Out-Null
}

# Step 1: MakeMieTable
Write-Host "Step 1: Creating scattering phase function look-up table using Mie theory" -ForegroundColor Cyan
Write-Host "-----------------------------------------------------------------------" -ForegroundColor Cyan

$mieTableExe = "I3RC-Monte-Carlo-Model/Tools/MakeMieTable"
$mieTableInput = "Input/MakeMieTable/mie_table_cloud.nml"

if (-not (Test-Path $mieTableExe)) {
    Write-Error "Error: $mieTableExe not found. Please build the project first."
    exit 1
}

if (-not (Test-Path $mieTableInput)) {
    Write-Error "Error: $mieTableInput not found. Please ensure input files exist."
    exit 1
}

$stopwatch1 = [System.Diagnostics.Stopwatch]::StartNew()
try {
    & $mieTableExe $mieTableInput
    if ($LASTEXITCODE -ne 0) {
        Write-Error "MakeMieTable failed with exit code $LASTEXITCODE"
        exit 1
    }
} catch {
    Write-Error "Error running MakeMieTable: $_"
    exit 1
}
$stopwatch1.Stop()
Write-Host "MakeMieTable completed in $($stopwatch1.Elapsed.TotalSeconds.ToString('F2')) seconds" -ForegroundColor Green
Write-Host ""

# Step 2: PhysicalPropertiesToDomain  
Write-Host "Step 2: Calculating optical properties of simulation domain" -ForegroundColor Cyan
Write-Host "--------------------------------------------------------" -ForegroundColor Cyan

$domainExe = "I3RC-Monte-Carlo-Model/Tools/PhysicalPropertiesToDomain"
$domainInput = "Input/PhysicalPropertiesToDomain/cloud_domain.nml"

if (-not (Test-Path $domainExe)) {
    Write-Error "Error: $domainExe not found. Please build the project first."
    exit 1
}

if (-not (Test-Path $domainInput)) {
    Write-Error "Error: $domainInput not found. Please ensure input files exist."
    exit 1
}

$stopwatch2 = [System.Diagnostics.Stopwatch]::StartNew()
try {
    & $domainExe $domainInput
    if ($LASTEXITCODE -ne 0) {
        Write-Error "PhysicalPropertiesToDomain failed with exit code $LASTEXITCODE"
        exit 1
    }
} catch {
    Write-Error "Error running PhysicalPropertiesToDomain: $_"
    exit 1
}
$stopwatch2.Stop()
Write-Host "PhysicalPropertiesToDomain completed in $($stopwatch2.Elapsed.TotalSeconds.ToString('F2')) seconds" -ForegroundColor Green
Write-Host ""

# Step 3: MonteCarloDriver
Write-Host "Step 3: Running Monte Carlo simulation" -ForegroundColor Cyan
Write-Host "------------------------------------" -ForegroundColor Cyan

$mcDriverExe = "I3RC-Monte-Carlo-Model/Example-Drivers/monteCarloDriver"
$mcDriverInput = "Input/MonteCarloDriver/MonteCarloDriver.nml"

if (-not (Test-Path $mcDriverExe)) {
    Write-Error "Error: $mcDriverExe not found. Please build the project first."
    exit 1
}

if (-not (Test-Path $mcDriverInput)) {
    Write-Error "Error: $mcDriverInput not found. Please ensure input files exist."
    exit 1
}

$stopwatch3 = [System.Diagnostics.Stopwatch]::StartNew()
try {
    & $mcDriverExe $mcDriverInput
    if ($LASTEXITCODE -ne 0) {
        Write-Error "MonteCarloDriver failed with exit code $LASTEXITCODE"
        exit 1
    }
} catch {
    Write-Error "Error running MonteCarloDriver: $_"
    exit 1
}
$stopwatch3.Stop()
Write-Host "MonteCarloDriver completed in $($stopwatch3.Elapsed.TotalSeconds.ToString('F2')) seconds" -ForegroundColor Green
Write-Host ""

# Summary
$totalTime = $stopwatch1.Elapsed + $stopwatch2.Elapsed + $stopwatch3.Elapsed
Write-Host "============================================" -ForegroundColor Green
Write-Host "SUCCESS: Monte Carlo Model Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host "Total execution time: $($totalTime.TotalSeconds.ToString('F2')) seconds" -ForegroundColor Green
Write-Host ""
Write-Host "Results are available in the Output directory:" -ForegroundColor Yellow
Write-Host "  - Output/MakeMieTable/" -ForegroundColor Yellow
Write-Host "  - Output/PhysicalPropertiesToDomain/" -ForegroundColor Yellow  
Write-Host "  - Output/monteCarloDriver/" -ForegroundColor Yellow
Write-Host ""
Write-Host "Check these directories for your simulation results!" -ForegroundColor Yellow
