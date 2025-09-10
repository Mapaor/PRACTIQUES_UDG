# I3RC Research Configuration - Complete Setup Guide

## 🎯 **Research Goal Achievement Setup**

You now have a complete setup for systematic studies of:
- **TOPDN**: Extraterrestrial radiation (downward flux at top of atmosphere)
- **BOTDN**: Global radiation (total downward flux at surface)
- **BOTDIF**: Diffuse radiation (scattered downward flux at surface)
- **BOTDIR**: Direct radiation (BOTDN - BOTDIF)

## 📁 **Input Files Created for Your Research**

### ✅ **Backup Files Created**
- **`Input_backup/`**: Complete backup of original input files

### ✅ **Research Configuration Files**

#### 1. **Mie Scattering Table** (Particle Properties)
**File**: `Input/MakeMieTable/mie_table_research.nml`
```fortran
&mie_table_input
 WAVELEN1=0.55,           ! 0.55 µm - middle of solar spectrum
 WAVELEN2=0.55,
 AVGFLAG='C',             ! Fast monochromatic calculation
 PARTYPE='W',             ! Water droplets
 DISTFLAG='G',            ! Gamma size distribution  
 ALPHA=7.0,               ! Typical cloud droplet distribution
 NRETAB=-35,              ! 35 effective radius points (logarithmic)
 SRETAB=2.0,              ! Minimum effective radius (µm)
 ERETAB=25.0,             ! Maximum effective radius (µm)
 MAXRADIUS=100.0,
 phaseFunctionTableFile='./Output/MakeMieTable/cloud_research_0.55um.phasetab'
/
```

#### 2. **Atmospheric Domain** (Extended 0-100 km)
**File**: `Input/PhysicalPropertiesToDomain/cloud_domain_research.nml`
```fortran
&fileNames
 ParticleFileName='./Input/PhysicalPropertiesToDomain/cloud_research.txt',
 ScatTableFiles='./Output/MakeMieTable/cloud_research_0.55um.phasetab',
 outputFileName = "./Output/PhysicalPropertiesToDomain/cloud_research.dom"
/
&profile
 ! Extended atmosphere 0-100 km with realistic temperature profile
 OtherHeights=0.0, 2.0, 5.0, 10.0, 15.0, 20.0, 30.0, 50.0, 70.0, 100.0,
 OtherTemps=288.0, 275.0, 255.0, 220.0, 217.0, 217.0, 230.0, 270.0, 220.0, 180.0,
/
&physicalProperties
 DropNumConc=100.,         ! Typical marine cloud concentration
 RayleighWavelength=0.55,  ! Include molecular scattering
/
```

#### 3. **Cloud Properties** (Variable Optical Thickness)
**File**: `Input/PhysicalPropertiesToDomain/cloud_research.txt`
```
3                         ! Format type 3 (multicomponent)
1 1 9                     ! 1×1 horizontal, 9 vertical levels  
0.1 0.1                   ! Grid spacing (km)
0.0 2.0 5.0 10.0 15.0 20.0 30.0 50.0 70.0 100.0    ! Height levels (km)
288.0 275.0 255.0 220.0 217.0 217.0 230.0 270.0 220.0 180.0  ! Temperatures (K)
1 1 1  1 1 0.1  10.0      ! Cloud layer 1: LWC=0.1 g/m³, Reff=10µm
1 1 2  1 1 0.2  10.0      ! Cloud layer 2: LWC=0.2 g/m³ 
1 1 3  1 1 0.3  10.0      ! Cloud layer 3: LWC=0.3 g/m³ (peak)
...                       ! Decreasing with height
```

#### 4. **Monte Carlo Simulation** (Total Radiation)
**File**: `Input/MonteCarloDriver/MonteCarloDriver_research.nml`
```fortran
&radiativeTransfer
  solarFlux = 1.0,         ! Standard solar constant
  solarMu = 0.5,           ! 60° solar zenith angle (MODIFY FOR YOUR STUDIES)
  surfaceAlbedo = 0.05,    ! Dark surface (MODIFY AS NEEDED)
/
&monteCarlo
  numPhotonsPerBatch = 1000,  ! High accuracy
  numBatches = 1000,          ! 1 million total photons
  iseed = 42,
/
&algorithms
  useRayTracing = .true.,     ! Full ray tracing (total radiation)
/
&fileNames
  domainFileName = "./Output/PhysicalPropertiesToDomain/cloud_research.dom",
  outputFluxFile = "./Output/MonteCarloDriver/Research_Fluxes.out",
  outputNetcdfFile = "./Output/MonteCarloDriver/Research_All_output.nc"
/
```

#### 5. **Diffuse-Optimized Simulation**
**File**: `Input/MonteCarloDriver/MonteCarloDriver_diffuse.nml`
```fortran
&radiativeTransfer
  solarMu = 0.5,           ! KEEP SAME AS MAIN CONFIG
  surfaceAlbedo = 0.05,    ! KEEP SAME AS MAIN CONFIG
/
&algorithms
  useRayTracing = .false., ! Max cross-section method (diffuse-optimized)
/
&fileNames
  outputFluxFile = "./Output/MonteCarloDriver/Research_Diffuse_Fluxes.out",
/
```

## 🚀 **Complete Research Workflow**

### **Step 1: Run Complete Workflow**
```bash
cd /mnt/c/Users/PC/Documents/GitHub/I3RC

# 1. Create scattering properties
./I3RC-Monte-Carlo-Model/Tools/MakeMieTable Input/MakeMieTable/mie_table_research.nml

# 2. Create atmospheric domain  
./I3RC-Monte-Carlo-Model/Tools/PhysicalPropertiesToDomain Input/PhysicalPropertiesToDomain/cloud_domain_research.nml

# 3. Run total radiation simulation
ulimit -s unlimited
./I3RC-Monte-Carlo-Model/Example-Drivers/monteCarloDriver Input/MonteCarloDriver/MonteCarloDriver_research.nml

# 4. Run diffuse-optimized simulation
./I3RC-Monte-Carlo-Model/Example-Drivers/monteCarloDriver Input/MonteCarloDriver/MonteCarloDriver_diffuse.nml
```

### **Step 2: Extract Your Variables**
```bash
# Check TOTAL radiation fluxes
cat Output/MonteCarloDriver/Research_Fluxes.out

# Check DIFFUSE radiation fluxes  
cat Output/MonteCarloDriver/Research_Diffuse_Fluxes.out
```

**Expected Output Format**:
```
!  FLUX AT Z= 100.000   NXO=   1   NYO=   1
!   X      Y           Flux_Up             Flux_Down    <- TOPDN here
  0.050  0.050     0.0234    0.0044     0.8766    0.0044

!  FLUX AT Z=   0.000   NXO=   1   NYO=   1  
!   X      Y           Flux_Up             Flux_Down    <- BOTDN here
  0.050  0.050     0.0856    0.0044     0.7234    0.0044
```

### **Your Research Variables**:
- **TOPDN** = Flux_Down at Z=100.000 in Research_Fluxes.out
- **BOTDN** = Flux_Down at Z=0.000 in Research_Fluxes.out  
- **BOTDIF** = Flux_Down at Z=0.000 in Research_Diffuse_Fluxes.out
- **BOTDIR** = BOTDN - BOTDIF

## 🔧 **Systematic Parameter Studies**

### **Solar Zenith Angle Variations**
Edit `solarMu` in both `MonteCarloDriver_research.nml` and `MonteCarloDriver_diffuse.nml`:
```fortran
solarMu = 1.0    ! 0° (overhead sun)
solarMu = 0.866  ! 30° 
solarMu = 0.5    ! 60°
solarMu = 0.342  ! 70°
solarMu = 0.174  ! 80° (very low sun)
```

### **Optical Thickness Variations**
Edit `cloud_research.txt` mass contents (column 6):
```
# Low optical thickness (τ ≈ 1)
1 1 1  1 1 0.05  10.0
1 1 2  1 1 0.1   10.0
1 1 3  1 1 0.15  10.0

# Medium optical thickness (τ ≈ 5)  
1 1 1  1 1 0.2   10.0
1 1 2  1 1 0.4   10.0
1 1 3  1 1 0.6   10.0

# High optical thickness (τ ≈ 10)
1 1 1  1 1 0.5   10.0
1 1 2  1 1 1.0   10.0
1 1 3  1 1 1.5   10.0
```

### **Surface Albedo Studies**
Edit `surfaceAlbedo` in both configuration files:
```fortran
surfaceAlbedo = 0.05   ! Dark surface (forest, ocean)
surfaceAlbedo = 0.15   ! Grassland
surfaceAlbedo = 0.25   ! Desert
surfaceAlbedo = 0.80   ! Snow/ice
```

## 📊 **Expected Results for Validation**

### **Clear Sky** (no clouds - set all mass contents to 0.0):
- TOPDN ≈ 1.0 (full solar flux)
- BOTDN ≈ 0.8-0.9 (atmospheric absorption)
- BOTDIF ≈ 0.1-0.2 (molecular scattering)
- BOTDIR ≈ 0.7-0.8

### **Thin Clouds** (τ ≈ 1):
- TOPDN ≈ 1.0 
- BOTDN ≈ 0.6-0.7
- BOTDIF ≈ 0.3-0.4  
- BOTDIR ≈ 0.3-0.4

### **Thick Clouds** (τ > 10):
- TOPDN ≈ 1.0
- BOTDN ≈ 0.2-0.4
- BOTDIF ≈ 0.15-0.35 (most radiation is diffuse)
- BOTDIR ≈ 0.05-0.1

## 🐍 **Python Script Framework**

For systematic automation, your Python script should:

1. **Modify input files** (solarMu, mass contents, surfaceAlbedo)
2. **Run workflow** (subprocess calls to bash commands)
3. **Parse output files** (extract flux values from ASCII files)
4. **Store results** (pandas DataFrame with all parameter combinations)

**Key parsing locations**:
- TOPDN: Search for "Z= 100.000" then extract Flux_Down value
- BOTDN: Search for "Z=   0.000" then extract Flux_Down value from total simulation
- BOTDIF: Extract Flux_Down value from diffuse simulation

## ✅ **Ready for Research!**

Your I3RC model setup is now optimized for systematic radiative flux studies. You have:
- ✅ Extended atmosphere (0-100 km) for complete flux calculations
- ✅ Optimized configurations for direct/diffuse separation  
- ✅ Easy parameter modification for systematic studies
- ✅ High-accuracy Monte Carlo settings
- ✅ Research-ready output formats

The model will compute exactly the variables you need (TOPDN, BOTDN, BOTDIF) for your cloud and aerosol optical thickness studies!
