# I3RC Diffuse Radiation Analysis Script
# This script runs the complete I3RC simulation and extracts diffuse radiation at surface
# Usage: .\run_diffuse_simulation.ps1 [-InputDir "path"] [-OutputDir "path"] [-ConfigFile "file.nml"]

param(
    [string]$InputDir = "Input\MonteCarloDriver",
    [string]$OutputDir = "Output\monteCarloDriver", 
    [string]$ConfigFile = "monteCarloDriver.nml",
    [switch]$Clean = $false,
    [switch]$Verbose = $false,
    [int]$NumPhotons = 10000,
    [int]$NumBatches = 10
)

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  I3RC DIFFUSE RADIATION ANALYSIS TOOL     " -ForegroundColor Cyan  
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Set paths
$SCRIPT_DIR = $PSScriptRoot
$I3RC_ROOT = $SCRIPT_DIR
$MODEL_DIR = "$I3RC_ROOT\I3RC-Monte-Carlo-Model"
$DRIVER_DIR = "$MODEL_DIR\Example-Drivers"
$INPUT_FULL_PATH = "$I3RC_ROOT\$InputDir"
$OUTPUT_FULL_PATH = "$I3RC_ROOT\$OutputDir"

# WSL paths
$WSL_MODEL_DIR = "/mnt/c/Users/PC/Documents/GitHub/I3RC/I3RC-Monte-Carlo-Model"
$WSL_DRIVER_DIR = "$WSL_MODEL_DIR/Example-Drivers"
$WSL_INPUT_DIR = "/mnt/c/Users/PC/Documents/GitHub/I3RC/$($InputDir.Replace('\', '/'))"
$WSL_OUTPUT_DIR = "/mnt/c/Users/PC/Documents/GitHub/I3RC/$($OutputDir.Replace('\', '/'))"

Write-Host "🔧 Configuration:" -ForegroundColor Yellow
Write-Host "   Input Directory:  $INPUT_FULL_PATH"
Write-Host "   Output Directory: $OUTPUT_FULL_PATH"
Write-Host "   Config File:      $ConfigFile"
Write-Host "   Number of Photons: $NumPhotons"
Write-Host "   Number of Batches: $NumBatches"
Write-Host ""

# Step 1: Verify input files exist
Write-Host "📁 Checking input files..." -ForegroundColor Yellow

if (-not (Test-Path $INPUT_FULL_PATH)) {
    Write-Host "❌ Input directory not found: $INPUT_FULL_PATH" -ForegroundColor Red
    exit 1
}

$configPath = "$INPUT_FULL_PATH\$ConfigFile"
if (-not (Test-Path $configPath)) {
    Write-Host "❌ Configuration file not found: $configPath" -ForegroundColor Red
    Write-Host "Available files:" -ForegroundColor Yellow
    Get-ChildItem $INPUT_FULL_PATH -Filter "*.nml" | ForEach-Object { Write-Host "   $($_.Name)" -ForegroundColor Gray }
    exit 1
}

Write-Host "✅ Input files verified" -ForegroundColor Green
Write-Host ""

# Step 2: Create output directory
Write-Host "📂 Preparing output directory..." -ForegroundColor Yellow
if (-not (Test-Path $OUTPUT_FULL_PATH)) {
    New-Item -ItemType Directory -Path $OUTPUT_FULL_PATH -Force | Out-Null
    Write-Host "✅ Created output directory: $OUTPUT_FULL_PATH" -ForegroundColor Green
} else {
    Write-Host "✅ Output directory exists: $OUTPUT_FULL_PATH" -ForegroundColor Green
}
Write-Host ""

# Step 3: Copy input files to driver directory
Write-Host "📋 Copying configuration files..." -ForegroundColor Yellow
try {
    Copy-Item "$configPath" "$DRIVER_DIR\$ConfigFile" -Force
    Write-Host "✅ Copied $ConfigFile to driver directory" -ForegroundColor Green
    
    # Copy domain file if it exists
    $domainFiles = Get-ChildItem $INPUT_FULL_PATH -Filter "*.dom"
    foreach ($domainFile in $domainFiles) {
        Copy-Item $domainFile.FullName "$DRIVER_DIR\$($domainFile.Name)" -Force
        Write-Host "✅ Copied $($domainFile.Name) to driver directory" -ForegroundColor Green
    }
}
catch {
    Write-Host "❌ Error copying files: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 4: Clean if requested
if ($Clean) {
    Write-Host "🧹 Cleaning previous build..." -ForegroundColor Yellow
    try {
        $cleanResult = wsl bash -c "cd '$WSL_MODEL_DIR' && make clean 2>&1"
        if ($Verbose) {
            Write-Host "Clean output: $cleanResult" -ForegroundColor Gray
        }
        Write-Host "✅ Clean completed" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️  Clean failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    Write-Host ""
}

# Step 5: Compile the model
Write-Host "🔨 Compiling I3RC Monte Carlo model with diffuse capability..." -ForegroundColor Yellow
try {
    $compileResult = wsl bash -c "cd '$WSL_MODEL_DIR' && make 2>&1"
    
    if ($compileResult -match "error|Error|ERROR") {
        Write-Host "❌ Compilation failed!" -ForegroundColor Red
        Write-Host "Compilation output:" -ForegroundColor Red
        Write-Host $compileResult -ForegroundColor Red
        exit 1
    } else {
        Write-Host "✅ Compilation successful" -ForegroundColor Green
        if ($Verbose) {
            Write-Host "Compilation output:" -ForegroundColor Gray
            Write-Host $compileResult -ForegroundColor Gray
        }
    }
}
catch {
    Write-Host "❌ Compilation error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 6: Check executable
Write-Host "🔍 Verifying executable..." -ForegroundColor Yellow
$executableCheck = wsl bash -c "test -f '$WSL_DRIVER_DIR/monteCarloDriver' && echo 'EXISTS' || echo 'MISSING'"

if ($executableCheck.Trim() -eq "MISSING") {
    Write-Host "❌ Executable not found: $WSL_DRIVER_DIR/monteCarloDriver" -ForegroundColor Red
    exit 1
} else {
    Write-Host "✅ Executable ready: monteCarloDriver" -ForegroundColor Green
}
Write-Host ""

# Step 7: Update configuration for diffuse analysis
Write-Host "⚙️ Configuring simulation parameters..." -ForegroundColor Yellow
$configContent = Get-Content "$DRIVER_DIR\$ConfigFile"
$newConfigContent = @()

foreach ($line in $configContent) {
    if ($line -match "numPhotonsPerBatch\s*=") {
        $newConfigContent += "  numPhotonsPerBatch = $NumPhotons"
        Write-Host "   Set numPhotonsPerBatch = $NumPhotons" -ForegroundColor Gray
    }
    elseif ($line -match "numBatches\s*=") {
        $newConfigContent += "  numBatches = $NumBatches"
        Write-Host "   Set numBatches = $NumBatches" -ForegroundColor Gray
    }
    elseif ($line -match "outputFluxFile\s*=") {
        $newConfigContent += '  outputFluxFile = "Fluxes_with_diffuse.out"'
        Write-Host "   Set outputFluxFile = Fluxes_with_diffuse.out" -ForegroundColor Gray
    }
    else {
        $newConfigContent += $line
    }
}

$newConfigContent | Set-Content "$DRIVER_DIR\$ConfigFile"
Write-Host "✅ Configuration updated for diffuse radiation analysis" -ForegroundColor Green
Write-Host ""

# Step 8: Run the simulation
Write-Host "🚀 Running Monte Carlo simulation with diffuse tracking..." -ForegroundColor Yellow
Write-Host "   This may take several minutes depending on photon count..." -ForegroundColor Gray
Write-Host ""

try {
    $startTime = Get-Date
    
    # Run the simulation and capture output
    $simulationOutput = wsl bash -c "cd '$WSL_DRIVER_DIR' && ./monteCarloDriver < $ConfigFile 2>&1"
    
    $endTime = Get-Date
    $duration = $endTime - $startTime
    
    # Check if simulation completed successfully
    if ($simulationOutput -match "error|Error|ERROR|failed|Failed|FAILED") {
        Write-Host "❌ Simulation failed!" -ForegroundColor Red
        Write-Host "Simulation output:" -ForegroundColor Red
        Write-Host $simulationOutput -ForegroundColor Red
        exit 1
    } else {
        Write-Host "✅ Simulation completed successfully!" -ForegroundColor Green
        Write-Host "⏱️  Duration: $([math]::Round($duration.TotalSeconds, 1)) seconds" -ForegroundColor Green
    }
}
catch {
    Write-Host "❌ Simulation error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 9: Copy results to output directory
Write-Host "📤 Copying results to output directory..." -ForegroundColor Yellow
try {
    # Copy all output files
    $outputFiles = Get-ChildItem "$DRIVER_DIR" -Filter "*.out"
    foreach ($file in $outputFiles) {
        Copy-Item $file.FullName "$OUTPUT_FULL_PATH\$($file.Name)" -Force
        Write-Host "   Copied: $($file.Name)" -ForegroundColor Gray
    }
    
    # Copy NetCDF files if they exist
    $ncFiles = Get-ChildItem "$DRIVER_DIR" -Filter "*.nc"
    foreach ($file in $ncFiles) {
        Copy-Item $file.FullName "$OUTPUT_FULL_PATH\$($file.Name)" -Force
        Write-Host "   Copied: $($file.Name)" -ForegroundColor Gray
    }
    
    Write-Host "✅ Results copied to output directory" -ForegroundColor Green
}
catch {
    Write-Host "⚠️  Warning: Could not copy some files: $($_.Exception.Message)" -ForegroundColor Yellow
}
Write-Host ""

# Step 10: Extract and analyze diffuse radiation
Write-Host "🔬 Analyzing diffuse radiation results..." -ForegroundColor Yellow
$fluxFile = "$OUTPUT_FULL_PATH\Fluxes_with_diffuse.out"

if (Test-Path $fluxFile) {
    Write-Host "✅ Found flux output file: Fluxes_with_diffuse.out" -ForegroundColor Green
    
    # Read and parse the flux file
    $fluxContent = Get-Content $fluxFile
    
    # Find the average line
    $averageLine = $fluxContent | Where-Object { $_ -match "!  Average:" }
    
    if ($averageLine) {
        Write-Host ""
        Write-Host "📊 DIFFUSE RADIATION ANALYSIS RESULTS:" -ForegroundColor Cyan
        Write-Host "=====================================" -ForegroundColor Cyan
        
        # Parse the values
        $values = $averageLine -replace "!  Average:\s*", "" -split "\s+"
        $values = $values | Where-Object { $_ -ne "" }
        
        if ($values.Count -ge 10) {
            $fluxUp = [double]$values[0]
            $fluxUpErr = [double]$values[1]
            $fluxDown = [double]$values[2]
            $fluxDownErr = [double]$values[3]
            $fluxAbs = [double]$values[4]
            $fluxAbsErr = [double]$values[5]
            $fluxUpDiff = [double]$values[6]
            $fluxUpDiffErr = [double]$values[7]
            $fluxDownDiff = [double]$values[8]
            $fluxDownDiffErr = [double]$values[9]
            
            Write-Host "TOTAL FLUXES:" -ForegroundColor Yellow
            Write-Host "  Upward (TOPDN):   $($fluxUp.ToString('F4')) ± $($fluxUpErr.ToString('F4')) W/m²" -ForegroundColor White
            Write-Host "  Downward (BOTDN): $($fluxDown.ToString('F4')) ± $($fluxDownErr.ToString('F4')) W/m²" -ForegroundColor White
            Write-Host "  Absorbed:         $($fluxAbs.ToString('F4')) ± $($fluxAbsErr.ToString('F4')) W/m²" -ForegroundColor White
            Write-Host ""
            Write-Host "DIFFUSE COMPONENTS:" -ForegroundColor Yellow
            Write-Host "  Upward Diffuse:   $($fluxUpDiff.ToString('F4')) ± $($fluxUpDiffErr.ToString('F4')) W/m²" -ForegroundColor Green
            Write-Host "  Downward Diffuse: $($fluxDownDiff.ToString('F4')) ± $($fluxDownDiffErr.ToString('F4')) W/m²" -ForegroundColor Green
            Write-Host ""
            Write-Host "DIRECT COMPONENTS (Total - Diffuse):" -ForegroundColor Yellow
            $directUp = $fluxUp - $fluxUpDiff
            $directDown = $fluxDown - $fluxDownDiff
            Write-Host "  Upward Direct:    $($directUp.ToString('F4')) W/m²" -ForegroundColor Magenta
            Write-Host "  Downward Direct:  $($directDown.ToString('F4')) W/m²" -ForegroundColor Magenta
            Write-Host ""
            Write-Host "DIFFUSE FRACTIONS:" -ForegroundColor Yellow
            if ($fluxUp -gt 0) {
                $diffFracUp = ($fluxUpDiff / $fluxUp) * 100
                Write-Host "  Upward Diffuse:   $($diffFracUp.ToString('F1'))%" -ForegroundColor Green
            }
            if ($fluxDown -gt 0) {
                $diffFracDown = ($fluxDownDiff / $fluxDown) * 100
                Write-Host "  Downward Diffuse: $($diffFracDown.ToString('F1'))%" -ForegroundColor Green
            }
            Write-Host ""
            Write-Host "🎯 KEY RESULT - SURFACE DIFFUSE RADIATION:" -ForegroundColor Cyan
            Write-Host "   Dif_down = $($fluxDownDiff.ToString('F4')) ± $($fluxDownDiffErr.ToString('F4')) W/m²" -ForegroundColor Green
            
            # Save summary to file
            $summaryFile = "$OUTPUT_FULL_PATH\diffuse_radiation_summary.txt"
            $summary = @"
I3RC Monte Carlo Diffuse Radiation Analysis
==========================================
Date: $(Get-Date)
Configuration: $ConfigFile
Photons: $($NumPhotons * $NumBatches) total ($NumPhotons per batch × $NumBatches batches)

RESULTS:
Total Upward Flux (TOPDN):    $($fluxUp.ToString('F6')) ± $($fluxUpErr.ToString('F6')) W/m²
Total Downward Flux (BOTDN):  $($fluxDown.ToString('F6')) ± $($fluxDownErr.ToString('F6')) W/m²
Absorbed Flux:                $($fluxAbs.ToString('F6')) ± $($fluxAbsErr.ToString('F6')) W/m²

Upward Diffuse Flux:          $($fluxUpDiff.ToString('F6')) ± $($fluxUpDiffErr.ToString('F6')) W/m²
Downward Diffuse Flux:        $($fluxDownDiff.ToString('F6')) ± $($fluxDownDiffErr.ToString('F6')) W/m²

Direct Upward Flux:           $($directUp.ToString('F6')) W/m²
Direct Downward Flux:         $($directDown.ToString('F6')) W/m²

Diffuse Fraction (Upward):    $($diffFracUp.ToString('F2'))%
Diffuse Fraction (Downward):  $($diffFracDown.ToString('F2'))%

KEY RESULT:
Surface Diffuse Radiation (Dif_down) = $($fluxDownDiff.ToString('F6')) ± $($fluxDownDiffErr.ToString('F6')) W/m²
"@
            $summary | Set-Content $summaryFile
            Write-Host ""
            Write-Host "✅ Summary saved to: diffuse_radiation_summary.txt" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Could not parse flux values from output" -ForegroundColor Yellow
            Write-Host "   Raw line: $averageLine" -ForegroundColor Gray
        }
    } else {
        Write-Host "⚠️  Could not find average flux line in output" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ Flux output file not found: $fluxFile" -ForegroundColor Red
    Write-Host "Available files in output directory:" -ForegroundColor Yellow
    Get-ChildItem $OUTPUT_FULL_PATH | ForEach-Object { Write-Host "   $($_.Name)" -ForegroundColor Gray }
}

Write-Host ""
Write-Host "🎉 I3RC Diffuse Radiation Analysis Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📁 Output Location: $OUTPUT_FULL_PATH" -ForegroundColor Yellow
Write-Host "📊 Key Files:" -ForegroundColor Yellow
Write-Host "   • Fluxes_with_diffuse.out - Complete flux results with diffuse components" -ForegroundColor Gray
Write-Host "   • diffuse_radiation_summary.txt - Analysis summary" -ForegroundColor Gray
Write-Host ""

# Optional: Open output directory
$openDir = Read-Host "Open output directory in Explorer? (y/N)"
if ($openDir -eq "y" -or $openDir -eq "Y") {
    Start-Process explorer.exe -ArgumentList $OUTPUT_FULL_PATH
}
