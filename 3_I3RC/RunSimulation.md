# How to Run the I3RC Monte Carlo Simulation

This guide explains how to run the I3RC Monte Carlo model for aerosols and clouds, including all necessary commands and workflow steps.

---


## 1. **Automated Workflow (Recommended for Most Users)**

This workflow uses provided PowerShell and Python scripts to automate all preparation and simulation steps. No manual WSL commands are needed.

### **Step 1: Prepare Profiles and Tables**

Run the PowerShell script to build all required Mie tables and domain files:

```powershell
pwsh ./PerpareI3RCProfiles.ps1
```

### **Step 2: Run Simulations and Batch Analysis**

Use the Python automation script to run the Monte Carlo simulations for a sweep of zenith angles and save results:

```powershell
python automate_i3rc_ZSA.py --config rural_aerosol_proper --angles 0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85 --num-batches 100 --photons-per-batch 1000 --output aerosol_results.csv
python automate_i3rc_ZSA.py --config thin_cloud --angles 0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85 --num-batches 100 --photons-per-batch 1000 --output cloud_results.csv
```

Convert results to KT/DF format:
```powershell
python csv2dat.py aerosol_results.csv aerosol_KT_DF.dat
python csv2dat.py cloud_results.csv cloud_KT_DF.dat
```

**Output files will be written to the Output folder.**

---

## 2. **Manual Workflow (WSL/bash Commands)**

This workflow is for advanced users who prefer to run each step manually in a WSL terminal.

### **Step 1: Prepare Profiles and Tables**

```bash
cd /mnt/c/Users/PC/Documents/GitHub/I3RC/I3RC-Monte-Carlo-Model/Tools
./MakeMieTable mie_table_cloud.nml
./MakeMieTable rural_aerosol_mie.nml
./physicalPropertiesToDomain thin_cloud_domain.nml
./physicalPropertiesToDomain rural_aerosol_proper_domain.nml
```

### **Step 2: Run Monte Carlo Simulation**

```bash
./I3RC-Monte-Carlo-Model/Example-Drivers/monteCarloDriver thin_cloud.nml
./I3RC-Monte-Carlo-Model/Example-Drivers/monteCarloDriver rural_aerosol_proper.nml
```

**Do not use `<` in native PowerShell; always use WSL for input redirection.**

---

---

## 3. **Automated Python Workflow**


You can automate zenith angle sweeps and output parsing using the provided Python script (run from the main project folder):

```powershell
python automate_i3rc_ZSA.py --config rural_aerosol_proper --angles 0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85 --photons 1000 --output aerosol_results.csv
python automate_i3rc_ZSA.py --config thin_cloud --angles 0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85 --photons 1000 --output cloud_results.csv
```

Convert results to KT/DF format:
```powershell
python csv2dat.py aerosol_results.csv aerosol_KT_DF.dat
python csv2dat.py cloud_results.csv cloud_KT_DF.dat
```

---

## 4. **Output Files**

- `Fluxes_*.out` — Upward/downward fluxes
- `Intensities_*.out` — Radiances in specified directions
- `Absorption_*.out` — Absorption profiles
- `All_output_*.nc` — NetCDF output (all results)
- `Diffuse_Fluxes.out` — Direct/diffuse separation (custom output)
- `*_results.csv` — Automated summary (from Python script)
- `*_KT_DF.dat` — KT/DF format for analysis

---

## 5. **Tips**

- Adjust photon counts for speed vs. accuracy (see `InputDocumentation.md`)
- Change `solarMu` in `.nml` files for different solar zenith angles
- Use the Python automation for batch runs and data extraction
- **Always run the executables inside WSL, or use the provided PowerShell scripts which automate this for you.**
- **No need to rebuild unless you change the Fortran source code.**

---

## 6. **Example: Full Aerosol Simulation Sweep (Python Automation)**


```powershell
python automate_i3rc_ZSA.py --config rural_aerosol_proper --angles 0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85 --photons 1000 --output aerosol_tau02_results.csv
python csv2dat.py aerosol_tau02_results.csv aerosol_tau02_KT_DF.dat
```

---

For more details, see `InputDocumentation.md` and `README.md` in the Input folder.
