# Quick debug script to check compilation status

Write-Host "🔍 Debugging I3RC Compilation..." -ForegroundColor Cyan
Write-Host ""

# Check current directory structure
Write-Host "📁 Driver directory contents:" -ForegroundColor Yellow
$driverDir = "C:\Users\PC\Documents\GitHub\I3RC\I3RC-Monte-Carlo-Model\Example-Drivers"
Get-ChildItem $driverDir | Select-Object Name, Length, LastWriteTime | Format-Table

Write-Host ""
Write-Host "🔨 Testing compilation with detailed output..." -ForegroundColor Yellow
$compileResult = wsl bash -c "cd /mnt/c/Users/PC/Documents/GitHub/I3RC/I3RC-Monte-Carlo-Model/Example-Drivers && make clean && make 2>&1"

Write-Host "Compilation output:" -ForegroundColor Gray
Write-Host $compileResult

if ($compileResult -match "error|Error|ERROR") {
    Write-Host ""
    Write-Host "❌ Compilation errors detected!" -ForegroundColor Red
    
    # Show specific errors
    $compileResult -split "`n" | Where-Object { $_ -match "error|Error|ERROR" } | ForEach-Object {
        Write-Host "   ERROR: $_" -ForegroundColor Red
    }
} else {
    Write-Host ""
    Write-Host "✅ Compilation appears successful" -ForegroundColor Green
    
    # Check if executable was created
    $executableCheck = wsl bash -c "test -f /mnt/c/Users/PC/Documents/GitHub/I3RC/I3RC-Monte-Carlo-Model/Example-Drivers/monteCarloDriver && echo 'EXISTS' || echo 'MISSING'"
    
    if ($executableCheck.Trim() -eq "EXISTS") {
        Write-Host "✅ Executable found: monteCarloDriver" -ForegroundColor Green
    } else {
        Write-Host "❌ Executable missing: monteCarloDriver" -ForegroundColor Red
        
        # Check what files were created
        Write-Host "Files in driver directory:" -ForegroundColor Yellow
        $files = wsl bash -c "ls -la /mnt/c/Users/PC/Documents/GitHub/I3RC/I3RC-Monte-Carlo-Model/Example-Drivers/monte*"
        Write-Host $files -ForegroundColor Gray
    }
}
