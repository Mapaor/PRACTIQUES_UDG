# $Revision: 19 $, $Date: 2009-04-19 18:27:41 +0100 (Sun, 19 Apr 2009) $
# $URL: http://i3rc-monte-carlo-model.googlecode.com/svn/trunk/Makefile $

### Installation directory

I3RC_Home = /mnt/c/Users/PC/Documents/GitHub/I3RC/I3RC-Monte-Carlo-Model
CodeDir    = $(I3RC_Home)/Code
IntegDir   = $(I3RC_Home)/Integrators
 
### Netcdf-specific entries for Ubuntu/WSL

NetcdfHome = /usr
Netcdf_IncludeDir = $(NetcdfHome)/include 
NetcdfLibs = -L$(NetcdfHome)/lib/x86_64-linux-gnu -lnetcdff -lnetcdf

### General compiler macros 

ModuleFlag = -I
Modules     = $(ModuleFlag)$(Netcdf_IncludeDir) $(ModuleFlag)/usr/include/hdf5/serial
Libs        = $(NetcdfLibs) -lgfortran 
Compile.F95 = $(F95) $(F95Flags) -c
Compile.F77 = $(F77) $(FFlags)   -c
Link.F95    = $(F95) $(F95Flags) 

### MPI-specific entries, if any 
#
# Set UseMPI to "yes" and specify the appropriate values for the 
#   MPI_Dir, MPI_IncludeDir, and MPI_LibDir directories to enable 
#   the use of multiple processors
#
UseMPI=no
ifeq ($(UseMPI),yes)  
  MPI_Dir = NULL
  MPI_IncludeDir=$(MPI_Dir)/include
  MPI_LibDir=$(MPI_Dir)/lib
  Libs += $(MPI_LibDir) -lmpi 
  # MPI and non-MPI versions live in $(CodeDir)
  multipleProcCode = multipleProcesses_mpi.o
  F95Flags += $(ModuleFlag)$(MPI_IncludeDir)  
else 
  multipleProcCode = multipleProcesses_nompi.o
endif

#### Compiler-specific entries (may override marcos above) 

# Macros are available for ifort, gfortran, g95, xlf, absoft
compiler=gfortran
debug=yes

ifeq ($(compiler),ifort)
  #
  # Intel fortran 
  #
  F95         = ifort
  F77         = ifort
  Compile.F95 += -free -Tf
  ifeq ($(debug),no) 
    # Optimization flags. 
    F95Flags = -O3 -heap-arrays -diag-disable vec -ipo $(Modules) 
    FFlags   = -fast 
  else
    # Debugging flags
    F95Flags = -g -O2 -heap-arrays -C -traceback -diag-disable vec $(Modules) 
    FFLAGS   = -g -O2 -heap-arrays -C -traceback -diag-disable vec 
  endif
endif

ifeq ($(compiler),g95)
  #
  # GNU fortran 
  #
  F95         = g95
  F77         = g77
  ifeq ($(debug),no) 
    # Optimization flags. 
    F95Flags = -O2 -std=f95 $(Modules) 
    FFLAGS   = -O2
  else
    # Debugging flags
    F95Flags = -g -std=f95 -fmodule-private -fimplicit-none -Wall $(Modules)
    FFLAGS   = -g                           -fimplicit-none -Wall 
  endif
endif

ifeq ($(compiler),gfortran)
  #
  # GNU gfortran (modern version) - configured for legacy I3RC code
  #
  F95         = gfortran
  F77         = gfortran
  ifeq ($(debug),no) 
    # Optimization flags with legacy support
    F95Flags = -O2 -ffree-form -fno-range-check -std=legacy $(Modules) 
    FFLAGS   = -O2 -fno-range-check -std=legacy
  else
    # Debugging flags with legacy support
    F95Flags = -g -ffree-form -fno-range-check -std=legacy -Wall $(Modules)
    FFLAGS   = -g -fno-range-check -std=legacy -Wall 
  endif
endif

ifeq ($(compiler),xlf)
  #
  # IBM xlf 8 for Mac 
  #
  F95         = f95
  F77         = f77
  ifeq ($(debug),no) 
    # Optimization flags. 
    F95Flags = -O3 -qlanglvl=95std $(Modules) 
    FFLAGS   = -O3
  else
    # Debugging flags
    F95Flags = -g -O2 -C -qlanglvl=95std -qmaxmem=-1  $(Modules)
    FFLAGS   = -g                      
  endif
endif

ifeq ($(compiler),absoft)
  #
  # absoft fortran 
  #
  F95        = f95
  F77        = f77
  ModuleFlag = -p
  Libs      += -lU77
  ifeq ($(debug),no) 
    # Optimization flags. 
    F95Flags = -O3  -stack_size 0x10000000 -cpu:host $(Modules)  
    FFlags   = -O3  -stack_size 0x10000000 -cpu:host 
  else 
    ##Debugging flags
    F95Flags = -g $(Modules) 
    FFLAGS   = -g 
  endif
endif

### General rules - should not require editing

# Rules for bullding object files
%.o: %.f
	$(Compile.F77) $<

%.o: %.f95
	$(Compile.F95) $<

# Rule to build executables	- some compilers are happier if everything 
#   is an object file 
%: %.o
	$(Link.F95) -o $@ $^ $(Libs)

