! Example modification to monteCarloDriver.f95 to enable scattering order tracking
! This shows how to add direct/diffuse separation capabilities to existing I3RC drivers

! Add this after the reportResults call (around line 310):

    ! ===== NEW: Write scattering order results for direct/diffuse separation =====
    ! This outputs files that can be analyzed to separate direct vs diffuse radiation
    ! Direct radiation: scattering order = 0 (no scattering events)  
    ! Diffuse radiation: scattering order >= 1 (one or more scattering events)
    
    if (batchNum == 1) then  ! Only write once per run to avoid file overwrites
      call writeScatteringOrderResults(mcIntegrator, 'monte_carlo_results', status)
      if (.not. stateIsSuccess(status)) then
        call printStatus(status)
        stop
      end if
      
      if (masterProc) then
        print '(A)', '  Scattering order files written:'
        print '(A)', '    monte_carlo_results_fluxUpByOrder.txt'  
        print '(A)', '    monte_carlo_results_fluxDownByOrder.txt'
        print '(A)', '  Use scattering_order_test.py to analyze direct/diffuse components'
      end if
    end if
    ! ============================================================================

! The complete workflow would be:
! 1. Compile the modified I3RC model (with scattering order tracking)
! 2. Run your monte carlo simulation as usual
! 3. New output files will contain scattering order information
! 4. Analyze with the Python script to get direct/diffuse separation

! Example analysis commands:
! python scattering_order_test.py monte_carlo_results

! This will output something like:
!
! === SCATTERING ORDER ANALYSIS ===
! Loaded 1250 upward flux records
! Loaded 980 downward flux records
!
! Upward Flux (TOPDN equivalent):
!   Direct component:   8.45e+02 W/m² (85.3%)
!   Diffuse component:  1.46e+02 W/m² (14.7%)
!   Total upward:       9.91e+02 W/m²
!
! Downward Flux (BOTDN equivalent):
!   Direct component:   7.82e+02 W/m² (78.9%)
!   Diffuse component:  2.09e+02 W/m² (21.1%)
!   Total downward:     9.91e+02 W/m²
!
! Scattering Order Distribution:
!   Order 0: 1.63e+03 W/m² (82.1%) - Direct radiation
!   Order 1: 2.89e+02 W/m² (14.6%) - Single scattering  
!   Order 2: 5.67e+01 W/m² (2.9%)  - Double scattering
!   Order 3: 7.82e+00 W/m² (0.4%)  - Triple scattering
!
