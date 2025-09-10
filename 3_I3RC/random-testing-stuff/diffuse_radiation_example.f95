! Example modification to monteCarloDriver.f95 to access diffuse radiation
! This shows how to use the new reportResultsWithDiffuse functionality

program diffuseRadiationExample
  ! This example shows how to modify an I3RC driver to access diffuse radiation
  ! components alongside the standard radiative fluxes
  
  use monteCarloRadiativeTransfer
  
  implicit none
  
  ! Standard flux variables (as before)
  real :: meanFluxUp, meanFluxDown, meanFluxAbsorbed
  real, dimension(:, :), allocatable :: fluxUp, fluxDown, fluxAbsorbed
  
  ! NEW: Diffuse radiation variables
  real :: meanFluxUpDiffuse, meanFluxDownDiffuse
  real, dimension(:, :), allocatable :: fluxUpDiffuse, fluxDownDiffuse
  
  ! Other variables...
  type(integrator) :: mcIntegrator
  type(ErrorMessage) :: status
  
  ! ... (setup code as in original driver) ...
  
  ! Allocate arrays including diffuse components
  allocate(fluxUp(numX, numY), fluxDown(numX, numY), fluxAbsorbed(numX, numY))
  allocate(fluxUpDiffuse(numX, numY), fluxDownDiffuse(numX, numY))
  
  ! ... (Monte Carlo computation) ...
  
  ! NEW: Get both standard and diffuse radiation results
  call reportResultsWithDiffuse(mcIntegrator, &
         meanFluxUp, meanFluxDown, meanFluxAbsorbed,       &
         fluxUp(:, :), fluxDown(:, :), fluxAbsorbed(:, :), &
         meanFluxUpDiffuse, meanFluxDownDiffuse,           &
         fluxUpDiffuse(:, :), fluxDownDiffuse(:, :),       &
         status = status)
  
  ! Calculate direct components
  real :: meanFluxUpDirect, meanFluxDownDirect
  real, dimension(:, :), allocatable :: fluxUpDirect, fluxDownDirect
  
  allocate(fluxUpDirect(numX, numY), fluxDownDirect(numX, numY))
  
  ! Direct = Total - Diffuse
  meanFluxUpDirect = meanFluxUp - meanFluxUpDiffuse
  meanFluxDownDirect = meanFluxDown - meanFluxDownDiffuse
  fluxUpDirect(:, :) = fluxUp(:, :) - fluxUpDiffuse(:, :)
  fluxDownDirect(:, :) = fluxDown(:, :) - fluxDownDiffuse(:, :)
  
  ! Output results
  print *, '=== RADIATIVE FLUX ANALYSIS ==='
  print *, 'Total upward flux:   ', meanFluxUp
  print *, 'Direct upward flux:  ', meanFluxUpDirect
  print *, 'Diffuse upward flux: ', meanFluxUpDiffuse
  print *, 'Direct fraction:     ', meanFluxUpDirect/meanFluxUp * 100., '%'
  print *, ''
  print *, 'Total downward flux:   ', meanFluxDown
  print *, 'Direct downward flux:  ', meanFluxDownDirect  
  print *, 'Diffuse downward flux: ', meanFluxDownDiffuse
  print *, 'Direct fraction:       ', meanFluxDownDirect/meanFluxDown * 100., '%'
  
  ! You can now access:
  ! - fluxUp, fluxDown: Total radiative fluxes (as before)
  ! - fluxUpDiffuse, fluxDownDiffuse: Diffuse radiation components (NEW)
  ! - fluxUpDirect, fluxDownDirect: Direct radiation (Total - Diffuse)
  
  ! These arrays can be written to NetCDF files, used in calculations, etc.
  
end program diffuseRadiationExample
