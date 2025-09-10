# Input Files Documentation and Cleanup Summary

## 📁 **Input Directory Organization Complete**

### **Created Documentation Files:**

1. **`InputDocumentation.md`** - Comprehensive 200+ line documentation covering:
   - Complete parameter explanations for all input file types
   - MakeMieTable configuration (Mie scattering properties)
   - PhysicalPropertiesToDomain settings (3D property distributions)  
   - MonteCarloDriver parameters (simulation control)
   - Workflow dependencies and examples
   - Parameter tuning guidelines
   - Common configuration templates

2. **`README.md`** - Quick reference guide with:
   - Essential file organization summary
   - Recommended workflow configurations
   - Parameter customization quick guide
   - File dependency chains
   - Cleanup summary

### **Files Cleaned Up:**

#### **Removed Unnecessary Files:**
- ✅ All auto-generated `*_z??.nml` files (zenith-angle specific configs)
- ✅ `MonteCarloDriver.nml.backup` (backup file)
- ✅ `.DS_Store` files (macOS system files)

#### **Organized Essential Files:**
**MakeMieTable/** (6 files)
- `mie_table_cloud.nml` - Water cloud droplets
- `rural_aerosol_mie.nml` - Rural/continental aerosols  
- `aerosol_mie.nml` - Dust aerosols
- `absorbing_aerosol_mie.nml` - Highly absorbing aerosols
- `mie_table_research.nml` - Research configuration
- `MakeMieTable.readme` - Original documentation

**MonteCarloDriver/** (11 files)
- Core configs: `MonteCarloDriver.nml`, `MonteCarloDriver_research.nml`
- Research-ready: `rural_aerosol_proper.nml`, `thin_cloud.nml`
- Testing: `MonteCarloDriver_small.nml`, `minimal_aerosol_test.nml`
- Special purpose: `MonteCarloDriver_clear_sky.nml`, `MonteCarloDriver_diffuse.nml`
- Additional: `rural_aerosol_02.nml`, `thin_aerosol.nml`
- Documentation: `monteCarloDriver.readme`

**PhysicalPropertiesToDomain/** (18 files)
- Physical property files: `*.txt` (8 files)
- Domain configuration files: `*_domain.nml` (8 files)  
- Documentation: `cloud.readme`, `cloud_domain.readme`

### **Updated Notebook Configuration:**

Updated `grafics.ipynb` to use the new clean datasets:
- ✅ Points to `aerosol_tau02_KT_DF.dat` and `cloud_tau02_KT_DF.dat`
- ✅ Improved labels: "Rural Aerosol (τ=0.2, reff=0.5μm)" and "Thin Cloud (τ=0.2, reff=10μm)"
- ✅ Enhanced plot formatting with better title and annotations
- ✅ Removed references to old/outdated data files

### **Key Documentation Highlights:**

#### **Parameter Customization Made Easy:**
```fortran
! Optical depth control examples
! Clouds (τ≈0.2): mass = 0.009 g/m³, reff = 10 μm  
! Aerosols (τ≈0.2): mass = 0.001 g/m³, reff = 0.5 μm

! Solar zenith angle examples
solarMu = 1.000  ! 0° (overhead)
solarMu = 0.707  ! 45° (mid-day)
solarMu = 0.087  ! 85° (grazing)
```

#### **Complete Workflow Examples:**
```bash
# Research-ready aerosol vs cloud comparison
MakeMieTable < Input/MakeMieTable/mie_table_cloud.nml
MakeMieTable < Input/MakeMieTable/rural_aerosol_mie.nml
PhysicalPropertiesToDomain < Input/PhysicalPropertiesToDomain/thin_cloud_domain.nml
PhysicalPropertiesToDomain < Input/PhysicalPropertiesToDomain/rural_aerosol_proper_domain.nml
MonteCarloDriver < Input/MonteCarloDriver/thin_cloud.nml
MonteCarloDriver < Input/MonteCarloDriver/rural_aerosol_proper.nml
```

#### **Physical Property Guidelines:**
- **Cloud droplets:** 5-20 μm effective radius, Gamma distribution (α=7)
- **Rural aerosols:** 0.1-2.0 μm effective radius, Lognormal distribution (σ=0.3-0.8)  
- **Refractive indices:** Water tables for clouds, user-specified for aerosols
- **Mass concentrations:** Tuned to achieve desired optical depths

### **Results:**

The Input directory is now:
- ✅ **Well-documented** with comprehensive parameter explanations
- ✅ **Organized** with clear file structure and purposes
- ✅ **Clean** with unnecessary files removed  
- ✅ **Research-ready** with example configurations for common use cases
- ✅ **Easy to customize** with clear parameter guidelines

Users can now easily:
1. **Understand** what each parameter does
2. **Modify** configurations for their research needs  
3. **Follow** complete workflows from Mie tables to final results
4. **Avoid** common pitfalls with proper parameter ranges
5. **Replicate** the aerosol vs cloud comparison studies

The documentation covers everything from basic parameter definitions to advanced simulation techniques, making the I3RC Monte Carlo model accessible for atmospheric optics research! 🎯
