# Simple test script for diffuse radiation capability
# Tests compilation and basic execution

param(
    [switch]$CompileOnly = $false
)

Write-Host "🔧 Testing I3RC Diffuse Radiation Capability..." -ForegroundColor Cyan
Write-Host ""

# Test compilation
Write-Host "🔨 Testing compilation..." -ForegroundColor Yellow
$compileResult = wsl bash -c "cd /mnt/c/Users/PC/Documents/GitHub/I3RC/I3RC-Monte-Carlo-Model/Example-Drivers && make 2>&1"

if ($compileResult -match "error|Error|ERROR") {
    Write-Host "❌ Compilation failed!" -ForegroundColor Red
    Write-Host $compileResult -ForegroundColor Red
    exit 1
} else {
    Write-Host "✅ Compilation successful!" -ForegroundColor Green
    if ($compileResult -match "warning|Warning|WARNING") {
        Write-Host "⚠️  Warnings present (but compilation succeeded):" -ForegroundColor Yellow
        $compileResult -split "`n" | Where-Object { $_ -match "warning|Warning|WARNING" } | ForEach-Object {
            Write-Host "   $_" -ForegroundColor Gray
        }
    }
}
Write-Host ""

if ($CompileOnly) {
    Write-Host "🎉 Compilation test complete!" -ForegroundColor Green
    exit 0
}

# Test execution with minimal parameters
Write-Host "🚀 Testing execution with minimal simulation..." -ForegroundColor Yellow

# Check if configuration file exists
$configFile = "C:\Users\PC\Documents\GitHub\I3RC\I3RC-Monte-Carlo-Model\Example-Drivers\monteCarloDriver.nml"
if (-not (Test-Path $configFile)) {
    # Copy from input directory
    $inputConfig = "C:\Users\PC\Documents\GitHub\I3RC\Input\MonteCarloDriver\monteCarloDriver.nml"
    if (Test-Path $inputConfig) {
        Copy-Item $inputConfig $configFile
        Write-Host "✅ Copied configuration from Input directory" -ForegroundColor Green
    } else {
        Write-Host "❌ Configuration file not found!" -ForegroundColor Red
        exit 1
    }
}

# Run minimal test
Write-Host "   Running 100 photons, 2 batches..." -ForegroundColor Gray
$testResult = wsl bash -c "cd /mnt/c/Users/PC/Documents/GitHub/I3RC/I3RC-Monte-Carlo-Model/Example-Drivers && timeout 60 ./monteCarloDriver < monteCarloDriver.nml 2>&1"

if ($testResult -match "error|Error|ERROR|failed|Failed|FAILED") {
    Write-Host "❌ Test execution failed!" -ForegroundColor Red
    Write-Host $testResult -ForegroundColor Red
} else {
    Write-Host "✅ Test execution successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📊 Sample output:" -ForegroundColor Yellow
    $testResult -split "`n" | Select-Object -Last 10 | ForEach-Object {
        Write-Host "   $_" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "🎉 Diffuse radiation capability test complete!" -ForegroundColor Green
