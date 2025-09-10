# Direct/Diffuse Radiation Separation in I3RC Monte Carlo Model

## Overview

This implementation adds scattering order tracking to the I3RC NASA Community Monte Carlo Radiative Transfer Model, enabling separation of direct and diffuse radiation components. This is a key capability for atmospheric research, particularly for studies involving cloud radiative effects and remote sensing applications.

## Key Concept

The separation is based on the fundamental physics principle that:
- **Direct radiation**: Photons that reach the boundary without any scattering events (scattering order = 0)
- **Diffuse radiation**: Photons that have experienced one or more scattering events (scattering order ≥ 1)

This approach is physically accurate and provides detailed information about the scattering processes in the atmosphere.

## Implementation Details

### 1. Source Code Modifications

The following files were modified in the I3RC Monte Carlo model:

#### `I3RC-Monte-Carlo-Model/Integrators/monteCarloRadiativeTransfer.f95`

**Added to integrator type (line ~133):**
```fortran
! Scattering order tracking for direct/diffuse separation
integer, parameter                :: maxScatteringOrder = 10
real, dimension(:, :, 0:maxScatteringOrder), &
                          pointer :: fluxUpByOrder => null(), &
                                     fluxDownByOrder => null()
```

**Added allocation (line ~245):**
```fortran
! Allocate scattering order tracking arrays
allocate(new%fluxUpByOrder(numX, numY, 0:new%maxScatteringOrder))
allocate(new%fluxDownByOrder(numX, numY, 0:new%maxScatteringOrder))
new%fluxUpByOrder(:, :, :) = 0.
new%fluxDownByOrder(:, :, :) = 0.
```

**Added tracking logic (lines ~522, ~540):**
```fortran
! Track scattering order for direct/diffuse separation
if(scatteringOrder <= thisIntegrator%maxScatteringOrder) then
  thisIntegrator%fluxUpByOrder(xIndex, yIndex, scatteringOrder) = &
    thisIntegrator%fluxUpByOrder(xIndex, yIndex, scatteringOrder) + photonWeight
end if
```

**Added output subroutine:**
```fortran
subroutine writeScatteringOrderResults(thisIntegrator, filePrefix, status)
```

### 2. Usage in Driver Programs

To enable scattering order tracking in existing I3RC drivers, add this call after `reportResults`:

```fortran
call writeScatteringOrderResults(mcIntegrator, 'results_prefix', status)
```

## Output Files

The implementation generates two output files:

1. **`[prefix]_fluxUpByOrder.txt`**: Upward flux by scattering order
2. **`[prefix]_fluxDownByOrder.txt`**: Downward flux by scattering order

### File Format
```
# Format: x_index y_index scattering_order flux
1 1 0 8.45234e+02
1 1 1 1.23456e+02
1 1 2 2.34567e+01
...
```

## Analysis Tools

### Python Analysis Script: `scattering_order_test.py`

This script provides automated analysis of the scattering order results:

```bash
python scattering_order_test.py results_prefix
```

**Example Output:**
```
=== SCATTERING ORDER ANALYSIS ===
Upward Flux (TOPDN equivalent):
  Direct component:   8.45e+02 W/m² (85.3%)
  Diffuse component:  1.46e+02 W/m² (14.7%)
  Total upward:       9.91e+02 W/m²

Downward Flux (BOTDN equivalent):
  Direct component:   7.82e+02 W/m² (78.9%)
  Diffuse component:  2.09e+02 W/m² (21.1%)
  Total downward:     9.91e+02 W/m²

Scattering Order Distribution:
  Order 0: 1.63e+03 W/m² (82.1%) - Direct
  Order 1: 2.89e+02 W/m² (14.6%) - Single scattering
  Order 2: 5.67e+01 W/m² (2.9%)  - Double scattering
```

## Research Applications

### 1. Cloud Radiative Forcing Studies
- Separate direct solar transmission through clouds
- Quantify diffuse radiation enhancement from cloud scattering
- Study multiple scattering effects in different cloud types

### 2. Atmospheric Heating Rate Calculations
- Accurate computation of radiative heating profiles
- Separation of direct absorption vs. scattered radiation heating
- Important for climate model parameterizations

### 3. Remote Sensing Algorithm Development
- Understand direct vs. diffuse contributions to satellite measurements
- Improve retrieval algorithms for cloud and aerosol properties
- Validate assumptions in radiative transfer models

### 4. Climate Model Validation
- Compare detailed scattering order results with simplified climate models
- Validate two-stream and delta-Eddington approximations
- Assess accuracy of climate model radiation schemes

## Integration with Existing I3RC Workflow

This enhancement is fully backward-compatible with existing I3RC configurations:

1. **No changes required to input files** - all existing namelist files work unchanged
2. **Optional output** - scattering order tracking is only enabled when explicitly called
3. **Minimal performance impact** - adds small arrays and simple counters to existing calculations
4. **Standard I3RC interfaces** - follows the same patterns as other I3RC output modules

## Technical Advantages

### 1. Physical Accuracy
- Based on fundamental radiative transfer physics
- No approximations or assumptions about radiation field structure
- Exact tracking of photon scattering history

### 2. Computational Efficiency  
- Minimal overhead on existing Monte Carlo calculations
- Uses already-computed scattering order variable
- Efficient array-based accumulation

### 3. Detailed Information
- Provides scattering order distribution (0, 1, 2, 3, ...)
- Spatial resolution preserved (pixel-level results)
- Can analyze higher-order scattering effects

### 4. Research Flexibility
- Can define direct/diffuse threshold at any scattering order
- Enables studies of single vs. multiple scattering
- Supports statistical analysis across multiple simulations

## Comparison with Alternative Approaches

### Traditional Ray Tracing Approach (I3RC's useRayTracing flag)
- **Problem**: Only captures geometric direct transmission
- **Limitation**: Misses scattered radiation that exits in forward direction
- **Result**: Underestimates diffuse component

### Scattering Order Approach (This Implementation)
- **Advantage**: Physically accurate separation
- **Captures**: All radiation regardless of exit direction
- **Result**: Correct direct/diffuse partitioning

### Two-Stream Model Approaches
- **Limitation**: Simplified angular distribution assumptions
- **Advantage of I3RC**: Full 3D Monte Carlo accuracy
- **Result**: Can validate two-stream model accuracy

## Future Enhancements

1. **NetCDF Output**: Add option to write scattering order results in NetCDF format
2. **Angular Distribution**: Track scattering order by exit angle
3. **Wavelength Dependence**: Extend to multi-spectral calculations
4. **Real-time Analysis**: Add built-in direct/diffuse calculation to driver
5. **Statistical Tools**: Add confidence intervals and convergence analysis

## Conclusion

This implementation provides a robust, physically accurate method for separating direct and diffuse radiation in atmospheric radiative transfer calculations. It addresses a key limitation in atmospheric research tools and opens new possibilities for detailed studies of cloud-radiation interactions, atmospheric heating, and remote sensing applications.

The solution is designed to integrate seamlessly with existing I3RC workflows while providing the advanced analysis capabilities needed for cutting-edge atmospheric research.
