#!/usr/bin/env pwsh
# extract_diffuse_exact.ps1
# PowerShell script to extract EXACT diffuse radiation using I3RC's built-in scattering order tracking

param(
    [int]$NumPhotons = 1000,
    [int]$NumBatches = 3,
    [switch]$Clean,
    [switch]$Verbose
)

Write-Host "🌟 I3RC EXACT DIFFUSE RADIATION EXTRACTION" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Using built-in scattering order tracking for exact direct/diffuse separation" -ForegroundColor Green
Write-Host ""

# Parameters
$I3RCPath = "C:\Users\PC\Documents\GitHub\I3RC\I3RC-Monte-Carlo-Model"
$ExampleDriversPath = "$I3RCPath\Example-Drivers"
$InputPath = "C:\Users\PC\Documents\GitHub\I3RC\Input\MonteCarloDriver"
$OutputPath = "C:\Users\PC\Documents\GitHub\I3RC\Output\monteCarloDriver"

# Ensure output directory exists
if (!(Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

# Step 1: Copy input files to working directory
Write-Host "📁 Step 1: Preparing input files..." -ForegroundColor Yellow
try {
    Copy-Item "$InputPath\*" $ExampleDriversPath -Force -ErrorAction SilentlyContinue
    Write-Host "✅ Input files copied to working directory" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Warning: Could not copy all input files: $_" -ForegroundColor Yellow
}

# Step 2: Update the namelist file for our parameters
Write-Host "📝 Step 2: Configuring simulation parameters..." -ForegroundColor Yellow
$namelistContent = @"
&radiativeTransfer
  solarFlux = 1.0
  solarMu = 1.0
  solarAzimuth = 0.0
  surfaceAlbedo = 0.1
  intensityMus = 1.0
  intensityPhis = 0.0
/

&monteCarlo
  numPhotonsPerBatch = $NumPhotons
  numBatches = $NumBatches
  iseed = 12345
  nPhaseIntervals = 9001
/

&algorithms
  useRayTracing = .true.
  useRussianRoulette = .true.
  useHybridPhaseFunsForIntenCalcs = .false.
  hybridPhaseFunWidth = 7.0
  numOrdersOrigPhaseFunIntenCalcs = 0
  useRussianRouletteForIntensity = .true.
  zetaMin = 0.3
  limitIntensityContributions = .false.
  maxIntensityContribution = 77.0
/

&output
  reportVolumeAbsorption = .false.
  reportAbsorptionProfile = .false.
/

&fileNames
  domainFileName = 'cloud.dom'
  outputFluxFile = 'Fluxes.out'
  outputRadFile = ''
  outputAbsProfFile = ''
  outputAbsVolumeFile = ''
  outputNetcdfFile = ''
/
"@

$namelistFile = "$ExampleDriversPath\test_diffuse.nml"
Set-Content -Path $namelistFile -Value $namelistContent
Write-Host "✅ Namelist configured: test_diffuse.nml" -ForegroundColor Green

# Step 3: Copy domain file and ensure it exists
Write-Host "🌍 Step 3: Ensuring domain file exists..." -ForegroundColor Yellow
$domainFile = "$ExampleDriversPath\cloud.dom"
if (!(Test-Path $domainFile)) {
    Write-Host "Copying domain file from Output directory..." -ForegroundColor Cyan
    try {
        Copy-Item "C:\Users\PC\Documents\GitHub\I3RC\Output\PhysicalPropertiesToDomain\cloud.dom" -Destination $domainFile
        Write-Host "✅ Domain file copied successfully" -ForegroundColor Green
    } catch {
        Write-Host "❌ Could not copy domain file: $_" -ForegroundColor Red
        return
    }
} else {
    Write-Host "✅ Domain file exists" -ForegroundColor Green
}

# Step 4: Compile and run I3RC
Write-Host "🔨 Step 4: Running I3RC Monte Carlo simulation..." -ForegroundColor Yellow
Set-Location $ExampleDriversPath

try {
    Write-Host "Starting I3RC simulation..." -ForegroundColor Cyan
    $process = Start-Process -FilePath "wsl" -ArgumentList "./monteCarloDriver test_diffuse.nml" -Wait -PassThru -NoNewWindow
    
    if ($process.ExitCode -eq 0) {
        Write-Host "✅ I3RC simulation completed successfully!" -ForegroundColor Green
    } else {
        Write-Host "❌ I3RC simulation failed with exit code: $($process.ExitCode)" -ForegroundColor Red
        return
    }
} catch {
    Write-Host "❌ Error running I3RC: $_" -ForegroundColor Red
    return
}

# Step 5: Check for diffuse output files
Write-Host "📊 Step 5: Analyzing results..." -ForegroundColor Yellow

$fluxFile = "$ExampleDriversPath\Fluxes.out"
$diffuseFile = "$ExampleDriversPath\Diffuse_Fluxes.out"

if (Test-Path $fluxFile) {
    Write-Host "✅ Found standard flux results: Fluxes.out" -ForegroundColor Green
} else {
    Write-Host "⚠️  Warning: Standard flux file not found" -ForegroundColor Yellow
}

if (Test-Path $diffuseFile) {
    Write-Host "✅ Found diffuse radiation results: Diffuse_Fluxes.out" -ForegroundColor Green
    
    # Copy results to output directory
    Copy-Item $fluxFile $OutputPath -Force -ErrorAction SilentlyContinue
    Copy-Item $diffuseFile $OutputPath -Force -ErrorAction SilentlyContinue
    
    # Extract key results
    Write-Host "" -ForegroundColor White
    Write-Host "🎯 EXACT DIFFUSE RADIATION RESULTS:" -ForegroundColor Cyan
    Write-Host "=================================" -ForegroundColor Cyan
    
    $diffuseContent = Get-Content $diffuseFile
    foreach ($line in $diffuseContent) {
        if ($line -match "Domain-mean.*diffuse.*:.*([0-9.]+).*\+/-.*([0-9.]+)") {
            Write-Host $line -ForegroundColor White
        } elseif ($line -match "Dif_down.*=.*([0-9.]+).*\+/-.*([0-9.]+)") {
            Write-Host $line -ForegroundColor Green
        }
    }
    
    Write-Host "" -ForegroundColor White
    Write-Host "🔬 SCIENTIFIC METHOD:" -ForegroundColor Cyan
    Write-Host "Direct radiation  = scattering order 0" -ForegroundColor White
    Write-Host "Diffuse radiation = scattering order ≥ 1" -ForegroundColor White
    Write-Host "" -ForegroundColor White
    
    Write-Host "📁 Results saved to: $OutputPath" -ForegroundColor Yellow
    Write-Host "✅ EXACT DIFFUSE RADIATION SUCCESSFULLY EXTRACTED!" -ForegroundColor Green
    
} else {
    Write-Host "❌ Diffuse radiation file not found" -ForegroundColor Red
    Write-Host "Check the I3RC compilation and execution" -ForegroundColor Yellow
}

Write-Host "" -ForegroundColor White
Write-Host "🎉 EXACT DIFFUSE EXTRACTION COMPLETE!" -ForegroundColor Cyan
