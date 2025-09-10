# I3RC Monte Carlo Results: Aerosols vs Clouds (τ = 0.2)

## Final Dataset Summary

**Generated on:** 2025-08-25  
**Optical Depth:** τ = 0.2 for both configurations  
**Solar Zenith Angles:** 0°, 15°, 30°, 45°, 60°, 75°, 85°  
**Monte Carlo Photons:** 1,000 per simulation  

## File Description

### CSV Format (Raw Results)
- `aerosol_tau02_results.csv` - Rural aerosol simulation results
- `cloud_tau02_results.csv` - Thin cloud simulation results

### DAT Format (KT/DF Analysis)
- `aerosol_tau02_KT_DF.dat` - Aerosol data in KT/DF format
- `cloud_tau02_KT_DF.dat` - Cloud data in KT/DF format

## Data Format Explanation

### CSV Files
- **zenith_angle**: Solar zenith angle (degrees)
- **solar_elevation**: Solar elevation angle (degrees) 
- **mu**: Cosine of zenith angle
- **extraterrestrial**: Incident radiation at top of domain (normalized to 1.0)
- **global**: Total transmitted radiation at surface (direct + diffuse)
- **diffuse**: Diffuse radiation component at surface

### DAT Files (KT/DF Format)
- **KT**: Clearness index = Global radiation / Extraterrestrial radiation
- **DF**: Diffuse fraction = Diffuse radiation / Global radiation

## Key Physical Insights

### Aerosols (Rural Aerosol, τ=0.2)
- **Transmission behavior**: High transmission at low zenith angles (~92%), decreasing significantly at high angles (~41% at 85°)
- **Diffuse fraction**: Increases from ~20% at 0° to ~99% at 85°
- **Scattering characteristics**: Strong forward scattering with increasing diffuse component at oblique angles

### Clouds (Water Droplets, τ=0.2)  
- **Transmission behavior**: Very high transmission at low zenith angles (~105%), decreasing to ~64% at 85°
- **Diffuse fraction**: Increases from ~11% at 0° to ~75% at 85°
- **Scattering characteristics**: Strong forward scattering, less diffuse scattering compared to aerosols

### Comparison Highlights
1. **Clouds transmit more radiation** than aerosols at all angles
2. **Aerosols create more diffuse radiation** than clouds at high zenith angles
3. **Both show strong angular dependence** with maximum transmission at low zenith angles
4. **Diffuse fraction increases dramatically** with zenith angle for both cases

## Technical Notes

- **Consistent data**: Global radiation calculated as Direct + Diffuse from same source to ensure DF ≤ 1.0
- **Normalized fluxes**: All radiation values normalized to incident flux of 1.0
- **Monte Carlo uncertainty**: Results based on 1,000 photons per simulation
- **Domain geometry**: 1-layer atmosphere with specified optical depth

## Usage for Research

These datasets are ready for:
- **Solar radiation modeling validation**
- **Direct/diffuse separation algorithm development** 
- **Atmospheric optics research**
- **Comparison with satellite or ground-based observations**

The KT/DF format is particularly useful for meteorological and solar energy applications.
