#!/usr/bin/env python3
"""
Test script to demonstrate direct/diffuse radiation separation using scattering order analysis.

This script shows how to analyze the scattering order output files to separate
direct from diffuse radiation components.
"""

import numpy as np
import matplotlib.pyplot as plt

def analyze_scattering_order_results(file_prefix):
    """
    Analyze scattering order results to separate direct vs diffuse radiation.
    
    Direct radiation: scattering order = 0 (no scattering events)
    Diffuse radiation: scattering order >= 1 (one or more scattering events)
    """
    
    try:
        # Load upward flux data
        up_data = np.loadtxt(f'{file_prefix}_fluxUpByOrder.txt', 
                           dtype=[('x', int), ('y', int), ('order', int), ('flux', float)])
        
        # Load downward flux data  
        down_data = np.loadtxt(f'{file_prefix}_fluxDownByOrder.txt',
                             dtype=[('x', int), ('y', int), ('order', int), ('flux', float)])
        
        print("=== SCATTERING ORDER ANALYSIS ===")
        print(f"Loaded {len(up_data)} upward flux records")
        print(f"Loaded {len(down_data)} downward flux records")
        
        # Analyze upward flux (e.g., TOPDN - radiation exiting at top)
        up_direct = up_data[up_data['order'] == 0]  # Direct (unscattered)
        up_diffuse = up_data[up_data['order'] >= 1]  # Diffuse (scattered)
        
        total_up_direct = np.sum(up_direct['flux']) if len(up_direct) > 0 else 0.0
        total_up_diffuse = np.sum(up_diffuse['flux']) if len(up_diffuse) > 0 else 0.0
        total_up = total_up_direct + total_up_diffuse
        
        print(f"\nUpward Flux (TOPDN equivalent):")
        print(f"  Direct component:   {total_up_direct:.6e} W/m²")
        print(f"  Diffuse component:  {total_up_diffuse:.6e} W/m²")
        print(f"  Total upward:       {total_up:.6e} W/m²")
        if total_up > 0:
            print(f"  Direct fraction:    {total_up_direct/total_up*100:.2f}%")
            print(f"  Diffuse fraction:   {total_up_diffuse/total_up*100:.2f}%")
        
        # Analyze downward flux (e.g., BOTDN - radiation exiting at bottom)
        down_direct = down_data[down_data['order'] == 0]  # Direct (unscattered)
        down_diffuse = down_data[down_data['order'] >= 1]  # Diffuse (scattered)
        
        total_down_direct = np.sum(down_direct['flux']) if len(down_direct) > 0 else 0.0
        total_down_diffuse = np.sum(down_diffuse['flux']) if len(down_diffuse) > 0 else 0.0
        total_down = total_down_direct + total_down_diffuse
        
        print(f"\nDownward Flux (BOTDN equivalent):")
        print(f"  Direct component:   {total_down_direct:.6e} W/m²")
        print(f"  Diffuse component:  {total_down_diffuse:.6e} W/m²")
        print(f"  Total downward:     {total_down:.6e} W/m²")
        if total_down > 0:
            print(f"  Direct fraction:    {total_down_direct/total_down*100:.2f}%")
            print(f"  Diffuse fraction:   {total_down_diffuse/total_down*100:.2f}%")
        
        # Analyze scattering order distribution
        print(f"\nScattering Order Distribution:")
        max_order = max(np.max(up_data['order']) if len(up_data) > 0 else 0,
                       np.max(down_data['order']) if len(down_data) > 0 else 0)
        
        for order in range(min(max_order + 1, 6)):  # Show up to order 5
            up_flux = np.sum(up_data[up_data['order'] == order]['flux']) if len(up_data) > 0 else 0.0
            down_flux = np.sum(down_data[down_data['order'] == order]['flux']) if len(down_data) > 0 else 0.0
            total_flux = up_flux + down_flux
            
            print(f"  Order {order}: {total_flux:.6e} W/m² ({up_flux:.2e} up, {down_flux:.2e} down)")
        
        return {
            'up_direct': total_up_direct,
            'up_diffuse': total_up_diffuse,
            'down_direct': total_down_direct,
            'down_diffuse': total_down_diffuse,
            'total_up': total_up,
            'total_down': total_down
        }
        
    except FileNotFoundError as e:
        print(f"Error: Could not find scattering order files with prefix '{file_prefix}'")
        print(f"Expected files: {file_prefix}_fluxUpByOrder.txt, {file_prefix}_fluxDownByOrder.txt")
        print(f"Make sure to run the I3RC model with scattering order tracking enabled.")
        return None
    except Exception as e:
        print(f"Error analyzing scattering order results: {e}")
        return None

def create_example_analysis():
    """
    Create example analysis showing the research workflow.
    """
    print("=== DIRECT/DIFFUSE RADIATION SEPARATION WORKFLOW ===")
    print()
    print("1. Run I3RC Monte Carlo model with scattering order tracking")
    print("2. Model outputs scattering order files:")
    print("   - [prefix]_fluxUpByOrder.txt")
    print("   - [prefix]_fluxDownByOrder.txt")
    print("3. Analyze results to separate direct vs diffuse components")
    print()
    print("Key insights:")
    print("- Order 0: Direct radiation (unscattered)")
    print("- Order ≥1: Diffuse radiation (scattered)")
    print("- Higher orders: Multiple scattering events")
    print()
    print("Research applications:")
    print("- Cloud radiative forcing analysis")
    print("- Atmospheric heating rate calculations")
    print("- Remote sensing algorithm development")
    print("- Climate model validation")
    print()
    
    # Example theoretical values
    print("=== EXAMPLE RESULTS (Theoretical) ===")
    print("Scenario: Thin cirrus cloud, solar zenith angle 30°")
    print()
    print("Upward Flux (TOPDN):")
    print("  Direct component:   8.45e+02 W/m² (85.3%)")
    print("  Diffuse component:  1.46e+02 W/m² (14.7%)")
    print("  Total upward:       9.91e+02 W/m²")
    print()
    print("Downward Flux (BOTDN):")
    print("  Direct component:   7.82e+02 W/m² (78.9%)")
    print("  Diffuse component:  2.09e+02 W/m² (21.1%)")
    print("  Total downward:     9.91e+02 W/m²")
    print()
    print("Scattering Order Distribution:")
    print("  Order 0: 1.63e+03 W/m² (82.1%) - Direct")
    print("  Order 1: 2.89e+02 W/m² (14.6%) - Single scattering")
    print("  Order 2: 5.67e+01 W/m² (2.9%)  - Double scattering")
    print("  Order 3: 7.82e+00 W/m² (0.4%)  - Triple scattering")

if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 1:
        # Analyze actual results
        file_prefix = sys.argv[1]
        results = analyze_scattering_order_results(file_prefix)
    else:
        # Show example workflow
        create_example_analysis()
