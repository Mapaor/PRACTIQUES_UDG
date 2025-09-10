! Simplified Monte Carlo Driver with Diffuse Output
! Based on I3RC Monte Carlo Model
program monteCarloDriver_simple
  use ErrorMessages
  use monteCarloRadiativeTransfer
  use userInterface
  use opticalProperties
  implicit none
  
  ! Variables
  character(len=256) :: namelistFileName = "test_diffuse.nml"
  character(len=256) :: domainFileName, outputFileName
  integer :: numPhotonsPerBatch, numBatches
  real :: solarFlux, solarMu, solarAzimuth, surfaceAlbedo
  real, dimension(:, :, :, :), allocatable :: fluxUpStats, fluxDownStats, fluxAbsorbedStats
  real, dimension(:, :, :, :), allocatable :: diffuseFluxUpStats, diffuseFluxDownStats
  real, dimension(:), allocatable :: xPosition, yPosition, zPosition
  type(domain), dimension(:), allocatable :: opticalPropertiesDomain
  real, dimension(:), allocatable :: intensityMus, intensityPhis
  real, dimension(:, :, :, :), allocatable :: RadianceStats
  integer :: i, j
  
  ! Read namelist
  namelist /monteCarlo/ &
       domainFileName, outputFileName, &
       numPhotonsPerBatch, numBatches, &
       solarFlux, solarMu, solarAzimuth, surfaceAlbedo
  
  print *, "Reading namelist..."
  open(unit=10, file=namelistFileName, status='old')
  read(10, nml=monteCarlo)
  close(10)
  
  print *, "Domain file: ", trim(domainFileName)
  print *, "Photons per batch: ", numPhotonsPerBatch
  print *, "Number of batches: ", numBatches
  print *, "Solar Mu: ", solarMu
  
  ! Read domain
  call readOpticalPropertiesDomain(opticalPropertiesDomain, xPosition, yPosition, zPosition, &
                                  trim(domainFileName))
  
  ! Allocate arrays
  allocate(fluxUpStats(size(xPosition)-1, size(yPosition)-1, 1, 2))
  allocate(fluxDownStats(size(xPosition)-1, size(yPosition)-1, 1, 2))
  allocate(fluxAbsorbedStats(size(xPosition)-1, size(yPosition)-1, 1, 2))
  allocate(diffuseFluxUpStats(size(xPosition)-1, size(yPosition)-1, 1, 2))
  allocate(diffuseFluxDownStats(size(xPosition)-1, size(yPosition)-1, 1, 2))
  
  ! Initialize
  fluxUpStats = 0.0
  fluxDownStats = 0.0
  fluxAbsorbedStats = 0.0
  diffuseFluxUpStats = 0.0
  diffuseFluxDownStats = 0.0
  
  ! Run Monte Carlo
  print *, "Running Monte Carlo simulation..."
  call doMonteCarloRadiativeTransfer( &
       opticalPropertiesDomain, xPosition, yPosition, zPosition, &
       numPhotonsPerBatch, numBatches, &
       solarFlux, solarMu, solarAzimuth, surfaceAlbedo, &
       fluxUpStats, fluxDownStats, fluxAbsorbedStats, &
       diffuseFluxUpStats=diffuseFluxUpStats, &
       diffuseFluxDownStats=diffuseFluxDownStats)
  
  ! Write standard output
  call writeSimpleResults(trim(outputFileName), fluxUpStats, fluxDownStats, fluxAbsorbedStats)
  
  ! Write diffuse output
  call writeDiffuseResults("Diffuse_Fluxes.out", diffuseFluxUpStats, diffuseFluxDownStats)
  
  print *, "Simulation complete. Check Fluxes.out and Diffuse_Fluxes.out"
  
end program monteCarloDriver_simple

subroutine writeSimpleResults(fileName, fluxUp, fluxDown, fluxAbsorbed)
  implicit none
  character(len=*), intent(in) :: fileName
  real, dimension(:, :, :, :), intent(in) :: fluxUp, fluxDown, fluxAbsorbed
  
  open(unit=20, file=fileName, status='replace')
  write(20, '(a)') "# Flux results: Up, Down, Absorbed (mean ± std_err)"
  write(20, '(3(f10.4," ± ",f8.4,2x))') &
       fluxUp(1,1,1,1), fluxUp(1,1,1,2), &
       fluxDown(1,1,1,1), fluxDown(1,1,1,2), &
       fluxAbsorbed(1,1,1,1), fluxAbsorbed(1,1,1,2)
  close(20)
end subroutine writeSimpleResults

subroutine writeDiffuseResults(fileName, diffuseFluxUp, diffuseFluxDown)
  implicit none
  character(len=*), intent(in) :: fileName
  real, dimension(:, :, :, :), intent(in) :: diffuseFluxUp, diffuseFluxDown
  
  open(unit=21, file=fileName, status='replace')
  write(21, '(a)') "# Diffuse flux results (scattering order >= 1)"
  write(21, '(a)') "# Up_Diffuse, Down_Diffuse (mean ± std_err)"
  write(21, '(2(f10.4," ± ",f8.4,2x))') &
       diffuseFluxUp(1,1,1,1), diffuseFluxUp(1,1,1,2), &
       diffuseFluxDown(1,1,1,1), diffuseFluxDown(1,1,1,2)
  close(21)
end subroutine writeDiffuseResults
