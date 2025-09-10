#!/bin/bash
# Quick test of Monte Carlo model without the segfault issue
# Run with smaller parameters to reduce memory pressure

cd /mnt/c/Users/PC/Documents/GitHub/I3RC

# Create a reduced parameter input file to avoid memory issues
cp Input/MonteCarloDriver/MonteCarloDriver.nml Input/MonteCarloDriver/MonteCarloDriver_small.nml

# Reduce the number of photons to reduce memory usage
sed -i 's/numPhotonsPerBatch = 100/numPhotonsPerBatch = 50/' Input/MonteCarloDriver/MonteCarloDriver_small.nml
sed -i 's/numBatches = 100/numBatches = 50/' Input/MonteCarloDriver/MonteCarloDriver_small.nml

echo "Testing with reduced parameters..."
ulimit -s unlimited
./I3RC-Monte-Carlo-Model/Example-Drivers/monteCarloDriver Input/MonteCarloDriver/MonteCarloDriver_small.nml

echo ""
echo "Results should be in Output/monteCarloDriver/ even if segfault occurs"
echo "The segfault happens during cleanup, after results are written"
