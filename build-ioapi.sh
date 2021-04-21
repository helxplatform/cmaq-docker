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
#  ----------------------
#  Unpack and build IOAPI
#  ----------------------
   cd /usr/local/src
   git clone --branch 20200828 https://github.com/cjcoats/ioapi-3.2.git
#  -------------------------------------------
#  Add -fPIC so we can create a shared library
#  and disable openmp because not used in CMAQ
#  -------------------------------------------
   cd ioapi-3.2
   cp -p Makefile.template Makefile
   export BIN=Linux2_x86_64
   export BASEDIR=/usr/local/src/ioapi-3.2
   export CPLMODE=nocpl
   cd ioapi
   cat >fpicfix <<EOF
27c27
< MFLAGS    = -fPIC -m64
---
> MFLAGS    = -ffast-math -funroll-loops -m64  #  -Wall -Wsurprising -march=native -mtune=native
29,30c29,30
< OMPFLAGS  = # -fopenmp
< OMPLIBS   = # -fopenmp
---
> OMPFLAGS  = -fopenmp
> OMPLIBS   = -fopenmp
EOF
   applydiff Makeinclude.Linux2_x86_64 fpicfix -R
   #cd ..
   cp Makefile.nocpl Makefile
   export HOME=/usr/local/src
   mkdir ../$BIN
   make > make.gcc9.log 2>&1
   cd ..
   cd m3tools
   cp Makefile.nocpl Makefile
   make > make.m3tools 2>&1
   cd ..
   mkdir lib bin
   cd Linux2_x86_64
   mv * ../bin
   cd ../bin
   mv *.o *.mod ../Linux2_x86_64
   mv *.a ../lib
   cd ../Linux2_x86_64
   ls -1 ../bin | xargs -I % sh -c 'ln -s ../bin/% %'
   cd ../lib
   ld -o libioapi.so -shared --whole-archive libioapi.a
   cd ../Linux2_x86_64
   ln -s ../lib/libioapi.a
   ln -s ../lib/libioapi.so
   cd ..
   cp -p bin/* /usr/local/bin
   cp -p lib/* /usr/local/lib
   cp -p Linux2_x86_64/*.mod /usr/local/include
#  -------------------------------------------------------
#  Only crusty old fixed source code should need the IOAPI
#  EXT files. Newer code should be USE-ing a module.
#  -------------------------------------------------------
   cp -p ioapi/fixed_src/*.EXT /usr/local/include
