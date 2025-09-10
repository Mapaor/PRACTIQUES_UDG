run_MC_model is the scrip to do an end-to-end example calculation for the I3RC Community Monte Carlo Radiative Transfer Model

$The source code is provided by Robert-Pincus and Cornish-Gilliflower
$Revision: 31 $, $Date: 2010-06-14 23:12:00 +0100 (Mon, 14 Jun 2010) $ 
$Compilation with Mac OS 10.5, Intel Core, netcdf 3.6.1 and absoft 1.0.3 by Stefani Huang at July 02 2010

=== What's in the package===
1) I3RC-Monte-Carlo-Model : Source code of the Monte Carlo Model
2) Input : All input files for the model, modify following 4 files for your own purpose, readme files are available for each of them.
    a. MakeMieTable/mie_table_cloud.nml
    b. PhysicalPropertiesToDomain/cloud_domain.nml,cloud.txt
    c. monteCarloDriver/MonteCarloDriver.nml
3) Output : All output files for each step
    a. MakeMieTable : netcdf file
    b. PhysicalPropertiesToDomain : netcdf file
    c. monteCarloDriver : three ascii files and one netcdf file. 

===What the scrip does===
One click to complete the three steps in the model : 
1) MakeMieTable creates a table of single scattering properties at a given wavelength for a size distribution of spheres as a function of size
2) PhysicalPropertieToDomain reads several kinds of formatted ASCII files describing concentration, drop sizes or numbers, etc., 
     combines them with the phaseFunctionTables, and produces a file describing the domain.
3) monteCarloDriver reads the domain, computes the radiative transfer, and writes out the results.

=== How to run===
1) Modify all files in the "Input" folder
2) Execute "./run_MC_model" on your computer
3) Get results from "Output" folder. 



