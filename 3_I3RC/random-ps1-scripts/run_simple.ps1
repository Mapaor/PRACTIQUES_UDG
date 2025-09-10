# Simple I3RC Simulation Runner
# Quick script to compile and run the I3RC Monte Carlo model

Write-Host "🚀 Running I3RC Monte Carlo Simulation..." -ForegroundColor Cyan


# Compile the driver in Example-Drivers
Write-Host "Compiling in Example-Drivers..." -ForegroundColor Yellow
wsl bash -c "cd /mnt/c/Users/PC/Documents/GitHub/I3RC/I3RC-Monte-Carlo-Model/Example-Drivers && make"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Compilation successful" -ForegroundColor Green
    
    # Run the simulation
    Write-Host "Running simulation..." -ForegroundColor Yellow
    wsl bash -c "cd /mnt/c/Users/PC/Documents/GitHub/I3RC/I3RC-Monte-Carlo-Model/Example-Drivers && ./monteCarloDriver < monteCarloDriver.nml"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Simulation completed!" -ForegroundColor Green
        
        # Show output files
        Write-Host "Output files:" -ForegroundColor Yellow
        wsl bash -c "ls -la /mnt/c/Users/PC/Documents/GitHub/I3RC/I3RC-Monte-Carlo-Model/Example-Drivers/*.out 2>/dev/null || echo 'No .out files found'"
    }
    else {
        Write-Host "❌ Simulation failed" -ForegroundColor Red
    }
}
else {
    Write-Host "❌ Compilation failed" -ForegroundColor Red
}
