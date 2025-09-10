# 1) pwsh ./PerpareI3RCProfiles.ps1
# Prepare I3RC Mie tables and domain files using WSL
Write-Host "🚀 Preparing I3RC simulation profiles..." -ForegroundColor Cyan

# Build Mie tables
Write-Host "Building Mie tables..." -ForegroundColor Yellow
wsl bash -c "cd /mnt/c/Users/PC/Documents/GitHub/I3RC/I3RC-Monte-Carlo-Model/Tools && ./MakeMieTable mie_table_cloud.nml"
wsl bash -c "cd /mnt/c/Users/PC/Documents/GitHub/I3RC/I3RC-Monte-Carlo-Model/Tools && ./MakeMieTable rural_aerosol_mie.nml"

# Build domain files
Write-Host "Building domain files..." -ForegroundColor Yellow
wsl bash -c "cd /mnt/c/Users/PC/Documents/GitHub/I3RC/I3RC-Monte-Carlo-Model/Tools && ./physicalPropertiesToDomain thin_cloud_domain.nml"
wsl bash -c "cd /mnt/c/Users/PC/Documents/GitHub/I3RC/I3RC-Monte-Carlo-Model/Tools && ./physicalPropertiesToDomain rural_aerosol_proper_domain.nml"

Write-Host "✅ Preparation complete! You can now run the Python simulation script." -ForegroundColor Green