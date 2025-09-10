#!/usr/bin/env python3
"""
Convert 3D cloud data to I3RC format
"""

def convert_3d_cloud_data():
    """Convert sparse 3D cloud data to I3RC format."""
    
    # Read the sparse 3D cloud data
    cloud_data = {}
    with open('Input/PhysicalPropertiesToDomain/3d_cloud_data.txt', 'r') as f:
        for line in f:
            parts = line.strip().split()
            if len(parts) == 4:
                x, y, z, lwc = int(parts[0]), int(parts[1]), int(parts[2]), float(parts[3])
                cloud_data[(x, y, z)] = lwc
    
    print(f"Read {len(cloud_data)} cloud data points")
    
    # Determine grid dimensions
    max_x = max(coord[0] for coord in cloud_data.keys())
    max_y = max(coord[1] for coord in cloud_data.keys())
    max_z = max(coord[2] for coord in cloud_data.keys())
    min_z = min(coord[2] for coord in cloud_data.keys())
    
    print(f"Grid dimensions: X={max_x}, Y={max_y}, Z={min_z}-{max_z}")
    
    # Create the formatted file
    with open('Input/PhysicalPropertiesToDomain/3d_cloud_complete.txt', 'w') as f:
        # Write header
        f.write("3\n")  # filekind = 3 (3D format)
        f.write(f"{max_x} {max_y} {max_z}\n")  # nx, ny, nzp
        f.write(" 0.1 0.1\n")  # delx, dely (100m grid spacing)
        
        # Write heights (assuming 500m vertical spacing starting from 0)
        heights = " ".join([f"{i*0.5:.1f}" for i in range(max_z + 2)])
        f.write(f" {heights}\n")
        
        # Write temperatures (linear decrease with height)
        temps = " ".join([f"{288.0 - i*2.0:.1f}" for i in range(max_z + 2)])
        f.write(f" {temps}\n")
        
        # Write cloud data for each cell
        for (x, y, z), lwc in sorted(cloud_data.items()):
            # Convert LWC to mass content and estimate effective radius
            mass_content = lwc / 1000.0  # Convert g/m³ to kg/m³ 
            effective_radius = 10.0  # Typical cloud droplet effective radius (μm)
            
            # Format: ix iy iz nc pt(i) mass(i) re(i)
            # nc=1 (one component), pt=1 (water droplets)
            f.write(f" {x} {y} {z}  1 1 {mass_content:.6f} {effective_radius:.1f}\n")
    
    print("Created 3d_cloud_complete.txt")

if __name__ == "__main__":
    import os
    os.chdir(r"c:\Users\PC\Documents\GitHub\I3RC")
    convert_3d_cloud_data()
