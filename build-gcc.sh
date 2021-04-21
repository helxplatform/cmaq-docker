#!/bin/bash

# print commands
set -x
# exit when any command fails
set -euo pipefail
shopt -s inherit_errexit

#  --------------------------------------
#  Add /usr/local/lib to the library path
#  --------------------------------------
if [ -z ${LD_LIBRARY_PATH-} ]
then
   export LD_LIBRARY_PATH=/usr/local/lib
else
   export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/lib
fi
#  -----------------------
#  Download and build HDF5
#  -----------------------
cd /usr/local/src
wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.10/hdf5-1.10.5/src/hdf5-1.10.5.tar.gz
tar xvf hdf5-1.10.5.tar.gz
rm -f hdf5-1.10.5.tar.gz
cd hdf5-1.10.5
export CFLAGS="-O3"
export FFLAGS="-O3"
export CXXFLAGS="-O3"
export FCFLAGS="-O3"
./configure --prefix=/usr/local --enable-fortran --enable-cxx --enable-shared --with-pic
make > make.gcc9.log 2>&1
#  make check > make.gcc9.check
make install
#  ---------------------------
#  Download and build netCDF-C
#  ---------------------------
cd /usr/local/src
wget https://www.unidata.ucar.edu/downloads/netcdf/ftp/netcdf-c-4.7.1.tar.gz
tar xvf netcdf-c-4.7.1.tar.gz
rm -f netcdf-c-4.7.1.tar.gz
cd netcdf-c-4.7.1
./configure --with-pic --enable-netcdf-4 --enable-shared --prefix=/usr/local
make > make.gcc9.log 2>&1
make install
#  ---------------------------------
#  Download and build netCDF-Fortran
#  ---------------------------------
cd /usr/local/src
wget https://www.unidata.ucar.edu/downloads/netcdf/ftp/netcdf-fortran-4.5.2.tar.gz
tar xvf netcdf-fortran-4.5.2.tar.gz
rm -f netcdf-fortran-4.5.2.tar.gz
cd netcdf-fortran-4.5.2
export LIBS="-lnetcdf"
./configure --with-pic --enable-shared --prefix=/usr/local
make > make.gcc9.log 2>&1
make install
#  -----------------------------
#  Download and build netCDF-CXX
#  -----------------------------
cd /usr/local/src
wget https://www.unidata.ucar.edu/downloads/netcdf/ftp/netcdf-cxx4-4.3.1.tar.gz
tar xvf netcdf-cxx4-4.3.1.tar.gz
rm -f netcdf-cxx4-4.3.1.tar.gz
cd netcdf-cxx4-4.3.1
./configure --with-pic --enable-shared --prefix=/usr/local
make > make.gcc9.log 2>&1
make install
#  --------------------------
#  Download and build OpenMPI
#  --------------------------
cd /usr/local/src
wget https://download.open-mpi.org/release/open-mpi/v3.1/openmpi-3.1.4.tar.gz
tar xvf openmpi-3.1.4.tar.gz
rm -f openmpi-3.1.4.tar.gz
cd openmpi-3.1.4
export CFLAGS="-O3"
export FFLAGS="-O3"
export CXXFLAGS="-O3"
export FCFLAGS="-O3"
./configure --prefix=/usr/local --enable-mpi-cxx
make > make.gcc9.log 2>&1
#  make check > make.gcc9.check
make install
#  ----------------------------------
#  Download and build Parallel netCDF
#  ----------------------------------
cd /usr/local/src
wget https://parallel-netcdf.github.io/Release/pnetcdf-1.11.2.tar.gz
tar xvf pnetcdf-1.11.2.tar.gz
rm -f pnetcdf-1.11.2.tar.gz
cd pnetcdf-1.11.2
export CFLAGS="-O3 -fPIC"
export FFLAGS="-O3 -fPIC"
export CXXFLAGS="-O3 -fPIC"
export FCFLAGS="-O3 -fPIC"
./configure --prefix=/usr/local MPIF77=mpif90 MPIF90=mpif90 MPICC=mpicc MPICXX=mpicxx --with-mpi=/usr/local
make > make.gcc9.log 2>&1
make install
#  ----------------------------------------
#  Use tcsh 6.20 instead of the broken 6.21
#  ----------------------------------------
cd /usr/local/src
wget http://ftp.funet.fi/pub/mirrors/ftp.astron.com/pub/tcsh/old/tcsh-6.20.00.tar.gz
tar xvf tcsh-6.20.00.tar.gz
rm -f tcsh-6.20.00.tar.gz
cd tcsh-6.20.00
./configure --disable-nls
make > make.gcc9.log 2>&1
make install
ln -s /usr/local/bin/tcsh /bin/csh
#  ----------------------
#  Download and build vim
#  ----------------------
cd /usr/local/src
git clone https://github.com/vim/vim.git vim
cd vim
./configure
make > make.gcc9.log 2>&1
make install
cd /usr/local/bin
ln -s vim vi
