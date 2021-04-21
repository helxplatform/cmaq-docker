#!/bin/bash

# print commands
set -x
# exit when any command fails
set -euo pipefail
shopt -s inherit_errexit

#  -----------------------
#  Download and build CMAQ
#  -----------------------
if [ -z ${LD_LIBRARY_PATH-} ]
then
  export LD_LIBRARY_PATH=/usr/local/lib
else
  export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/lib
fi

export IOAPI_DIR=/usr/local
export NETCDF_DIR=/usr/local
export NETCDFF_DIR=/usr/local
export PNETCDF_DIR=/usr/local
export MPI_DIR=/usr/local
cd /usr/local/src
git clone -b 5.3.2_singularity https://github.com/lizadams/CMAQ.git CMAQ_REPO
cd CMAQ_REPO
export CMAQ_HOME=$PWD
#  ----------------------------------------------------
#  Use the environment variable CMAQ_HOME if it is set.
#  ----------------------------------------------------
cat >blditfix <<EOF
19,21c19,21
< if (! \$?CMAQ_HOME) then
<  set CMAQ_HOME = \$HOME/CMAQ_REPO
< endif
---
>
>  #set CMAQ_HOME = [your_install_path]/openmpi_4.0.1_gcc_9.1.0_debug
>  set CMAQ_HOME = /home/username/CMAQ_Project
EOF
applydiff bldit_project.csh blditfix -R
./bldit_project.csh
#  -----------------------------------------------------------
#  Use the settings of IOAPI_DIR and NETCDF_DIR instead of
#  requiring the installer to modify the build script by hand.
#  MPI_DIR is not needed if MPI build scripts are used.
#  -----------------------------------------------------------
   cat >configfix <<EOF
81a82,90
>         #> I/O API, netCDF, and MPI library locations
>         setenv IOAPI_INCL_DIR   ioapi_inc_intel    #> I/O API include header files
>         setenv IOAPI_LIB_DIR    ioapi_lib_intel    #> I/O API libraries
>         setenv NETCDF_LIB_DIR   netcdf_lib_intel   #> netCDF C directory path
>         setenv NETCDF_INCL_DIR  netcdf_inc_intel   #> netCDF C directory path
>         setenv NETCDFF_LIB_DIR  netcdff_lib_intel  #> netCDF Fortran directory path
>         setenv NETCDFF_INCL_DIR netcdff_inc_intel  #> netCDF Fortran directory path
>         setenv MPI_LIB_DIR      mpi_lib_intel      #> MPI directory path
>
102a112,120
>         #> I/O API, netCDF, and MPI library locations
>         setenv IOAPI_INCL_DIR   iopai_inc_pgi   #> I/O API include header files
>         setenv IOAPI_LIB_DIR    ioapi_lib_pgi   #> I/O API libraries
>         setenv NETCDF_LIB_DIR   netcdf_lib_pgi  #> netCDF C directory path
>         setenv NETCDF_INCL_DIR  netcdf_inc_pgi  #> netCDF C directory path
>         setenv NETCDFF_LIB_DIR  netcdff_lib_pgi #> netCDF Fortran directory path
>         setenv NETCDFF_INCL_DIR netcdff_inc_pgi #> netCDF Fortran directory path
>         setenv MPI_LIB_DIR      mpi_lib_pgi     #> MPI directory path
>
121a140,148
>         #> I/O API, netCDF, and MPI library locations
>         setenv IOAPI_INCL_DIR   iopai_inc_gcc   #> I/O API include header files
>         setenv IOAPI_LIB_DIR    ioapi_lib_gcc   #> I/O API libraries
>         setenv NETCDF_LIB_DIR   netcdf_lib_gcc  #> netCDF C directory path
>         setenv NETCDF_INCL_DIR  netcdf_inc_gcc  #> netCDF C directory path
>         setenv NETCDFF_LIB_DIR  netcdff_lib_gcc #> netCDF Fortran directory path
>         setenv NETCDFF_INCL_DIR netcdff_inc_gcc #> netCDF Fortran directory path
>         setenv MPI_LIB_DIR      mpi_lib_gcc     #> MPI directory path
>
168a196,200
>  setenv MPI_DIR     \$CMAQ_LIB/mpi
>  setenv NETCDF_DIR  \$CMAQ_LIB/netcdf
>  setenv NETCDFF_DIR \$CMAQ_LIB/netcdff
>  setenv PNETCDF_DIR \$CMAQ_LIB/pnetcdf
>  setenv IOAPI_DIR   \$CMAQ_LIB/ioapi
172,187c204,215
<
< #> Check that NETCDF_DIR, IOAPI_DIR, and PNETCDF_DIR were set, error if not
<  if (! \$?NETCDF_DIR) then
<     echo "ERROR: NETCDF_DIR has not been set, install netCDF and set this variable before proceeding."
<     exit
<  endif
<  if (! \$?NETCDFF_DIR) then
<     setenv NETCDFF_DIR \$NETCDF_DIR
<  endif
<  if (! \$?IOAPI_DIR) then
<     echo "ERROR: IOAPI_DIR has not been set, install IOAPI and set this variable before proceeding."
<     exit
<  endif
<  if (! \$?PNETCDF_DIR) then
<     echo "ERROR: PNETCDF_DIR has not been set, install PNETCDF and set this variable before proceeding."
<     exit
---
>  if (   -e \$MPI_DIR  ) rm -rf \$MPI_DIR
>      ln -s \$MPI_LIB_DIR \$MPI_DIR
>  if ( ! -d \$NETCDF_DIR )  mkdir \$NETCDF_DIR
>  if ( ! -e \$NETCDF_DIR/lib ) ln -sfn \$NETCDF_LIB_DIR \$NETCDF_DIR/lib
>  if ( ! -e \$NETCDF_DIR/include ) ln -sfn \$NETCDF_INCL_DIR \$NETCDF_DIR/include
>  if ( ! -d \$NETCDFF_DIR )  mkdir \$NETCDFF_DIR
>  if ( ! -e \$NETCDFF_DIR/lib ) ln -sfn \$NETCDFF_LIB_DIR \$NETCDFF_DIR/lib
>  if ( ! -e \$NETCDFF_DIR/include ) ln -sfn \$NETCDFF_INCL_DIR \$NETCDFF_DIR/include
>  if ( ! -d \$IOAPI_DIR ) then
>     mkdir \$IOAPI_DIR
>     ln -sfn \$IOAPI_INCL_DIR \$IOAPI_DIR/include_files
>     ln -sfn \$IOAPI_LIB_DIR  \$IOAPI_DIR/lib
192c220
<     echo "ERROR: \$NETCDF_DIR/lib/libnetcdf.a does not exist!!! Check your installation before proceeding with CMAQ build."
---
>     echo "ERROR: \$NETCDF_DIR/lib/libnetcdf.a does not exist in your CMAQ_LIB directory!!! Check your installation before proceeding with CMAQ build."
196c224
<     echo "ERROR: \$NETCDFF_DIR/lib/libnetcdff.a does not exist!!! Check your installation before proceeding with CMAQ build."
---
>     echo "ERROR: \$NETCDFF_DIR/lib/libnetcdff.a does not exist in your CMAQ_LIB directory!!! Check your installation before proceeding with CMAQ build."
200c228
<     echo "ERROR: \$IOAPI_DIR/lib/libioapi.a does not exist!!! Check your installation before proceeding with CMAQ build."
---
>     echo "ERROR: \$IOAPI_DIR/lib/libioapi.a does not exist in your CMAQ_LIB directory!!! Check your installation before proceeding with CMAQ build."
203,204c231,232
<  if ( ! -e \$IOAPI_DIR/include/m3utilio.mod ) then
<     echo "ERROR: \$IOAPI_DIR/include/m3utilio.mod does not exist!!! Check your installation before proceeding with CMAQ build."
---
>  if ( ! -e \$IOAPI_DIR/lib/m3utilio.mod ) then
>     echo "ERROR: \$IOAPI_MOD_DIR/m3utilio.mod does not exist in your CMAQ_LIB directory!!! Check your installation before proceeding with CMAQ build."
EOF
applydiff config_cmaq.csh configfix -R
#  -----------------------------------------------
#  Fix the build scripts to remove redundant paths
#  -----------------------------------------------
#
#  BLDMAKE
#
cd $CMAQ_HOME/UTIL/bldmake/src
cat >cfgfix <<EOF
151d150
<       Character( FLD_LEN ) :: pnetcdf
154,158c153,157
<       Character( FLD_LEN ) :: ioapi_dir
<       Character( FLD_LEN ) :: netcdf_dir
<       Character( FLD_LEN ) :: netcdff_dir
<       Character( FLD_LEN ) :: mpi_dir
<       Character( FLD_LEN ) :: pnetcdf_dir
---
>       Character( FLD_LEN ) :: ioapi_incl_dir
>       Character( FLD_LEN ) :: ioapi_lib_dir
>       Character( FLD_LEN ) :: netcdf_lib_dir
>       Character( FLD_LEN ) :: netcdff_lib_dir
>       Character( FLD_LEN ) :: mpi_lib_dir
EOF
applydiff cfg_module.f cfgfix -R
cat >bldmakefix <<EOF
313,317c313,317
<       Call GETENV( 'IOAPI_DIR', ioapi_dir )
<       Call GETENV( 'NETCDF_DIR', netcdf_dir )
<       Call GETENV( 'NETCDFF_DIR', netcdff_dir )
<       Call GETENV( 'MPI_DIR',    mpi_dir )
<       Call GETENV( 'PNETCDF_DIR', pnetcdf_dir )
---
>       Call GETENV( 'IOAPI_INCL_DIR', ioapi_incl_dir )
>       Call GETENV( 'IOAPI_LIB_DIR',  ioapi_lib_dir )
>       Call GETENV( 'NETCDF_LIB_DIR', netcdf_lib_dir )
>       Call GETENV( 'NETCDFF_LIB_DIR', netcdff_lib_dir )
>       Call GETENV( 'MPI_LIB_DIR',    mpi_lib_dir )
319,323c319,323
<       Write( lfn, '("#      IOAPI:     ",a)' ) Trim( ioapi_dir )
<       Write( lfn, '("#      NETCDF:    ",a)' ) Trim( netcdf_dir )
<       Write( lfn, '("#      NETCDFF:   ",a)' ) Trim( netcdff_dir )
<       Write( lfn, '("#      MPICH:     ",a)' ) Trim( mpi_dir )
<       Write( lfn, '("#      PNETCDF:   ",a)' ) Trim( pnetcdf_dir )
---
>       Write( lfn, '("#      \$(LIB)/ioapi/include_files -> ",a)' ) Trim( ioapi_incl_dir )
>       Write( lfn, '("#      \$(LIB)/ioapi/lib -> ",a)' ) Trim( ioapi_lib_dir )
>       Write( lfn, '("#      \$(LIB)/mpi -> ",a)' ) Trim( mpi_lib_dir )
>       Write( lfn, '("#      \$(LIB)/netcdf -> ",a)' ) Trim( netcdf_lib_dir )
>       Write( lfn, '("#      \$(LIB)/netcdff -> ",a)' ) Trim( netcdff_lib_dir )
345a346,347
>       Write( lfn, '(/" LIB = ",a)' ) Trim( lib_base )
>       Write( lfn, '( " include_path = -I \$(LIB)/",a,1x,a)' ) Trim( lib_1 ), backslash
347,349c349,351
<          Write( lfn, '( " include_path = -I ",a,"/include ",a)' ) Trim( ioapi_dir ), backslash
<          Write( lfn, '( "                -I ",a,"/include ",a)' ) Trim( netcdf_dir ), backslash
<          Write( lfn, '( "                -I ",a,"/include")' ) Trim( mpi_dir )
---
>          Write( lfn, '( "                -I \$(LIB)/",a,1x,a)' ) Trim( lib_2 ), backslash
>          Write( lfn, '( "                -I \$(LIB)/",a,1x,a)' ) Trim( lib_3 ), backslash
>          Write( lfn, '( "                -I \$(LIB)/",a)' )      Trim( lib_5 )
351,352c353,354
<          Write( lfn, '( " include_path = -I ",a,"/include ",a)' ) Trim( ioapi_dir ), backslash
<          Write( lfn, '( "                -I ",a,"/include")' ) Trim( netcdf_dir )
---
>          Write( lfn, '( "                -I \$(LIB)/",a,1x,a)' ) Trim( lib_2 ), backslash
>          Write( lfn, '( "                -I \$(LIB)/",a)' )      Trim( lib_3 )
354c356
<          Write( lfn, '( " include_path = -I ",a,"/include")' ) Trim( ioapi_dir )
---
>          Write( lfn, '( "                -I \$(LIB)/",a,1x,a)' ) Trim( lib_2 )
384c386,390
<       Write( lfn, '( " C_FLAGS   = ",a)' ) Trim( c_flags ) // "-I."
---
>       If ( serial ) Then
>          Write( lfn, '( " C_FLAGS   = ",a)' ) Trim( c_flags ) // "-I."
>       Else
>          Write( lfn, '( " C_FLAGS   = ",a)' ) Trim( c_flags ) // "\$(LIB)/mpi/include -I."
>       End If
406,408c412,414
<       Write( lfn, '(/" IOAPI  = -L",a,"/lib ",a)' ) Trim( ioapi_dir ), Trim( ioapi )
<       Write( lfn, '( " NETCDF = -L",a,"/lib ",a," -L",a,"/lib ",a)' ), Trim( netcdf_dir ),
<      &  Trim( netcdf ), Trim( netcdff_dir ), Trim( netcdff )
---
>       Write( lfn, '(/" IOAPI  = -L\$(LIB)/",a,1x,a)' ) Trim( lib_4 ), Trim( ioapi )
>       Write( lfn, '( " NETCDF = -L\$(LIB)/",a,1x,a, " -L\$(LIB)/",a,1x,a)' )
>      &  ,"netcdff/lib", Trim( netcdff ), "netcdf/lib", Trim(netcdf)
410c416,422
<       Write( lfn, '( " LIBRARIES = \$(IOAPI) \$(NETCDF)")' )
---
>       If ( serial ) Then
>          Write( lfn, '( " LIBRARIES = \$(IOAPI) \$(NETCDF)")' )
>       Else
> !         Write( lfn, '( " MPICH  = -L\$(LIB)/",a,1x,a)' ) "mpich/lib", Trim( mpich )
> !         Write( lfn, '( " MPICH  = -L\$(LIB)/",a,1x,a)' ) "mpi/lib", Trim( mpich )
>          Write( lfn, '( " LIBRARIES = \$(IOAPI) \$(NETCDF) ")' )
>       End If
729c741
<                   Write( lfn, '(1x,a," = ",a,"/include")' ) pathMacro( i ), Trim( mpi_dir )
---
>                   Write( lfn, '(1x,a," = ",a)' ) pathMacro( i ), "\$(LIB)/mpi/include"
EOF
applydiff bldmake.f bldmakefix -R
#
#  BCON
#
cd $CMAQ_HOME/PREP/bcon/scripts
cat >blditfix << EOF
78,81c78,81
<  set xLib_Base  = \${IOAPI_DIR}
<  set xLib_1     = \${IOAPI_DIR}/include
<  set xLib_2     = \${IOAPI_DIR}/include
<  set xLib_4     = \${IOAPI_DIR}/lib
---
>  set xLib_Base  = \${CMAQ_LIB}
>  set xLib_1     = ioapi/lib
>  set xLib_2     = ioapi/include_files
>  set xLib_4     = ioapi/lib
EOF
applydiff bldit_bcon.csh blditfix -R
./bldit_bcon.csh gcc > bldit_bcon.log 2>&1
#
#  ICON
#
cd $CMAQ_HOME/PREP/icon/scripts
cat >blditfix << EOF
78,81c78,81
<  set xLib_Base  = \${IOAPI_DIR}
<  set xLib_1     = \${IOAPI_DIR}/include
<  set xLib_2     = \${IOAPI_DIR}/include
<  set xLib_4     = \${IOAPI_DIR}/lib
---
>  set xLib_Base  = \${CMAQ_LIB}
>  set xLib_1     = ioapi/lib
>  set xLib_2     = ioapi/include_files
>  set xLib_4     = ioapi/lib
EOF
applydiff bldit_icon.csh blditfix -R
./bldit_icon.csh gcc > bldit_icon.log 2>&1
#
#  CCTM
#
cd $CMAQ_HOME/CCTM/scripts
cat >blditfix << EOF
368c368
<  echo "lib_base    \$IOAPI_DIR;"                                    >> \$Cfile
---
>  echo "lib_base    \$CMAQ_LIB;"                                     >> \$Cfile
370c370
<  echo "lib_1       \$IOAPI_DIR/include;"                            >> \$Cfile
---
>  echo "lib_1       ioapi/lib;"                                     >> \$Cfile
372c372
<  echo "lib_2       \$IOAPI_DIR/include;"                            >> \$Cfile
---
>  echo "lib_2       ioapi/include_files;"                           >> \$Cfile
374,377c374,377
< # if ( \$?ParOpt ) then
< #    echo "lib_3       \${quote}mpi -I.\$quote;"                      >> \$Cfile
< #    echo                                                           >> \$Cfile
< # endif
---
>  if ( \$?ParOpt ) then
>     echo "lib_3       \${quote}mpi -I.\$quote;"                      >> \$Cfile
>     echo                                                           >> \$Cfile
>  endif
379c379
<  echo "lib_4       \$IOAPI_DIR/lib;"                                >> \$Cfile
---
>  echo "lib_4       ioapi/lib;"                                     >> \$Cfile
EOF
applydiff bldit_cctm.csh blditfix -R
./bldit_cctm.csh gcc > bldit_cctm.log 2>&1
