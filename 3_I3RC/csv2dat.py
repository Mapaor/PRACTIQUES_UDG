#!/usr/bin/env python3
"""
Convert I3RC CSV output to .dat format for plotting/analysis.

Usage:
    python csv2dat.py input.csv output.dat

Output format:
# KT DF
KT_value DF_value
...
Where:
  KT = global / extraterrestrial
  DF = diffuse / global
"""
import sys
import pandas as pd

if len(sys.argv) < 3:
    print("Usage: python csv2dat.py input.csv output.dat")
    sys.exit(1)

input_csv = sys.argv[1]
output_dat = sys.argv[2]

# Read CSV, skip comment lines
with open(input_csv, 'r') as f:
    lines = [line for line in f if not line.startswith('#') and line.strip()]

# If no data, exit
if len(lines) < 2:
    print("No data found in CSV.")
    sys.exit(1)

# Read into DataFrame
from io import StringIO
df = pd.read_csv(StringIO(''.join(lines)))

# Compute KT and DF
kt = df['global'] / df['extraterrestrial']
df_frac = df['diffuse'] / df['global']

# Write .dat file
with open(output_dat, 'w') as f:
    f.write("# KT DF\n")
    for k, d in zip(kt, df_frac):
        f.write(f"{k:.4f} {d:.4f}\n")

print(f"✓ Converted {input_csv} to {output_dat} in KT/DF format.")
