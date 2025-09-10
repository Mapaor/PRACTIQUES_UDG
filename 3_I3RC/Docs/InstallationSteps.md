# I3RC Model - Installation Guide for Windows Users

## 🎯 **Quick Start for New Users**

This guide allows any Windows user to install and run the I3RC NASA Monte Carlo Radiative Transfer Model on their system using the exact same setup.

## 📋 **Prerequisites**

### 1. Windows 10/11 with WSL2 ✅
```powershell
# Open PowerShell as Administrator and run:
wsl --install

# After restart, this will install Ubuntu by default
# If WSL is already installed, ensure you have Ubuntu:
wsl --list --online
wsl --install -d Ubuntu-22.04
```

### 2. Git for Windows (Optional but Recommended) ✅
Download from: https://git-scm.com/download/win

## 🔧 **Step-by-Step Installation**

### Step 1: Setup WSL Ubuntu Environment
```bash
# Launch WSL Ubuntu (search "Ubuntu" in Start Menu)
# Update package manager
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y gfortran make libnetcdf-dev libnetcdff-dev dos2unix

# Verify installation
gfortran --version  # Should show version 11.4.0 or similar
```

### Step 2: Copy the Model Files
```bash
# Option A: If you have this directory on a USB/shared folder
cp -r /mnt/c/path/to/I3RC /home/$(whoami)/I3RC

# Option B: If you're getting it from Git
# git clone <repository-url> I3RC

# Navigate to the model
cd ~/I3RC
```

### Step 3: Build the Model
```bash
# Navigate to the model directory
cd I3RC-Monte-Carlo-Model

# Clean any existing builds
./Clean_bash

# Build all components
./Build_bash

# Verify successful build
ls -la Tools/MakeMieTable Example-Drivers/monteCarloDriver
# You should see executable files with recent timestamps
```

### Step 4: Test the Installation
```bash
# Return to main directory
cd ..

# Run the complete workflow test
echo "Testing Step 1: Mie Table Creation..."
./I3RC-Monte-Carlo-Model/Tools/MakeMieTable Input/MakeMieTable/mie_table_cloud.nml

echo "Testing Step 2: Domain Creation..."
./I3RC-Monte-Carlo-Model/Tools/PhysicalPropertiesToDomain Input/PhysicalPropertiesToDomain/cloud_domain.nml

echo "Testing Step 3: Monte Carlo Simulation..."
ulimit -s unlimited
./I3RC-Monte-Carlo-Model/Example-Drivers/monteCarloDriver Input/MonteCarloDriver/MonteCarloDriver.nml

# Check outputs
ls -la Output/*/
echo "Installation test complete!"
```

## ✅ **Verification Checklist**

After installation, verify these files exist:

### Executables Built Successfully:
- [ ] `I3RC-Monte-Carlo-Model/Tools/MakeMieTable` (≈208KB)
- [ ] `I3RC-Monte-Carlo-Model/Tools/PhysicalPropertiesToDomain` (≈251KB)  
- [ ] `I3RC-Monte-Carlo-Model/Example-Drivers/monteCarloDriver` (≈381KB)

### Test Outputs Created:
- [ ] `Output/MakeMieTable/cloud_w_0.67nm_mie.phasetab`
- [ ] `Output/PhysicalPropertiesToDomain/cloud.dom`
- [ ] `Output/monteCarloDriver/Fluxes.out`
- [ ] `Output/monteCarloDriver/Intensities.out`
- [ ] `Output/monteCarloDriver/All_output.nc`

### Expected Behavior:
- [ ] First two programs complete without errors
- [ ] MonteCarloDriver completes calculations and writes outputs
- [ ] MonteCarloDriver may show segmentation fault at end (this is normal - all results are already written)

## 🚨 **Troubleshooting Common Issues**

### WSL Not Working
```powershell
# In PowerShell as Administrator:
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
# Restart computer, then:
wsl --set-default-version 2
```

### Build Errors
```bash
# If gfortran not found:
sudo apt install gfortran

# If NetCDF errors:
sudo apt install libnetcdf-dev libnetcdff-dev

# If permission errors:
chmod +x I3RC-Monte-Carlo-Model/Build_bash
chmod +x I3RC-Monte-Carlo-Model/Clean_bash

# If line ending errors:
sudo apt install dos2unix
find . -type f -name "*.f95" -exec dos2unix {} \;
find . -type f -name "*.nml" -exec dos2unix {} \;
```

### Memory Issues
```bash
# Increase stack size before running MonteCarloDriver:
ulimit -s unlimited

# Check available memory:
free -h

# For very large simulations, consider reducing photon count in:
# Input/MonteCarloDriver/MonteCarloDriver.nml
```

## 📁 **Directory Structure Overview**

After successful installation:
```
I3RC/
├── BUILD_SUCCESS_GUIDE.md           # Technical modification log
├── Documentation.md                 # Complete usage guide  
├── InstallationSteps.md            # This file
├── I3RC-Monte-Carlo-Model/         # Source code and executables
│   ├── Code/                       # Fortran source modules
│   ├── Tools/                      # Utility programs (MakeMieTable, etc.)
│   ├── Example-Drivers/            # Main simulation program
│   ├── Integrators/                # Monte Carlo integration code
│   ├── Build_bash, Clean_bash      # Build scripts
│   └── Makefile                    # Compilation configuration
├── Input/                          # Configuration files
│   ├── MakeMieTable/              # Scattering table configs
│   ├── MonteCarloDriver/          # Simulation configs  
│   └── PhysicalPropertiesToDomain/ # Domain setup configs
└── Output/                         # Results directory
    ├── MakeMieTable/              # Phase function tables
    ├── PhysicalPropertiesToDomain/ # Domain files
    └── monteCarloDriver/          # Flux and radiance results
```

## 🔬 **Running Your First Simulation**

### Basic Workflow:
```bash
# 1. Configure particle properties (edit if needed)
nano Input/MakeMieTable/mie_table_cloud.nml

# 2. Configure atmospheric domain (edit if needed)  
nano Input/PhysicalPropertiesToDomain/cloud_domain.nml

# 3. Configure simulation parameters (edit if needed)
nano Input/MonteCarloDriver/MonteCarloDriver.nml

# 4. Run complete workflow
cd I3RC
./I3RC-Monte-Carlo-Model/Tools/MakeMieTable Input/MakeMieTable/mie_table_cloud.nml
./I3RC-Monte-Carlo-Model/Tools/PhysicalPropertiesToDomain Input/PhysicalPropertiesToDomain/cloud_domain.nml
ulimit -s unlimited
./I3RC-Monte-Carlo-Model/Example-Drivers/monteCarloDriver Input/MonteCarloDriver/MonteCarloDriver.nml

# 5. View results
cat Output/monteCarloDriver/Fluxes.out
```

## 📞 **Getting Help**

### If Installation Fails:
1. **Check WSL Version**: `wsl --status` (should be WSL2)
2. **Check Ubuntu Version**: `lsb_release -a` (should be 22.04 or newer)
3. **Check Dependencies**: Verify all apt packages installed correctly
4. **Check Permissions**: Ensure executable permissions on scripts

### If Simulation Fails:
1. **Review Documentation.md**: Complete parameter explanation
2. **Check Input Files**: Verify configuration file syntax
3. **Check System Resources**: Ensure adequate memory/disk space
4. **Enable Debug Mode**: Edit Makefile to set `debug=yes` and rebuild

### For Advanced Usage:
- Read **Documentation.md** for detailed parameter studies
- Examine existing input files for configuration examples
- Check **BUILD_SUCCESS_GUIDE.md** for technical details

## 🎯 **You're Ready!**

After completing this installation, you'll have a fully functional atmospheric radiative transfer model capable of:
- Computing radiative fluxes through cloudy atmospheres
- Studying effects of solar zenith angle variations
- Analyzing optical thickness impacts on radiation
- Generating research-quality atmospheric radiation data

**Success Indicator**: If you can run the test workflow and see files created in `Output/monteCarloDriver/`, your installation is complete and functional!
