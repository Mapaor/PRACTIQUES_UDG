#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Creates I3RC aerosol configuration files for different optical depth scenarios
.DESCRIPTION
    Generates complete configuration sets for aerosols with specified optical depths
.PARAMETER Name
    Name for the configuration (e.g., "thin_aerosol")
.PARAMETER OpticalDepth
    Target optical depth (e.g., 0.2, 0.5, 1.0, 2.0, 5.0)
.PARAMETER LayerThickness
    Aerosol layer thickness in km (default: 2.0 for typical boundary layer)
.PARAMETER EffectiveRadius
    Aerosol effective radius in micrometers (default: 0.5)
.PARAMETER AerosolType
    Type of aerosol: "dust", "urban", "maritime" (default: "dust")
.EXAMPLE
    .\create_aerosol_config.ps1 -Name "thin_aerosol" -OpticalDepth 0.2
    .\create_aerosol_config.ps1 -Name "thick_aerosol" -OpticalDepth 2.0 -AerosolType "urban"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Name,
    
    [Parameter(Mandatory=$true)]
    [double]$OpticalDepth,
    
    [Parameter(Mandatory=$false)]
    [double]$LayerThickness = 2.0,
    
    [Parameter(Mandatory=$false)]
    [double]$EffectiveRadius = 0.5,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("dust", "rural", "urban", "maritime")]
    [string]$AerosolType = "rural"
)

$I3RC_ROOT = "C:\Users\PC\Documents\GitHub\I3RC"
$INPUT_PHYS_DIR = "$I3RC_ROOT\Input\PhysicalPropertiesToDomain"
$INPUT_MC_DIR = "$I3RC_ROOT\Input\MonteCarloDriver"

Write-Host "Creating I3RC aerosol configuration for '$Name' with optical depth $OpticalDepth" -ForegroundColor Cyan

# Aerosol properties based on type
$aerosolProperties = @{
    "dust" = @{
        "density" = 2.6       # g/cm³
        "phaseTable" = "aerosol_w_0.67nm_mie.phasetab"
        "massExtinctionCoeff" = 0.8  # m²/g - dust has high scattering
    }
    "rural" = @{
        "density" = 1.8       # g/cm³ 
        "phaseTable" = "rural_aerosol_w_0.67nm_mie.phasetab"
        "massExtinctionCoeff" = 3.0  # m²/g - rural has more absorption
    }
    "urban" = @{
        "density" = 1.8       # g/cm³ 
        "phaseTable" = "rural_aerosol_w_0.67nm_mie.phasetab"
        "massExtinctionCoeff" = 4.0  # m²/g - urban has highest absorption
    }
    "maritime" = @{
        "density" = 2.2       # g/cm³
        "phaseTable" = "aerosol_w_0.67nm_mie.phasetab"
        "massExtinctionCoeff" = 2.0  # m²/g - maritime moderate properties
    }
}

$density = $aerosolProperties[$AerosolType]["density"]
$phaseTable = $aerosolProperties[$AerosolType]["phaseTable"]
$massExtinctionCoeff = $aerosolProperties[$AerosolType]["massExtinctionCoeff"]

# Calculate mass content needed for target optical depth
# For aerosols, use empirical relationship: τ = α × Mass × Δz
# where α is the mass extinction coefficient (m²/g)
$delta_z_km = $LayerThickness  # in km

# Mass content (g/m³) = τ / (α × Δz_km)
$MassContent = $OpticalDepth / ($massExtinctionCoeff * $delta_z_km)

Write-Host "Calculated parameters:" -ForegroundColor Yellow
Write-Host "  Aerosol type: $AerosolType" -ForegroundColor Gray
Write-Host "  Layer thickness: $LayerThickness km" -ForegroundColor Gray  
Write-Host "  Effective radius: $EffectiveRadius μm" -ForegroundColor Gray
Write-Host "  Particle density: $density g/cm³" -ForegroundColor Gray
Write-Host "  Mass extinction coefficient: $massExtinctionCoeff m²/g" -ForegroundColor Gray
Write-Host "  Mass content: $($MassContent.ToString('F6')) g/m³" -ForegroundColor Gray

# Create physical properties file for aerosols
# Using format 3 (multicomponent) with aerosol type 1
$physPropsContent = @"
3
1 1 3
 0.1 0.1
 0.0 $LayerThickness $(2*$LayerThickness) 
 288.0 285.0 282.0 
 1 1 1  1 1 0.0  $EffectiveRadius
 1 1 2  1 1 $($MassContent.ToString('F6'))  $EffectiveRadius
 1 1 3  1 1 0.0  $EffectiveRadius
"@

$physPropsFile = "$INPUT_PHYS_DIR\${Name}.txt"
$physPropsContent | Out-File -FilePath $physPropsFile -Encoding ASCII
Write-Host "✓ Created: $physPropsFile" -ForegroundColor Green

# Create domain configuration file
$domainConfigContent = @"
! Namelist input file for PhysicalPropertiesToDomain
! Generated for $Name ($AerosolType aerosol) with optical depth $OpticalDepth

&fileNames
 ! Atmospheric optical properties file name:
 ParticleFileName='./Input/PhysicalPropertiesToDomain/${Name}.txt',
 ! Scattering (phase function) table file names:
 ScatTableFiles='./Output/MakeMieTable/$phaseTable',
 ! Molecular absorption extinction profile file name (or ''):
 MolecAbsFileName='',
 ! Name of domain (output) file
 outputFileName = "./Output/PhysicalPropertiesToDomain/${Name}.dom"
/ 

&profile
!
! Other height levels (km):
 OtherHeights=10.0,
!
! Temperatures at other height levels (km):
 OtherTemps=270.0,
/ 

&physicalProperties
 ! Aerosol number concentration (not used for multicomponent file):
 DropNumConc=1000.,
 ! Wavelength for molecular Rayleigh scattering (<=0 for none):
 RayleighWavelength=0.0,
/
"@

$domainConfigFile = "$INPUT_PHYS_DIR\${Name}_domain.nml"
$domainConfigContent | Out-File -FilePath $domainConfigFile -Encoding ASCII
Write-Host "✓ Created: $domainConfigFile" -ForegroundColor Green

# Create Monte Carlo configuration file
$mcConfigContent = @"
! Namelist input file for monteCarloDriver
! Generated for $Name ($AerosolType aerosol) with optical depth $OpticalDepth

&radiativeTransfer
  ! Normalization 
  solarFlux = 1.0, 
  ! Cosine of the solar zenith angle
  solarMu = 0.5,  
  ! Azimuthal direction of incoming photons (0 = +x direction)
  solarAzimuth = 0.0
  !
  surfaceAlbedo = 0.0, 
  ! Cosine of directions at which to compute intensity (+ve)
  !   The number should match the number of azimuths below.  
  intensityMus = 1.0, 0.5, 0.5
  ! Azimuth of direction at which to compute intensity
  intensityPhis = 0.0, 0.0, 180.0 
/  

&monteCarlo
  ! The number of photons per batch in the MC calculation
  numPhotonsPerBatch = 50, 
  ! The number of batches in the MC calculation
  !   Total number of photons used is numPhotonsPerBatch * numBatches
  numBatches = 50, 
  ! Random number seed (used in conjunction with batch number)
  iseed = 10, 
  ! Number of equal probability angles to compute in the inverse phase function
  nPhaseintervals = 10001
/

&algorithms
  ! Photon tracing (T) or max cross-section (F)? 
  useRayTracing = .true., 
  ! Use Russian roulette (kill/refresh weak photons)? 
  useRussianRoulette = .false.,
  useRussianRouletteForIntensity = .false.,  
  zetaMin = 0.3, 
  useHybridPhaseFunsForIntenCalcs = .false., 
  hybridPhaseFunWidth = 0., numOrdersOrigPhaseFunIntenCalcs = 0, 
  limitIntensityContributions = .false., 
  maxIntensityContribution = 1.0, 
/

&fileNames
  ! The domain file describing the distribution of optical properties
  domainFileName = "./Output/PhysicalPropertiesToDomain/${Name}.dom", 
  ! Name of ascii file contain intensity at specified direction
  outputRadFile = "./Output/MonteCarloDriver/Intensities_${Name}.out", 
  ! Name of ascii file with pixel-by-pixel fluxes
  outputFluxFile = "./Output/MonteCarloDriver/Fluxes_${Name}.out", 
  ! Name of ascii file for the absorption profile
  outputAbsProfFile = ".//Output/MonteCarloDriver/Absorption_${Name}.out",
  ! Netcdf output file
  outputNetcdfFile = ".//Output/MonteCarloDriver/All_output_${Name}.nc"
/ 

&output 
  ! Include the domain-mean flux divergence profile?
  reportAbsorptionProfile = .false., 
  ! Include the cell-by-cell flux divergence? 
  !   This is usually the largest output field by far 
  reportVolumeAbsorption = .false. 
  !
/
"@

$mcConfigFile = "$INPUT_MC_DIR\${Name}.nml"
$mcConfigContent | Out-File -FilePath $mcConfigFile -Encoding ASCII
Write-Host "✓ Created: $mcConfigFile" -ForegroundColor Green

Write-Host "`nAerosol configuration '$Name' created successfully!" -ForegroundColor Green
Write-Host "To run simulation: .\run_i3rc_simulation.ps1 -ConfigName '$Name'" -ForegroundColor Yellow
Write-Host "Expected results for $AerosolType aerosol (τ=$OpticalDepth):" -ForegroundColor Gray

# Provide theoretical expectations for aerosols
$directTransmission = [Math]::Exp(-$OpticalDepth) * 100
Write-Host "  Direct transmission: ~$($directTransmission.ToString('F1'))%" -ForegroundColor Gray
Write-Host "  Note: Aerosols typically have more forward scattering than clouds" -ForegroundColor Gray
