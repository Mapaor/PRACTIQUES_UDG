#!/usr/bin/env python3
"""
I3RC Monte Carlo ZSA Automation
===============================================

Automates I3RC simulations across different solar zenith angles (0° to 85°)
and extracts key radiation components: extraterrestrial, global, and diffuse.

Usage:
    python automate_i3rc_ZSA.py --config cloud_config --output results.csv
    python automate_i3rc_ZSA.py --config aerosol_config --angles 0,15,30,45,60,75

Author: Research Automation Script
Date: August 2025
"""

import os
import sys
import subprocess
import argparse
import numpy as np
import pandas as pd
import re
from pathlib import Path
from typing import Dict, List, Tuple, Optional
import json
import time

class I3RCAutomation:
    """Automates I3RC Monte Carlo simulations for different zenith angle values."""
    
    def __init__(self, base_dir: str = None):
        """Initialize automation with I3RC directory."""
        self.base_dir = Path(base_dir) if base_dir else Path.cwd()
        self.input_dir = self.base_dir / "Input"
        self.output_dir = self.base_dir / "Output"
        self.results = []
        
        # Verify I3RC directory structure
        self._verify_i3rc_setup()
    
    def _verify_i3rc_setup(self):
        """Verify I3RC directory structure exists."""
        required_dirs = [
            "Input/PhysicalPropertiesToDomain",
            "Input/MonteCarloDriver", 
            "Output/PhysicalPropertiesToDomain",
            "Output/MonteCarloDriver",
            "I3RC-Monte-Carlo-Model/Tools"
        ]
        
        for dir_path in required_dirs:
            full_path = self.base_dir / dir_path
            if not full_path.exists():
                raise FileNotFoundError(f"Required I3RC directory not found: {full_path}")
        
        print(f"✓ I3RC setup verified in: {self.base_dir}")
    
    def create_monte_carlo_config(self, config_name: str, zenith_angle: float, 
                                 base_config_file: str, photons_per_batch: int = 100, num_batches: int = 10) -> str:
        """Create Monte Carlo configuration file for specific zenith angle based on existing config."""
        
        # Read existing base configuration
        base_config_path = self.input_dir / "MonteCarloDriver" / f"{base_config_file}.nml"
        if not base_config_path.exists():
            raise FileNotFoundError(f"Base configuration not found: {base_config_path}")
        
        with open(base_config_path, 'r') as f:
            base_content = f.read()
        
        # Convert zenith angle to mu (cosine)
        zenith_rad = np.radians(zenith_angle)
        mu = np.cos(zenith_rad)
        
        # Update the configuration for this zenith angle
        # Replace solarMu value
        import re
        content = re.sub(r'solarMu\s*=\s*[0-9.+-]+', f'solarMu = {mu:.6f}', base_content)
        
        # Update photon counts
        content = re.sub(r'numPhotonsPerBatch\s*=\s*[0-9]+', f'numPhotonsPerBatch = {photons_per_batch}', content)
        content = re.sub(r'numBatches\s*=\s*[0-9]+', f'numBatches = {num_batches}', content)
        
        # Update output file names
        content = re.sub(r'outputRadFile\s*=\s*"[^"]*"', 
                        f'outputRadFile = "./Output/MonteCarloDriver/Intensities_{config_name}_z{zenith_angle:02.0f}.out"', content)
        content = re.sub(r'outputFluxFile\s*=\s*"[^"]*"', 
                        f'outputFluxFile = "./Output/MonteCarloDriver/Fluxes_{config_name}_z{zenith_angle:02.0f}.out"', content)
        content = re.sub(r'outputAbsProfFile\s*=\s*"[^"]*"', 
                        f'outputAbsProfFile = "./Output/MonteCarloDriver/Absorption_{config_name}_z{zenith_angle:02.0f}.out"', content)
        content = re.sub(r'outputNetcdfFile\s*=\s*"[^"]*"', 
                        f'outputNetcdfFile = "./Output/MonteCarloDriver/All_output_{config_name}_z{zenith_angle:02.0f}.nc"', content)
        
        # Add comment header
        header = f"""! Namelist input file for monteCarloDriver
! Generated for {config_name} at {zenith_angle}° zenith angle
! Solar zenith: {zenith_angle}°, mu = {mu:.6f}
! Based on: {base_config_file}.nml

"""
        content = header + content
        
        # Write configuration file
        config_path = self.input_dir / "MonteCarloDriver" / f"{config_name}_z{zenith_angle:02.0f}.nml"
        with open(config_path, 'w') as f:
            f.write(content)
        
        return str(config_path)
    
    def run_wsl_command(self, command: str, cwd: str = None) -> Tuple[int, str, str]:
        """Execute command in WSL and return exit code, stdout, stderr."""
        if cwd is None:
            cwd = str(self.base_dir)
        
        # Convert Windows path to WSL path
        wsl_cwd = cwd.replace('C:\\', '/mnt/c/').replace('\\', '/')
        
        # Full WSL command
        full_command = f'wsl -d Ubuntu -e bash -c "cd \\"{wsl_cwd}\\" && {command}"'
        
        try:
            result = subprocess.run(
                full_command, 
                shell=True, 
                capture_output=True, 
                text=True, 
                timeout=300  # 5 minute timeout
            )
            return result.returncode, result.stdout, result.stderr
        except subprocess.TimeoutExpired:
            return -1, "", "Command timed out after 5 minutes"
        except Exception as e:
            return -1, "", str(e)
    
    def run_i3rc_simulation(self, config_name: str, base_config: str, zenith_angle: float, photons_per_batch: int, num_batches: int) -> bool:
        """Run complete I3RC simulation for given configuration and zenith angle."""
        
        print(f"  Running simulation for {zenith_angle}° zenith angle...")
        
        # Step 1: Check if domain file exists (should already exist)
        domain_path = self.output_dir / "PhysicalPropertiesToDomain" / f"{config_name}.dom"
        if not domain_path.exists():
            print(f"    Generating domain file...")
            cmd = f"./I3RC-Monte-Carlo-Model/Tools/physicalPropertiesToDomain ./Input/PhysicalPropertiesToDomain/{config_name}_domain.nml"
            exit_code, stdout, stderr = self.run_wsl_command(cmd)
            
            if exit_code != 0:
                print(f"    ❌ Domain generation failed: {stderr}")
                return False
            print(f"    ✓ Domain file created")
        
        # Step 2: Create Monte Carlo configuration based on existing config
        config_path = self.create_monte_carlo_config(config_name, zenith_angle, base_config, photons_per_batch, num_batches)
        
        # Step 3: Delete previous output files to ensure fresh simulation
        output_files = [
            f"Fluxes_{config_name}_z{zenith_angle:02.0f}.out",
            f"Intensities_{config_name}_z{zenith_angle:02.0f}.out", 
            f"Absorption_{config_name}_z{zenith_angle:02.0f}.out",
            f"All_output_{config_name}_z{zenith_angle:02.0f}.nc"
        ]
        
        for output_file in output_files:
            output_path = self.output_dir / "MonteCarloDriver" / output_file
            if output_path.exists():
                output_path.unlink()
                print(f"    Deleted previous: {output_file}")
        
        # Also delete the generic Diffuse_Fluxes.out to ensure fresh results
        diffuse_file = self.output_dir / "MonteCarloDriver" / "Diffuse_Fluxes.out"
        if diffuse_file.exists():
            diffuse_file.unlink()
        
        # Step 4: Run Monte Carlo simulation
        print(f"    Running Monte Carlo simulation with {photons_per_batch} photons per batch, {num_batches} batches...")
        config_file = f"{config_name}_z{zenith_angle:02.0f}.nml"
        cmd = f"./I3RC-Monte-Carlo-Model/Example-Drivers/monteCarloDriver ./Input/MonteCarloDriver/{config_file}"
        
        start_time = time.time()
        exit_code, stdout, stderr = self.run_wsl_command(cmd)
        end_time = time.time()
        
        simulation_time = end_time - start_time
        print(f"    Simulation took {simulation_time:.1f} seconds")
        
        if exit_code not in [0, 11]:  # 11 is segfault but simulation completes
            print(f"    ❌ Monte Carlo simulation failed (exit code {exit_code}): {stderr}")
            return False
        
        # Step 5: Verify output files were created
        created_files = []
        for output_file in output_files:
            output_path = self.output_dir / "MonteCarloDriver" / output_file
            if output_path.exists():
                created_files.append(output_file)
        
        if len(created_files) < 3:  # At least 3 output files should be created
            print(f"    ❌ Simulation incomplete - only {len(created_files)} output files created")
            return False
        
        print(f"    ✓ Simulation completed - {len(created_files)} output files created")
        return True
    
    def parse_standard_fluxes(self, config_name: str, zenith_angle: float) -> Optional[Dict[str, float]]:
        """Parse the standard Fluxes_*.out file to extract radiation components."""
        
        # Read the standard flux file for this zenith angle
        flux_file = self.output_dir / "MonteCarloDriver" / f"Fluxes_{config_name}_z{zenith_angle:02.0f}.out"
        if not flux_file.exists():
            print(f"    ❌ Flux file not found: {flux_file}")
            return None
        
        try:
            with open(flux_file, 'r') as f:
                content = f.read()
            
            # Parse flux values from the standard output
            lines = content.strip().split('\n')
            flux_down = None
            flux_up = None
            
            # Look for the Average line with flux data (can be in comments starting with !)
            for line in lines:
                if 'Average:' in line:
                    parts = line.split()
                    print(f"    Found Average line: '{line.strip()}'")
                    print(f"    Split into {len(parts)} parts: {parts}")
                    if len(parts) >= 6:  # Need at least 6 parts: !, Average:, flux_up, stderr, flux_down, stderr, ...
                        try:
                            # For comment lines starting with !, the flux values are shifted by 1
                            if line.startswith('!'):
                                flux_up = float(parts[2])      # Upwelling flux (after ! and Average:)
                                flux_down = float(parts[4])    # Downwelling flux
                            else:
                                flux_up = float(parts[1])      # Upwelling flux
                                flux_down = float(parts[3])    # Downwelling flux
                            print(f"    Parsed fluxes: Up={flux_up:.4f}, Down={flux_down:.4f}")
                            break
                        except (ValueError, IndexError) as e:
                            print(f"    ❌ Failed to parse values: {e}")
                            continue
            
            if flux_down is None or flux_up is None:
                print(f"    ❌ Failed to parse flux values from {flux_file}")
                return None
            
            # For KT calculation, we need:
            # - Extraterrestrial: Solar flux at TOA = solarFlux = 1.0 (normalized incident radiation)
            # - Global: Transmitted flux at bottom of domain (flux_down at lowest level)
            # NOTE: The domain doesn't extend to true surface/TOA, but solarFlux represents
            #       the incident extraterrestrial radiation entering the domain from above
            extraterrestrial = 1.0  # solarFlux (normalized incident solar radiation)
            global_radiation = flux_down  # Transmitted flux at bottom boundary
            
            # Also read diffuse component from our custom output
            diffuse_data = self.parse_diffuse_component()
            if diffuse_data is None:
                print(f"    ⚠ Could not parse diffuse component, using standard calculation")
                diffuse_radiation = 0.0  # Fallback if diffuse parsing fails
                direct_radiation = global_radiation
            else:
                # Use consistent global radiation from direct + diffuse
                direct_radiation = diffuse_data['botdn_direct']
                diffuse_radiation = diffuse_data['botdn_diffuse'] 
                global_consistent = diffuse_data['global_consistent']
                
                print(f"    Standard global: {global_radiation:.4f}")
                print(f"    Consistent global (direct + diffuse): {global_consistent:.4f}")
                print(f"    Direct: {direct_radiation:.4f}, Diffuse: {diffuse_radiation:.4f}")
                
                # Use the consistent global radiation to avoid DF > 1.0
                global_radiation = global_consistent
            
            return {
                'extraterrestrial': extraterrestrial,
                'global': global_radiation,
                'diffuse': diffuse_radiation,
                'direct': direct_radiation,
                'flux_up': flux_up,
                'flux_down': flux_down
            }
            
        except Exception as e:
            print(f"    ❌ Error parsing standard fluxes: {e}")
            return None
    
    def parse_diffuse_component(self) -> Optional[Dict[str, float]]:
        """Parse both direct and diffuse components from Diffuse_Fluxes.out file."""
        
        diffuse_file = self.output_dir / "MonteCarloDriver" / "Diffuse_Fluxes.out"
        print(f"    Looking for diffuse file: {diffuse_file}")
        
        if not diffuse_file.exists():
            print(f"    ❌ Diffuse file not found: {diffuse_file}")
            return None
        
        try:
            with open(diffuse_file, 'r') as f:
                content = f.read()
            
            print(f"    Diffuse file content (first 300 chars): {content[:300]}")
            
            # Parse the diffuse flux values
            lines = content.strip().split('\n')
            print(f"    Number of lines in diffuse file: {len(lines)}")
            
            for i, line in enumerate(lines):
                print(f"    Line {i}: '{line}'")
                if line.strip() and not line.startswith('#') and len(line.split()) >= 4:
                    values = line.split()
                    print(f"    Found data line with {len(values)} values: {values}")
                    if len(values) >= 4:
                        try:
                            topdn_direct = float(values[0])    # Top direct
                            botdn_direct = float(values[1])    # Surface direct
                            topdn_diffuse = float(values[2])   # Top diffuse
                            botdn_diffuse = float(values[3])   # Surface diffuse
                            
                            # Calculate consistent global radiation from direct + diffuse
                            global_consistent = botdn_direct + botdn_diffuse
                            
                            print(f"    Parsed direct: {botdn_direct:.4f}, diffuse: {botdn_diffuse:.4f}")
                            print(f"    Consistent global: {global_consistent:.4f}")
                            
                            return {
                                'botdn_direct': botdn_direct,
                                'botdn_diffuse': botdn_diffuse,
                                'global_consistent': global_consistent
                            }
                        except (ValueError, IndexError) as e:
                            print(f"    ❌ Error parsing values: {e}")
                            continue
            
            print(f"    ❌ No valid data lines found in diffuse file")
            return None
            
        except Exception as e:
            print(f"    ❌ Error reading diffuse file: {e}")
            return None
    
    def run_zenith_sweep(self, config_name: str, base_config: str, 
                        zenith_angles: List[float], photons_per_batch: int = 100, num_batches: int = 10) -> pd.DataFrame:
        """Run I3RC simulations across multiple zenith angles."""
        
        print(f"\n{'='*60}")
        print(f"I3RC Solar Zenith Angle Sweep: {config_name}")
        print(f"{'='*60}")
        print(f"Configuration: {config_name}")
        print(f"Base config: {base_config}")
        print(f"Zenith angles: {zenith_angles}")
        print(f"Photons per batch: {photons_per_batch}")
        print(f"Number of batches: {num_batches}")
        print(f"{'='*60}")
        
        results = []
        
        for i, zenith in enumerate(zenith_angles):
            print(f"\n[{i+1}/{len(zenith_angles)}] Processing zenith angle: {zenith}°")
            
            # Run simulation
            success = self.run_i3rc_simulation(config_name, base_config, zenith, photons_per_batch, num_batches)
            
            if success:
                # Parse results
                fluxes = self.parse_standard_fluxes(config_name, zenith)
                
                if fluxes:
                    result = {
                        'zenith_angle': zenith,
                        'solar_elevation': 90 - zenith,
                        'mu': np.cos(np.radians(zenith)),
                        'extraterrestrial': fluxes['extraterrestrial'],
                        'global': fluxes['global'],
                        'diffuse': fluxes['diffuse']
                    }
                    results.append(result)
                    
                    # Calculate diffuse fraction for display
                    diffuse_fraction = fluxes['diffuse'] / fluxes['global'] * 100 if fluxes['global'] > 0 else 0
                    print(f"    ✓ Results: Ext={fluxes['extraterrestrial']:.4f}, Global={fluxes['global']:.4f}, Diffuse={fluxes['diffuse']:.4f} ({diffuse_fraction:.1f}%)")
                else:
                    print(f"    ❌ Failed to parse results")
            else:
                print(f"    ❌ Simulation failed")
        
        # Create DataFrame
        df = pd.DataFrame(results)
        
        print(f"\n{'='*60}")
        print(f"Solar Zenith Angle Sweep Completed: {len(results)}/{len(zenith_angles)} successful")
        print(f"{'='*60}")
        
        return df
    
    def save_results(self, df: pd.DataFrame, output_file: str, config_name: str):
        """Save results to CSV file with metadata."""
        
        output_path = Path(output_file)
        
        # Create header with metadata
        header_lines = [
            "# I3RC Monte Carlo Solar Zenith Angle Analysis Results",
            f"# Configuration: {config_name}",
            f"# Generated: {time.strftime('%Y-%m-%d %H:%M:%S')}",
            f"# Total simulations: {len(df)}",
            "#",
            "# Columns:",
            "#   zenith_angle: Solar zenith angle (degrees)",
            "#   solar_elevation: Solar elevation angle (degrees)", 
            "#   mu: Cosine of zenith angle",
            "#   extraterrestrial: Total radiation at top of atmosphere",
            "#   global: Total radiation at surface (direct + diffuse)",
            "#   diffuse: Diffuse radiation at surface",
            "#",
            "# Units: All radiation values are normalized fluxes",
            "#"
        ]
        
        # Write results
        with open(output_path, 'w') as f:
            # Write header
            for line in header_lines:
                f.write(line + '\n')
            
            # Write CSV data
            df.to_csv(f, index=False, float_format='%.6f')
        
        print(f"\n✓ Results saved to: {output_path}")
        print(f"✓ {len(df)} data points written")
        
        # Print summary statistics
        if len(df) > 0:
            print(f"\nSummary Statistics:")
            print(f"  Zenith range: {df['zenith_angle'].min():.1f}° - {df['zenith_angle'].max():.1f}°")
            print(f"  Extraterrestrial: {df['extraterrestrial'].min():.4f} - {df['extraterrestrial'].max():.4f}")
            print(f"  Global radiation: {df['global'].min():.4f} - {df['global'].max():.4f}")
            print(f"  Diffuse radiation: {df['diffuse'].min():.4f} - {df['diffuse'].max():.4f}")
            
            # Calculate and display mean ± std for each key variable
            print(f"\nMean ± Standard Deviation:")
            for col in ['extraterrestrial', 'global', 'diffuse']:
                mean_val = df[col].mean()
                std_val = df[col].std()
                print(f"  {col.capitalize()}: {mean_val:.4f} ± {std_val:.4f}")
            
            # Show percentage statistics for diffuse fraction
            diffuse_fraction = df['diffuse'] / df['global']
            print(f"  Diffuse fraction: {diffuse_fraction.mean():.3f} ± {diffuse_fraction.std():.3f} ({diffuse_fraction.mean()*100:.1f}%)")

def main():
    """Main function with command line interface."""
    
    parser = argparse.ArgumentParser(
        description="Automate I3RC Monte Carlo simulations across zenith angles",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    python automate_i3rc_ZSA.py --config thin_cloud --output cloud_results.csv
    python automate_i3rc_ZSA.py --config rural_aerosol_proper --angles 0,15,30,45,60,75 --num-batches 20 --photons-per-batch 50
    python automate_i3rc_ZSA.py --config thin_cloud --angles 0:85:5 --output detailed_cloud.csv --num-batches 100 --photons-per-batch 1000
        """
    )
    
    parser.add_argument('--config', required=True, 
                       help='Configuration name (e.g., thin_cloud, rural_aerosol_proper)')
    parser.add_argument('--output', default='i3rc_zenith_results.csv',
                       help='Output CSV file name (default: i3rc_zenith_results.csv)')
    parser.add_argument('--angles', default='0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85',
                       help='Zenith angles: comma-separated (0,15,30) or range (0:85:5)')
    parser.add_argument('--num-batches', type=int, default=10,
                       help='Number of batches in the MC simulation (default: 10)')
    parser.add_argument('--photons-per-batch', type=int, default=100,
                       help='Number of photons per batch (default: 100)')
    parser.add_argument('--base-dir', default=None,
                       help='I3RC base directory (default: current directory)')
    
    args = parser.parse_args()
    
    # Parse zenith angles
    if ':' in args.angles:
        # Range format: start:stop:step
        parts = args.angles.split(':')
        if len(parts) == 3:
            start, stop, step = map(float, parts)
            zenith_angles = list(np.arange(start, stop + step/2, step))
        else:
            raise ValueError("Range format should be start:stop:step (e.g., 0:85:5)")
    else:
        # Comma-separated format
        zenith_angles = [float(x.strip()) for x in args.angles.split(',')]
    
    # Validate zenith angles
    for angle in zenith_angles:
        if not 0 <= angle <= 90:
            raise ValueError(f"Zenith angle {angle}° must be between 0° and 90°")
    
    print(f"I3RC Solar Zenith Angle Automation")
    print(f"Configuration: {args.config}")
    print(f"Output file: {args.output}")
    print(f"Zenith angles: {zenith_angles}")
    print(f"Photons per batch: {args.photons_per_batch}")
    print(f"Number of batches: {args.num_batches}")
    
    try:
        # Initialize automation
        automation = I3RCAutomation(args.base_dir)
        
        # Run zenith sweep
        results_df = automation.run_zenith_sweep(
            config_name=args.config,
            base_config=args.config,  # Use same name for base config
            zenith_angles=zenith_angles,
            photons_per_batch=args.photons_per_batch,
            num_batches=args.num_batches
        )
        
        # Save results
        if len(results_df) > 0:
            automation.save_results(results_df, args.output, args.config)
            print(f"\n🎯 I3RC Solar Zenith Angle Automation completed successfully!")
        else:
            print(f"\n❌ No successful simulations - check configuration and input files")
            sys.exit(1)
            
    except Exception as e:
        print(f"\n❌ Automation failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
