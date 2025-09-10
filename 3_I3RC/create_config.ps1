#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Creates I3RC configuration files for different optical depth scenarios
.DESCRIPTION
    Generates complete configuration sets (physical properties, domain config, MC config) 
    for clouds with specified optical depths
.PARAMETER Name
    Name for the configuration (e.g., "medium_cloud")
.PARAMETER OpticalDepth
    Target optical depth (e.g., 0.2, 0.5, 1.0, 2.0, 5.0)
.PARAMETER LayerThickness
    Cloud layer thickness in km (default: 0.15)
.PARAMETER EffectiveRadius
    Droplet effective radius in micrometers (default: 10.0)
.EXAMPLE
    .\create_config.ps1 -Name "medium_cloud" -OpticalDepth 1.0
    .\create_config.ps1 -Name "thick_cloud" -OpticalDepth 5.0 -LayerThickness 0.3
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Name,
    
    [Parameter(Mandatory=$true)]
    [double]$OpticalDepth,
    
    [Parameter(Mandatory=$false)]
    [double]$LayerThickness = 0.15,
    
    [Parameter(Mandatory=$false)]
    [double]$EffectiveRadius = 10.0
)

$I3RC_ROOT = "C:\Users\PC\Documents\GitHub\I3RC"
$INPUT_PHYS_DIR = "$I3RC_ROOT\Input\PhysicalPropertiesToDomain"
$INPUT_MC_DIR = "$I3RC_ROOT\Input\MonteCarloDriver"

Write-Host "Creating I3RC configuration for '$Name' with optical depth $OpticalDepth" -ForegroundColor Cyan

# Calculate liquid water content needed for target optical depth
# Formula: τ = (3/2) × LWC × Δz / (ρ_water × r_eff)
# Rearranged: LWC = τ × (ρ_water × r_eff) / ((3/2) × Δz)
$rho_water = 1000.0  # kg/m³
$r_eff_m = $EffectiveRadius * 1e-6  # convert μm to m
$delta_z = $LayerThickness * 1000.0  # convert km to m

$LWC = $OpticalDepth * ($rho_water * $r_eff_m) / (1.5 * $delta_z)
$LWC_g_per_m3 = $LWC * 1000.0  # convert kg/m³ to g/m³

Write-Host "Calculated parameters:" -ForegroundColor Yellow
Write-Host "  Layer thickness: $LayerThickness km" -ForegroundColor Gray
Write-Host "  Effective radius: $EffectiveRadius μm" -ForegroundColor Gray
Write-Host "  Liquid water content: $($LWC_g_per_m3.ToString('F6')) g/m³" -ForegroundColor Gray

# Create physical properties file
$physPropsContent = @"
3
1 1 3
 0.1 0.1
 0.5 $(0.5 + $LayerThickness) $(0.5 + 2*$LayerThickness) 
 283.0 282.7 282.4 
 1 1 1  1 1 0.0  $EffectiveRadius
 1 1 2  1 1 $($LWC_g_per_m3.ToString('F6'))  $EffectiveRadius
 1 1 3  1 1 0.0  $EffectiveRadius
"@

$physPropsFile = "$INPUT_PHYS_DIR\${Name}.txt"
$physPropsContent | Out-File -FilePath $physPropsFile -Encoding ASCII
Write-Host "✓ Created: $physPropsFile" -ForegroundColor Green

# Create domain configuration file
$domainConfigContent = @"
! Namelist input file for PhysicalPropertiesToDomain
! Generated for $Name with optical depth $OpticalDepth

&fileNames
 ! Atmospheric optical properties file name:
 ParticleFileName='./Input/PhysicalPropertiesToDomain/${Name}.txt',
 ! Scattering (phase function) table file names:
 ScatTableFiles='./Output/MakeMieTable/cloud_w_0.67nm_mie.phasetab',
 ! Molecular absorption extinction profile file name (or ''):
 MolecAbsFileName='',
 ! Name of domain (output) file
 outputFileName = "./Output/PhysicalPropertiesToDomain/${Name}.dom"
/ 

&profile
!
! Other height levels (km):
 OtherHeights=0.0,
!
! Temperatures at other height levels (km):
 OtherTemps=288.0,
/ 

&physicalProperties
 ! Cloud droplet number concentration (cm^-3) for a 1 parameter LWC file:
 DropNumConc=100.,
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
! Generated for $Name with optical depth $OpticalDepth

&radiativeTransfer
  ! Normalization 
  solarFlux = 1.0, 
  ! Cosine of the solar zenith angle
  solarMu = 0.5,  
  ! Azimuthal direction of incoming photons (0 = +x direction)
  solarAzimuth = 0.0
  !
  surfaceAlbedo = 0.2, 
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

Write-Host "`nConfiguration '$Name' created successfully!" -ForegroundColor Green
Write-Host "To run simulation: .\run_i3rc_simulation.ps1 -ConfigName '$Name'" -ForegroundColor Yellow
Write-Host "Expected results for τ=$OpticalDepth :" -ForegroundColor Gray

# Provide theoretical expectations
$directTransmission = [Math]::Exp(-$OpticalDepth) * 100
$totalTransmission = 90 + ($directTransmission * 0.1)  # Rough estimate
Write-Host "  Direct transmission: ~$($directTransmission.ToString('F1'))%" -ForegroundColor Gray
Write-Host "  Total transmission: ~$($totalTransmission.ToString('F1'))%" -ForegroundColor Gray
"@

$createConfigFile = "$I3RC_ROOT\create_config.ps1"
$createConfigContent | Out-File -FilePath $createConfigFile -Encoding ASCII
Write-Host "✓ Created: $createConfigFile" -ForegroundColor Green
