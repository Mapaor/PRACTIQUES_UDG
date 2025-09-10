# I3RC Monte Carlo Model Input Files Documentation

## Overview

The I3RC (Intercomparison of 3D Radiation Codes) Monte Carlo model uses a three-stage workflow with corresponding input file categories:

1. **MakeMieTable**: Generate phase function tables for different particle types
2. **PhysicalPropertiesToDomain**: Convert physical properties to domain files
3. **MonteCarloDriver**: Run the actual radiative transfer simulation

## File Structure

```
Input/
├── MakeMieTable/           # Mie scattering table generation
├── MonteCarloDriver/       # Monte Carlo simulation parameters
└── PhysicalPropertiesToDomain/  # Physical property definitions
```

---

## 1. MakeMieTable Configuration Files

### Purpose
Generate Mie scattering tables (phase function tables) for spherical particles using Mie theory. These tables contain extinction coefficients, single scattering albedo, and Legendre coefficients of the phase function as functions of effective radius.

### File Format: `*.nml` (Fortran Namelist)

### Key Parameters

#### &mie_table_input Namelist

**Wavelength Settings:**
- `WAVELEN1`, `WAVELEN2` (μm): Start and end wavelength of spectral band
  - Single wavelength: Set both to same value (e.g., 0.67 μm)
  - Spectral band: Set range (e.g., 0.55-0.75 μm)

- `AVGFLAG`: Spectral averaging method
  - `'C'`: Use center wavelength (faster)
  - `'A'`: Average over band (more accurate)

- `DELTAWAVE` (μm): Wavelength interval for averaging (only used if AVGFLAG='A')

**Particle Type:**
- `PARTYPE`: Particle composition
  - `'W'`: Water droplets (index of refraction from tables)
  - `'I'`: Ice crystals (index of refraction from tables)  
  - `'A'`: Aerosols (user-specified index of refraction)

**Aerosol Properties (PARTYPE='A' only):**
- `RINDEX`: Complex refractive index (real, imaginary)
  - Format: `(real_part, -imaginary_part)`
  - Example: `(1.53, -0.025)` for absorbing aerosol
- `PARDENS` (g/cm³): Particle bulk density

**Size Distribution:**
- `DISTFLAG`: Distribution type
  - `'G'`: Gamma distribution: n(r) = a×r^α×exp(-b×r)
  - `'L'`: Lognormal distribution

- `ALPHA`: Shape parameter
  - Gamma: α shape parameter (typical values: 1-15)
  - Lognormal: log standard deviation (typical values: 0.3-0.8)

**Effective Radius Tabulation:**
- `NRETAB`: Number of effective radius points
  - Positive: Linear spacing
  - Negative: Logarithmic spacing (recommended)
- `SRETAB` (μm): Starting effective radius
- `ERETAB` (μm): Ending effective radius
- `MAXRADIUS` (μm): Maximum particle radius in size distribution

**Output:**
- `phaseFunctionTableFile`: Path to output phase function table

### Example Configurations

#### Cloud Droplets (Water)
```fortran
&mie_table_input
 WAVELEN1=0.67, WAVELEN2=0.67,
 AVGFLAG='C',
 PARTYPE='W',
 DISTFLAG='G',
 ALPHA=7.0,
 NRETAB=-35,
 SRETAB=1.0, ERETAB=30.0,
 MAXRADIUS=100.0,
 phaseFunctionTableFile='./Output/MakeMieTable/cloud_w_0.67nm_mie.phasetab'
/
```

#### Rural Aerosol
```fortran
&mie_table_input
 WAVELEN1=0.67, WAVELEN2=0.67,
 AVGFLAG='C',
 PARTYPE='A',
 RINDEX=(1.53,-0.025),
 PARDENS=1.8,
 DISTFLAG='L',
 ALPHA=0.60,
 NRETAB=-20,
 SRETAB=0.05, ERETAB=1.5,
 MAXRADIUS=8.0,
 phaseFunctionTableFile='./Output/MakeMieTable/rural_aerosol_w_0.67nm_mie.phasetab'
/
```

---

## 2. PhysicalPropertiesToDomain Files

### Purpose
Define the 3D distribution of particle properties (mass content and effective radius) and convert them to domain files readable by the Monte Carlo model.

### File Types

#### A. Physical Properties Text Files (`*.txt`)

**Format:**
```
filekind
nx ny nz
delx dely
z1 z2 z3 ... z(nz+1)
T1 T2 T3 ... T(nz+1)
ix iy iz ncomp ptype1 mass1 reff1 [ptype2 mass2 reff2 ...]
...
```

**Parameters:**
- `filekind`: File type (3 = physical properties)
- `nx, ny, nz`: Grid dimensions
- `delx, dely` (km): Horizontal grid spacing
- `z1...z(nz+1)` (km): Vertical level heights
- `T1...T(nz+1)` (K): Temperature profile
- Grid cell data:
  - `ix, iy, iz`: Grid cell indices (1-based)
  - `ncomp`: Number of particle components in cell
  - `ptype`: Particle type (1=water, 2=ice, other=aerosol)
  - `mass` (g/m³): Mass concentration
  - `reff` (μm): Effective radius

**Example (Thin Cloud):**
```
3                    # File type
1 1 3               # 1×1×3 grid
0.1 0.1             # 0.1 km grid spacing
0.5 0.65 0.8        # Heights: 0.5, 0.65, 0.8 km
283.0 282.7 282.4   # Temperatures
1 1 1  1 1 0.0  10.0    # Cell (1,1,1): water, 0.0 g/m³, 10 μm
1 1 2  1 1 0.009 10.0   # Cell (1,1,2): water, 0.009 g/m³, 10 μm  
1 1 3  1 1 0.0  10.0    # Cell (1,1,3): water, 0.0 g/m³, 10 μm
```

#### B. Domain Configuration Files (`*_domain.nml`)

**&fileNames Namelist:**
- `ParticleFileName`: Path to physical properties text file
- `ScatTableFiles`: Path(s) to phase function table(s)
- `MolecAbsFileName`: Molecular absorption file (usually empty)
- `outputFileName`: Output domain file path

**&profile Namelist:**
- `OtherHeights` (km): Additional height levels
- `OtherTemps` (K): Temperatures at additional levels

**&physicalProperties Namelist:**
- `DropNumConc` (cm⁻³): Cloud droplet number concentration
- `RayleighWavelength` (μm): Wavelength for molecular scattering (≤0 to disable)

### Common Configurations

#### Thin Cloud (τ ≈ 0.2)
- Single layer with low mass concentration (0.009 g/m³)
- Large droplets (10 μm effective radius)
- Creates optical depth ≈ 0.2

#### Rural Aerosol (τ ≈ 0.2)  
- Single layer with very low mass concentration (0.001 g/m³)
- Small particles (0.5 μm effective radius)
- Creates optical depth ≈ 0.2

---

## 3. MonteCarloDriver Configuration Files

### Purpose
Control the Monte Carlo radiative transfer simulation parameters, including solar geometry, algorithm choices, and output options.

### File Format: `*.nml` (Fortran Namelist)

### Key Namelists

#### &radiativeTransfer
**Solar Conditions:**
- `solarFlux`: Incident solar flux normalization (typically 1.0)
- `solarMu`: Cosine of solar zenith angle
  - Range: 0.087 (85°) to 1.0 (0°)
  - Calculate: cos(zenith_angle × π/180)
- `solarAzimuth` (degrees): Solar azimuth direction (0 = +x direction)

**Surface:**
- `surfaceAlbedo`: Surface reflectance (0.0 = black surface)

**Intensity Calculations:**
- `intensityMus`: Cosines of viewing directions
- `intensityPhis`: Azimuth angles of viewing directions

#### &monteCarlo
**Simulation Size:**
- `numPhotonsPerBatch`: Photons per batch (affects memory usage)
- `numBatches`: Number of batches (affects total photons and precision)
- **Total photons = numPhotonsPerBatch × numBatches**

**Random Number Generation:**
- `iseed`: Random seed (change for different realizations)
- `nPhaseintervals`: Phase function resolution (10001 recommended)

#### &algorithms
**Ray Tracing:**
- `useRayTracing`: Use ray tracing (true) vs. max cross-section (false)
  - Ray tracing: More accurate, slower
  - Max cross-section: Faster, less accurate for complex geometry

**Variance Reduction:**
- `useRussianRoulette`: Kill weak photons to speed simulation
- `useRussianRouletteForIntensity`: Russian roulette for intensity calculations
- `zetaMin`: Minimum weight threshold (0.3 recommended)

**Advanced Options:**
- `useHybridPhaseFunsForIntenCalcs`: Smoothed phase functions for intensity
- `limitIntensityContributions`: Redistribute large intensity contributions

#### &fileNames
**Input:**
- `domainFileName`: Path to domain file (from PhysicalPropertiesToDomain)

**Output:**
- `outputRadFile`: Intensity output file
- `outputFluxFile`: Flux output file
- `outputAbsProfFile`: Absorption profile file
- `outputNetcdfFile`: NetCDF output file

#### &output
**Control Output:**
- `reportAbsorptionProfile`: Include absorption profiles
- `reportVolumeAbsorption`: Include 3D absorption (large files)

### Solar Zenith Angle Examples

| Zenith Angle | solarMu | Description |
|--------------|---------|-------------|
| 0° | 1.000000 | Overhead sun |
| 30° | 0.866025 | High sun |
| 45° | 0.707107 | Mid-day |
| 60° | 0.500000 | Low sun |
| 75° | 0.258819 | Very low sun |
| 85° | 0.087156 | Grazing sun |

### Typical Simulation Settings

#### High Precision Research
```fortran
numPhotonsPerBatch = 1000
numBatches = 1000
! Total: 1,000,000 photons
```

#### Quick Testing
```fortran
numPhotonsPerBatch = 100
numBatches = 10
! Total: 1,000 photons
```

#### Production Runs
```fortran
numPhotonsPerBatch = 500
numBatches = 200
! Total: 100,000 photons
```

---

## 4. Workflow and Dependencies

### Complete Simulation Workflow

1. **Generate Phase Function Tables**
   ```bash
   ./MakeMieTable < Input/MakeMieTable/cloud_mie.nml
   ./MakeMieTable < Input/MakeMieTable/rural_aerosol_mie.nml
   ```

2. **Create Domain Files**
   ```bash
   ./PhysicalPropertiesToDomain < Input/PhysicalPropertiesToDomain/cloud_domain.nml
   ./PhysicalPropertiesToDomain < Input/PhysicalPropertiesToDomain/rural_aerosol_proper_domain.nml
   ```

3. **Run Monte Carlo Simulation**
   ```bash
   ./MonteCarloDriver < Input/MonteCarloDriver/thin_cloud.nml
   ./MonteCarloDriver < Input/MonteCarloDriver/rural_aerosol_proper.nml
   ```

### File Dependencies

```
MIE TABLE (.phasetab) ←── MakeMieTable ←── mie_table_*.nml
     ↓
DOMAIN FILE (.dom) ←── PhysicalPropertiesToDomain ←── *_domain.nml + *.txt
     ↓  
SIMULATION OUTPUT ←── MonteCarloDriver ←── MonteCarloDriver_*.nml
```

---

## 5. Parameter Tuning Guidelines

### Optical Depth Control

**For Clouds (τ ≈ 0.2):**
- Adjust mass concentration in `.txt` file
- Typical: 0.005-0.015 g/m³ for 10 μm droplets

**For Aerosols (τ ≈ 0.2):**
- Adjust mass concentration in `.txt` file  
- Typical: 0.0005-0.002 g/m³ for 0.5 μm particles

### Precision vs. Speed

**High Precision:**
- More photons (1M+)
- Ray tracing enabled
- Fine phase function resolution

**Fast Testing:**
- Fewer photons (1K-10K)
- Max cross-section method
- Coarse resolution

### Physical Realism

**Cloud Properties:**
- Effective radius: 5-20 μm (typical)
- Mass concentration: 0.01-1.0 g/m³
- Gamma distribution (α = 7)

**Aerosol Properties:**
- Effective radius: 0.1-2.0 μm
- Mass concentration: 0.001-0.1 g/m³
- Lognormal distribution (σ = 0.3-0.8)

---

## 6. Common Configurations Summary

### Research-Ready Configurations

1. **thin_cloud**: Thin water cloud (τ ≈ 0.2, reff = 10 μm)
2. **rural_aerosol_proper**: Continental aerosol (τ ≈ 0.2, reff = 0.5 μm)

### Quick Test Configurations

1. **minimal_aerosol_test**: Minimal aerosol for fast testing
2. **clear_sky**: Clear sky (no particles)

### Output Files Generated

- **Fluxes_*.out**: Upward/downward fluxes
- **Intensities_*.out**: Radiances in specified directions
- **Absorption_*.out**: Absorption profiles
- **All_output_*.nc**: Complete NetCDF output
- **Diffuse_Fluxes.out**: Direct/diffuse separation (custom output)

This documentation covers all essential parameters for customizing I3RC Monte Carlo simulations. Modify the `.nml` and `.txt` files according to your research needs while maintaining physical consistency.
