# I3RC Monte Carlo Simulation Runner
# This script compiles and runs the I3RC Monte Carlo model using WSL
# and demonstrates the new diffuse radiation capability

param(
    [string]$ConfigFile = "monteCarloDriver.nml",
    [switch]$Clean = $false,
    [switch]$Verbose = $false
)

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "  I3RC Monte Carlo Radiation Simulation  " -ForegroundColor Cyan  
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

# Set paths
$I3RC_ROOT = "C:\Users\PC\Documents\GitHub\I3RC"
$MODEL_DIR = "$I3RC_ROOT\I3RC-Monte-Carlo-Model"
$DRIVER_DIR = "$MODEL_DIR\Example-Drivers"
$WSL_MODEL_DIR = "/mnt/c/Users/PC/Documents/GitHub/I3RC/I3RC-Monte-Carlo-Model"
$WSL_DRIVER_DIR = "$WSL_MODEL_DIR/Example-Drivers"

Write-Host "🔧 Configuration:" -ForegroundColor Yellow
Write-Host "   Model Directory: $MODEL_DIR"
Write-Host "   Driver Directory: $DRIVER_DIR"
Write-Host "   Config File: $ConfigFile"
Write-Host ""

# Step 1: Clean if requested
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

# Step 2: Compile the model
Write-Host "🔨 Compiling I3RC Monte Carlo model..." -ForegroundColor Yellow
try {
    $compileResult = wsl bash -c "cd '$WSL_MODEL_DIR' && make 2>&1"
    
    if ($compileResult -match "error|Error|ERROR") {
        Write-Host "❌ Compilation failed!" -ForegroundColor Red
        Write-Host "Compilation output:" -ForegroundColor Red
        Write-Host $compileResult -ForegroundColor Red
        exit 1
    }
    else {
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

# Step 3: Check if executable exists
Write-Host "🔍 Checking executable..." -ForegroundColor Yellow
$executableCheck = wsl bash -c "test -f '$WSL_DRIVER_DIR/monteCarloDriver' && echo 'EXISTS' || echo 'MISSING'"

if ($executableCheck.Trim() -eq "MISSING") {
    Write-Host "❌ Executable not found: $WSL_DRIVER_DIR/monteCarloDriver" -ForegroundColor Red
    exit 1
}
else {
    Write-Host "✅ Executable found: monteCarloDriver" -ForegroundColor Green
}
Write-Host ""

# Step 4: Check configuration file
Write-Host "📄 Checking configuration file..." -ForegroundColor Yellow
$configCheck = wsl bash -c "test -f '$WSL_DRIVER_DIR/$ConfigFile' && echo 'EXISTS' || echo 'MISSING'"

if ($configCheck.Trim() -eq "MISSING") {
    Write-Host "❌ Configuration file not found: $ConfigFile" -ForegroundColor Red
    Write-Host "Available files in driver directory:" -ForegroundColor Yellow
    $files = wsl bash -c "ls -1 '$WSL_DRIVER_DIR'/*.nml 2>/dev/null || echo 'No .nml files found'"
    Write-Host $files -ForegroundColor Gray
    exit 1
}
else {
    Write-Host "✅ Configuration file found: $ConfigFile" -ForegroundColor Green
}
Write-Host ""

# Step 5: Show configuration summary
Write-Host "📋 Configuration Summary:" -ForegroundColor Yellow
try {
    $configContent = wsl bash -c "grep -E '(nPhotons|numBatches|outputFile|surfaceAlbedo)' '$WSL_DRIVER_DIR/$ConfigFile' | head -10"
    if ($configContent) {
        Write-Host $configContent -ForegroundColor Gray
    }
    else {
        Write-Host "   (Configuration details not available)" -ForegroundColor Gray
    }
}
catch {
    Write-Host "   (Could not read configuration)" -ForegroundColor Gray
}
Write-Host ""

# Step 6: Run the simulation
Write-Host "🚀 Running Monte Carlo simulation..." -ForegroundColor Yellow
Write-Host "   This may take a few moments depending on the number of photons..." -ForegroundColor Gray
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
    }
    else {
        Write-Host "✅ Simulation completed successfully!" -ForegroundColor Green
        Write-Host "⏱️  Duration: $($duration.TotalSeconds) seconds" -ForegroundColor Green
    }
}
catch {
    Write-Host "❌ Simulation error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 7: Display simulation output
Write-Host "📊 Simulation Output:" -ForegroundColor Yellow
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host $simulationOutput -ForegroundColor White
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Step 8: Check for output files
Write-Host "📁 Checking output files..." -ForegroundColor Yellow
try {
    $outputFiles = wsl bash -c "ls -la '$WSL_DRIVER_DIR'/*.out '$WSL_DRIVER_DIR'/*.nc 2>/dev/null || echo 'No output files found'"
    
    if ($outputFiles -ne "No output files found") {
        Write-Host "✅ Output files generated:" -ForegroundColor Green
        Write-Host $outputFiles -ForegroundColor Gray
    }
    else {
        Write-Host "⚠️  No standard output files (.out, .nc) found" -ForegroundColor Yellow
        Write-Host "Checking for any recent files..." -ForegroundColor Yellow
        $recentFiles = wsl bash -c "find '$WSL_DRIVER_DIR' -type f -newer '$WSL_DRIVER_DIR/monteCarloDriver' -ls 2>/dev/null || echo 'No recent files'"
        Write-Host $recentFiles -ForegroundColor Gray
    }
}
catch {
    Write-Host "⚠️  Could not check output files" -ForegroundColor Yellow
}
Write-Host ""

# Step 9: Summary and next steps
Write-Host "🎯 Summary:" -ForegroundColor Yellow
Write-Host "✅ Model compiled successfully" -ForegroundColor Green  
Write-Host "✅ Simulation executed" -ForegroundColor Green
Write-Host ""
Write-Host "🔬 Research Notes:" -ForegroundColor Yellow
Write-Host "   • The simulation used the STANDARD I3RC driver" -ForegroundColor Cyan
Write-Host "   • To access DIFFUSE RADIATION, modify the driver to use:" -ForegroundColor Cyan
Write-Host "     reportResultsWithDiffuse() instead of reportResults()" -ForegroundColor Cyan
Write-Host "   • See IMPLEMENTATION_SUMMARY.md for complete details" -ForegroundColor Cyan
Write-Host ""
Write-Host "📁 Files location: $DRIVER_DIR" -ForegroundColor Yellow
Write-Host ""
Write-Host "🎉 I3RC Monte Carlo simulation completed!" -ForegroundColor Green

# Optional: Open the directory in Explorer
Write-Host ""
$openDir = Read-Host "Open output directory in Explorer? (y/N)"
if ($openDir -eq "y" -or $openDir -eq "Y") {
    Start-Process explorer.exe -ArgumentList $DRIVER_DIR
}
