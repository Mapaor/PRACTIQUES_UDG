# Direct/Diffuse Radiation Separation Implementation

## Summary

I've successfully modified the I3RC Monte Carlo radiative transfer model to provide direct access to diffuse radiation components alongside the existing radiative flux outputs. This implementation tracks photon scattering order internally and separates radiation into direct (unscattered) and diffuse (scattered) components.

## Key Changes Made

### 1. Enhanced Integrator Type Definition

**Added to `monteCarloRadiativeTransfer.f95` integrator type:**
```fortran
real, dimension(:, :), pointer :: fluxUpDiffuse => null(), fluxDownDiffuse => null()
```

These arrays store the diffuse radiation components parallel to the existing `fluxUp` and `fluxDown` arrays.

### 2. Memory Management

**Allocation (line ~238):**
```fortran
allocate(new%fluxUpDiffuse(numX, numY), new%fluxDownDiffuse(numX, numY))
new%fluxUpDiffuse(:, :) = 0.; new%fluxDownDiffuse(:, :) = 0.
```

**Copy operations (copy_Integrator):**
```fortran
if(associated(original%fluxUpDiffuse)) then
  allocate(copy%fluxUpDiffuse(size(original%fluxUpDiffuse, 1), &
                              size(original%fluxUpDiffuse, 2)))
  copy%fluxUpDiffuse(:, :) = original%fluxUpDiffuse(:, :)
end if
```

**Deallocation (finalize_Integrator):**
```fortran
if(associated(thisIntegrator%fluxUpDiffuse))    deallocate(thisIntegrator%fluxUpDiffuse)
if(associated(thisIntegrator%fluxDownDiffuse))  deallocate(thisIntegrator%fluxDownDiffuse)
```

### 3. Radiation Tracking Logic

**In the Monte Carlo integration loop:**
```fortran
! When photon exits at top boundary
thisIntegrator%fluxUp(xIndex, yIndex) = thisIntegrator%fluxUp(xIndex, yIndex) + photonWeight

! Track diffuse radiation (scattering order >= 1)
if(scatteringOrder >= 1) then
  thisIntegrator%fluxUpDiffuse(xIndex, yIndex) = &
    thisIntegrator%fluxUpDiffuse(xIndex, yIndex) + photonWeight
end if

! Similar logic for bottom boundary (fluxDown/fluxDownDiffuse)
```

**Physical Principle:**
- **Direct radiation**: `scatteringOrder = 0` (no scattering events)
- **Diffuse radiation**: `scatteringOrder >= 1` (one or more scattering events)

### 4. Extended Output Interface

**New subroutine `reportResultsWithDiffuse`:**
```fortran
subroutine reportResultsWithDiffuse(thisIntegrator,                             &
                         meanFluxUp, meanFluxDown, meanFluxAbsorbed, &
                             fluxUp,     fluxDown,     fluxAbsorbed, & 
                         meanFluxUpDiffuse, meanFluxDownDiffuse,     &
                             fluxUpDiffuse,     fluxDownDiffuse,     &
                         absorbedProfile, volumeAbsorption,          &
                         meanIntensity, intensity, status)
```

This extends the standard `reportResults` interface with diffuse radiation outputs.

## Usage in Driver Programs

### 1. Variable Declarations

```fortran
! Standard variables (unchanged)
real :: meanFluxUp, meanFluxDown, meanFluxAbsorbed
real, dimension(:, :), allocatable :: fluxUp, fluxDown, fluxAbsorbed

! NEW: Diffuse radiation variables
real :: meanFluxUpDiffuse, meanFluxDownDiffuse  
real, dimension(:, :), allocatable :: fluxUpDiffuse, fluxDownDiffuse
```

### 2. Array Allocation

```fortran
allocate(fluxUp(numX, numY), fluxDown(numX, numY), fluxAbsorbed(numX, numY))
allocate(fluxUpDiffuse(numX, numY), fluxDownDiffuse(numX, numY))  ! NEW
```

### 3. Retrieving Results

```fortran
! NEW: Extended call to get diffuse radiation
call reportResultsWithDiffuse(mcIntegrator, &
       meanFluxUp, meanFluxDown, meanFluxAbsorbed,       &
       fluxUp(:, :), fluxDown(:, :), fluxAbsorbed(:, :), &
       meanFluxUpDiffuse, meanFluxDownDiffuse,           &  ! NEW
       fluxUpDiffuse(:, :), fluxDownDiffuse(:, :),       &  ! NEW
       status = status)
```

### 4. Calculate Direct Components

```fortran
! Direct = Total - Diffuse
meanFluxUpDirect = meanFluxUp - meanFluxUpDiffuse
meanFluxDownDirect = meanFluxDown - meanFluxDownDiffuse
fluxUpDirect(:, :) = fluxUp(:, :) - fluxUpDiffuse(:, :)
fluxDownDirect(:, :) = fluxDown(:, :) - fluxDownDiffuse(:, :)
```

## Output Variables Available

After calling `reportResultsWithDiffuse`, you have access to:

### Standard Outputs (unchanged)
- `fluxUp`, `fluxDown`: Total radiative fluxes  
- `meanFluxUp`, `meanFluxDown`: Domain-averaged total fluxes
- `fluxAbsorbed`, `meanFluxAbsorbed`: Absorption terms
- `volumeAbsorption`: 3D absorption field
- `intensity`: Radiance fields (if requested)

### NEW: Diffuse Radiation Outputs
- `fluxUpDiffuse`, `fluxDownDiffuse`: Diffuse radiation components
- `meanFluxUpDiffuse`, `meanFluxDownDiffuse`: Domain-averaged diffuse fluxes

### Derived: Direct Radiation Components  
- Direct fluxes = Total fluxes - Diffuse fluxes
- Direct fractions = Direct fluxes / Total fluxes

## Physical Interpretation

### TOPDN (Top of Domain, Downward)
- **Total**: `fluxUp` - All radiation exiting upward at domain top
- **Direct**: `fluxUp - fluxUpDiffuse` - Unscattered solar radiation
- **Diffuse**: `fluxUpDiffuse` - Radiation that has been scattered

### BOTDN (Bottom of Domain, Downward)  
- **Total**: `fluxDown` - All radiation exiting downward at domain bottom
- **Direct**: `fluxDown - fluxDownDiffuse` - Unscattered solar radiation
- **Diffuse**: `fluxDownDiffuse` - Radiation that has been scattered

### BOTDIF (Bottom Diffuse) Equivalent
- `fluxDownDiffuse` directly provides the BOTDIF equivalent you were seeking
- No need for separate BOTDIF calculation - it's automatically computed

## Research Applications

### 1. Cloud Radiative Effects
- Quantify how clouds enhance diffuse radiation
- Study direct solar transmission vs. scattered radiation
- Analyze multiple scattering in different cloud types

### 2. Atmospheric Heating Calculations  
- Separate heating from direct absorption vs. scattered radiation
- Improve radiative heating rate calculations
- Validate climate model radiation schemes

### 3. Remote Sensing
- Understand direct vs. diffuse contributions to satellite measurements
- Improve cloud and aerosol retrieval algorithms
- Account for 3D radiative effects in retrievals

### 4. Solar Energy Applications
- Calculate direct normal irradiance vs. diffuse horizontal irradiance
- Study cloud impacts on solar panel efficiency
- Model radiation enhancement effects

## Advantages of This Implementation

### 1. **Seamless Integration**
- Fully backward compatible with existing I3RC drivers
- No changes required to existing input files or configurations
- Standard `reportResults` still works unchanged

### 2. **Physical Accuracy**
- Based on fundamental scattering order physics
- No approximations or assumptions about radiation field structure
- Captures all photon paths regardless of exit direction

### 3. **Computational Efficiency**
- Minimal overhead on existing Monte Carlo calculations  
- Uses already-computed `scatteringOrder` variable
- Simple array accumulation operations

### 4. **Comprehensive Output**
- Provides both pixel-level and domain-averaged results
- Maintains full spatial resolution
- Integrates with existing I3RC output workflows

### 5. **Research Flexibility**
- Direct access to diffuse radiation arrays for analysis
- Can be easily extended for more detailed scattering order studies
- Compatible with NetCDF output and post-processing tools

## Compilation and Testing

The modified code should compile with the existing I3RC build system:

```bash
cd I3RC-Monte-Carlo-Model
make clean
make
```

The changes preserve all existing functionality while adding the new diffuse radiation capability.

## Conclusion

This implementation provides exactly what you requested: **direct access to diffuse radiation alongside the other radiative fluxes in the I3RC Monte Carlo model**. The diffuse radiation arrays are computed automatically during the Monte Carlo integration and can be accessed through the standard I3RC driver interface using the new `reportResultsWithDiffuse` subroutine.

The solution is physically accurate, computationally efficient, and seamlessly integrates with existing I3RC workflows while providing the advanced analysis capabilities needed for atmospheric research involving direct/diffuse radiation separation.
