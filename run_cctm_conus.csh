#!/bin/csh -f

# ===================== CCTMv5.3.2 Run Script =========================
# Usage: run.cctm >&! cctm_v532.2016_12SE1.log &
#
# To report problems or request help with this script/program:
#             http://www.epa.gov/cmaq    (EPA CMAQ Website)
#             http://www.cmascenter.org  (CMAS Website)
# ===================================================================
set bar = '-=-=--=-=-=-=--=-=-=-=--=-=-=-=--=-=-=-=--=-=-=-=--=-=-=-=--=-=-'
# ===================================================================
#>      Runtime Environment Options
# ===================================================================

setenv limit unlimited

setenv CMAQ_HOME        /usr/local/src/CMAQ_REPO
setenv CMAQ_DATA        $CMAQ_HOME/data

echo 'Start Model Run At ' `date`

#>      Set General Parameters for Configuring the Simulation
#>      Code Version
#>      Mechanism ID
set VRSN      = v532
set MECH      = cb6r3_ae7_aq

#>      Toggle Diagnostic Mode which will print verbose information to standard output:
#>           0:  none,
#>           1:  environment and file-listing diagnostics
#>           2:  "set echo" + file-listing diagnostics
#>      Date&Time Parameters
#>      Application Name (e.g. Gridname)
#>      Choose compiler and set up CMAQ environment with correct
#>      libraries using config.cmaq. Options: intel | gcc | pgi

if ( ! $?CTM_DIAG_LVL     )   setenv CTM_DIAG_LVL 0
if (   $CTM_DIAG_LVL >= 2 )   set echo

if ( ! $?NEW_START  )  setenv NEW_START     TRUE
if ( ! $?START_DATE )  setenv START_DATE    "2015-12-22"
if ( ! $?END_DATE   )  setenv END_DATE      "2015-12-22"
if ( ! $?START_TIME )  setenv START_TIME    000000
if ( ! $?RUN_LENGTH )  setenv RUN_LENGTH    240000
if ( ! $?TIME_STEP  )  setenv TIME_STEP     10000
if ( ! $?NMLDIR     )  setenv NMLDIR        ${CMAQ_HOME}/CCTM/scripts/BLD_CCTM_${VRSN}_gcc

if ( ! $?APPL       )  setenv APPL           12US2
if ( ! $?EMIS       )  setenv EMIS           2016fh
if ( ! $?PROC       )  setenv PROC           mpi
if ( ! $?NPCOL      )  setenv NPCOL          6
if ( ! $?NPROW      )  setenv NPROW          6

if ( ! $?NZ             ) setenv NZ                35
if ( ! $?YYYYMM         ) setenv YYYYMM            201512
if ( ! $?CTM_ABFLUX     ) setenv CTM_ABFLUX        N
if ( ! $?CTM_BIOGEMIS   ) setenv CTM_BIOGEMIS      N
if ( ! $?CTM_OCEAN_CHEM ) setenv CTM_OCEAN_CHEM    N


if ( ! $?EXECUTION_ID ) setenv EXECUTION_ID   "CMAQ_CCTM${VRSN}_`id -u -n`_`date -u +%Y%m%d_%H%M%S_%N`"

@ RUN_DAYS = ${RUN_LENGTH} / 240000

#>      Set the build directory:  This is where the CMAQ executable is located.
#>      Define RUNID as any combination of parameters above or others. By default,
#>      this information will be collected into this one string, $RUNID, for easy
#>      referencing in output binaries and log files as well as in other scripts.

if ( $?DEBUG ) then
    set compiler = gccdbg
else
    set compiler = gcc
endif

echo "VRSN    = ${VRSN}"
echo "compiler= ${compiler}"
echo "APPL    = ${APPL}"

if ( ! $?RUNID      )   setenv RUNID        ${VRSN}_${compiler}_${APPL}
if ( ! $?MPIVERSION )   setenv $MPIVERSION  openmpi

switch ( ${MPIVERSION} )
    case mvapich*:
        set BLD = ${CMAQ_HOME}/CCTM/scripts/BLD_CCTM_${VRSN}_${compiler}-mvapich2
        alias mpirun /usr/lib64/mvapich2/bin/mpirun
        breaksw
    case mpich*:
        set BLD = ${CMAQ_HOME}/CCTM/scripts/BLD_CCTM_${VRSN}_${compiler}-mpich
        alias mpirun /usr/lib64/mpich/bin/mpirun
        breaksw
    case openmpi*:
        set BLD = ${CMAQ_HOME}/CCTM/scripts/BLD_CCTM_${VRSN}_${compiler}
        alias mpirun /usr/local/bin/mpirun
        breaksw
    default:
        echo ${bar}
        echo "ERROR:  MPIVERSION = ${MPIVERSION} not supported"
        exit( 2 )
endsw

#if ( $?BLDDIR ) setenv BLD ${BLDDIR}

if ( ! $?EXEC )  set EXEC = ${BLD}/CCTM_${VRSN}.exe


#>      Set Working, Input, Log, and Output Directories; grid description file
 set WORKDIR = ${CMAQ_HOME}/CCTM/script
 set DATADIR = ${CMAQ_DATA}/${APPL}
 set LOGDIR  = ${DATADIR}/logs
 set OUTDIR  = $DATADIR/cctm

if ( ! $?GRIDDESC )     setenv GRIDDESC ${DATADIR}/GRIDDESC

 echo ""
 echo "Working Directory is $WORKDIR"
 echo "Build Directory   is $BLD"
 echo "Output Directory  is $OUTDIR"
 echo "Log Directory     is $LOGDIR"
 echo "Executable Name   is $BLD/$EXEC"

# =====================================================================
#>      CCTM Configuration Options
# =====================================================================

#>      Set Timestepping Parameters
 set STTIME     = ${START_TIME}           #>      beginning GMT time (HHMMSS)
 set NSTEPS     = ${RUN_LENGTH}           #>      time duration (HHMMSS) for this run
 set TSTEP      = ${TIME_STEP}            #>      output time step interval (HHMMSS)

#>      Horizontal domain decomposition
if ( $PROC == serial ) then
   setenv NPCOL_NPROW "1 1"; set NPROCS   = 1 # single processor setting
else
   @ NPROCS = $NPCOL * $NPROW
   setenv NPCOL_NPROW "$NPCOL $NPROW";
endif

#>      Define Execution ID: e.g. [CMAQ-Version-Info]_[User]_[Date]_[Time]
echo ""
echo "---CMAQ EXECUTION ID: $EXECUTION_ID ---"

#>      Keep or Delete Existing Output Files
set CLOBBER_DATA = TRUE

#>      Logfile Options
#>      Master Log File Name; uncomment to write standard output to a log, otherwise write to screen
#setenv LOGFILE $CMAQ_HOME/$RUNID.log
if (! -e $LOGDIR )  mkdir -p $LOGDIR

setenv PRINT_PROC_TIME  Y  ##   Print timing for all science subprocesses to Logfile
                           ##     [ default: TRUE or Y ]
setenv STDOUT           T  ##   Override I/O-API trying to write information to both the processor
                           ##     logs and STDOUT [ options: T | F ]

if ( ! $?GRID_NAME          ) setenv GRID_NAME          ${APPL} ##   check GRIDDESC file for GRID_NAME options

#>      Output Species and Layer Options
#>      CONC file species; comment or set to "ALL" to write all species to CONC
if ( ! $?CONC_SPCS          ) setenv CONC_SPCS         "O3 NO ANO3I ANO3J NO2 FORM ISOP NH3 ANH4I ANH4J ASO4I ASO4J"
if ( ! $?CONC_BLEV_ELEV     ) setenv CONC_BLEV_ELEV    "1 1"##   CONC file layer range; comment to write all layers to CONC

#>      ACONC file species; comment or set to "ALL" to write all species to ACONC
#if( ! $?AVG_CONC_SPCS      ) setenv AVG_CONC_SPCS     "O3 NO CO NO2 ASO4I ASO4J NH3"
if ( ! $?AVG_CONC_SPCS      ) setenv AVG_CONC_SPCS     "ALL"
if ( ! $?ACONC_BLEV_ELEV    ) setenv ACONC_BLEV_ELEV   "1 1"   ##   ACONC file layer range; comment to write all layers to ACONC
if ( ! $?AVG_FILE_ENDTIME   ) setenv AVG_FILE_ENDTIME   N      ##   override default beginning ACONC timestamp [ default: N ]

#>      Synchronization Time Step and Tolerance Options
if ( ! $?CTM_MAXSYNC        ) setenv CTM_MAXSYNC      300      ##   max sync time step (sec) [ default: 720 ]
if ( ! $?CTM_MINSYNC        ) setenv CTM_MINSYNC       60      ##   min sync time step (sec) [ default: 60 ]
if ( ! $?SIGMA_SYNC_TOP     ) setenv SIGMA_SYNC_TOP     0.7    ##   top sigma level thru which sync step determined [ default: 0.7 ]
#if( ! $?ADV_HDIV_LIM       ) setenv ADV_HDIV_LIM       0.95   ##   maximum horiz. div. limit for adv step adjust [ default: 0.9 ]
if ( ! $?CTM_ADV_CFL        ) setenv CTM_ADV_CFL        0.95   ##   max CFL [ default: 0.75]
#if ( ! $?RB_ATOL           ) setenv RB_ATOL            1.0E-09##   global ROS3 solver absolute tolerance [ default: 1.0E-07 ]

#>      Science Options
if ( ! $?CTM_OCEAN_CHEM     ) setenv CTM_OCEAN_CHEM     Y      ##   Flag for ocean halgoen chemistry and sea spray aerosol emissions [ default: Y ]
if ( ! $?CTM_WB_DUST        ) setenv CTM_WB_DUST        N      ##   use inline windblown dust emissions [ default: Y ]
if ( ! $?CTM_WBDUST_BELD    ) setenv CTM_WBDUST_BELD    BELD3  ##   landuse database for identifying dust source regions
                                                               ##      [ default: UNKNOWN ]; ignore if CTM_WB_DUST = N
if ( ! $?CTM_LTNG_NO        ) setenv CTM_LTNG_NO        N      ##   turn on lightning NOx [ default: N ]
if ( ! $?KZMIN              ) setenv KZMIN              Y      ##   use Min Kz option in edyintb [ default: Y ],
                                                               ##      otherwise revert to Kz0UT
if ( ! $?CTM_MOSAIC         ) setenv CTM_MOSAIC         N      ##   landuse specific deposition velocities [ default: N ]
if ( ! $?CTM_FST            ) setenv CTM_FST            N      ##   mosaic method to get land-use specific stomatal flux
                                                               ##      [ default: N ]
if ( ! $?PX_VERSION         ) setenv PX_VERSION         Y      ##   WRF PX LSM
if ( ! $?CLM_VERSION        ) setenv CLM_VERSION        N      ##   WRF CLM LSM
if ( ! $?NOAH_VERSION       ) setenv NOAH_VERSION       N      ##   WRF NOAH LSM
if ( ! $?CTM_ABFLUX         ) setenv CTM_ABFLUX         Y      ##   ammonia bi-directional flux for in-line deposition
                                                               ##      velocities [ default: N ]
if ( ! $?CTM_BIDI_FERT_NH3  ) setenv CTM_BIDI_FERT_NH3  T      ##   subtract fertilizer NH3 from emissions because it will be handled
                                                               ##      by the BiDi calculation [ default: Y ]
if ( ! $?CTM_HGBIDI         ) setenv CTM_HGBIDI         N      ##   mercury bi-directional flux for in-line deposition
                                                               ##      velocities [ default: N ]
if ( ! $?CTM_SFC_HONO       ) setenv CTM_SFC_HONO       Y      ##   surface HONO interaction [ default: Y ]
if ( ! $?CTM_GRAV_SETL      ) setenv CTM_GRAV_SETL      Y      ##   vdiff aerosol gravitational sedimentation [ default: Y ]
if ( ! $?CTM_BIOGEMIS       ) setenv CTM_BIOGEMIS       Y      ##   calculate in-line biogenic emissions [ default: N ]

#>      Vertical Extraction Options
if ( ! $?VERTEXT            ) setenv VERTEXT            N
if ( ! $?VERTEXT_COORD_PATH ) setenv VERTEXT_COORD_PATH ${WORKDIR}/lonlat.csv

#>      I/O Controls
setenv IOAPI_LOG_WRITE      F       ##   turn on excess WRITE3 logging [ options: T | F ]
setenv FL_ERR_STOP          N       ##   stop on inconsistent input files
setenv PROMPTFLAG           F       ##   turn on I/O-API PROMPT*FILE interactive mode [ options: T | F ]
setenv IOAPI_OFFSET_64      YES     ##   support large timestep records (>2GB/timestep record) [ options: YES | NO ]
setenv IOAPI_CHECK_HEADERS  N       ##   check file headers [ options: Y | N ]

if ( ! $?CTM_EMISCHK        ) setenv CTM_EMISCHK        N   ##   Abort CMAQ if missing surrogates from emissions Input files
if ( ! $?EMISDIAG           ) setenv EMISDIAG           F   ##   Print Emission Rates at the output time step after they have been
                                                            ##     scaled and modified by the user Rules [options: F | T or 2D | 3D | 2DSUM ]
                                                            ##     Individual streams can be modified using the variables:
                                                            ##         GR_EMIS_DIAG_                                ## | STK_EMIS_DIAG_                                ## | BIOG_EMIS_DIAG
                                                            ##         MG_EMIS_DIAG    | LTNG_EMIS_DIAG   | DUST_EMIS_DIAG
                                                            ##         SEASPRAY_EMIS_DIAG
                                                            ##     Note that these diagnostics are different than other emissions diagnostic
                                                            ##     output because they occur after scaling.
if ( ! $?EMISDIAG_SUM       ) setenv EMISDIAG_SUM       F   ##   Print Sum of Emission Rates to Gridded Diagnostic File

if ( ! $?EMIS_SYM_DATE      ) setenv EMIS_SYM_DATE      N   ##   Master switch for allowing CMAQ to use the date from each Emission file
                                                            ##     rather than checking the emissions date against the internal model date.
                                                            ##     [options: T | F or Y | N]. If false (F/N), then the date from CMAQ's internal
                                                            ##     time will be used and an error check will be performed (recommended). Users
                                                            ##     may switch the behavior for individual emission files below using the variables:
                                                            ##         GR_EM_SYM_DATE_                                ## | STK_EM_SYM_DATE_                                ## [ default : N ]
#>      Diagnostic Output Flags
if ( ! $?CTM_CKSUM          ) setenv CTM_CKSUM          Y      ##   checksum report [ default: Y ]
if ( ! $?CLD_DIAG           ) setenv CLD_DIAG           N      ##   cloud diagnostic file [ default: N ]

if ( ! $?CTM_PHOTDIAG       ) setenv CTM_PHOTDIAG       N      ##   photolysis diagnostic file [ default: N ]
if ( ! $?NLAYS_PHOTDIAG     ) setenv NLAYS_PHOTDIAG    "1"     ##   Number of layers for PHOTDIAG2 and PHOTDIAG3 from
                                                               ##       Layer 1 to NLAYS_PHOTDIAG  [ default: all layers ]
#if ( ! $?NWAVE_PHOTDIAG    ) setenv NWAVE_PHOTDIAG    "294 303 310 316 333 381 607" ##   Wavelengths written for variables
                                                               ##     in PHOTDIAG2 and PHOTDIAG3
                                                               ##     [ default: all wavelengths ]

if ( ! $?CTM_PMDIAG         ) setenv CTM_PMDIAG         N      ##   Instantaneous Aerosol Diagnostic File [ default: Y ]
if ( ! $?CTM_APMDIAG        ) setenv CTM_APMDIAG        Y      ##   Hourly-Average Aerosol Diagnostic File [ default: Y ]
if ( ! $?APMDIAG_BLEV_ELEV  ) setenv APMDIAG_BLEV_ELEV "1 1"   ##   layer range for average pmdiag = NLAYS

if ( ! $?CTM_SSEMDIAG       ) setenv CTM_SSEMDIAG       N      ##   sea-spray emissions diagnostic file [ default: N ]
if ( ! $?CTM_DUSTEM_DIAG    ) setenv CTM_DUSTEM_DIAG    N      ##   windblown dust emissions diagnostic file [ default: N ];
                                                               ##       Ignore if CTM_WB_DUST = N
if ( ! $?CTM_DEPV_FILE      ) setenv CTM_DEPV_FILE      N      ##   deposition velocities diagnostic file [ default: N ]
if ( ! $?VDIFF_DIAG_FILE    ) setenv VDIFF_DIAG_FILE    N      ##   vdiff & possibly aero grav. sedimentation diagnostic file [ default: N ]
if ( ! $?LTNGDIAG           ) setenv LTNGDIAG           N      ##   lightning diagnostic file [ default: N ]
if ( ! $?B3GTS_DIAG         ) setenv B3GTS_DIAG         N      ##   BEIS mass emissions diagnostic file [ default: N ]
if ( ! $?CTM_WVEL           ) setenv CTM_WVEL           Y      ##   save derived vertical velocity component to conc file [ default: Y ]

# =====================================================================
#>      Input Directories and Filenames
# =====================================================================

 set ICpath    = $DATADIR/icbc                       ##   initial conditions input directory
 set BCpath    = $DATADIR/icbc                       ##   boundary conditions input directory
 set EMISpath  = $DATADIR/emissions                  ##   gridded emissions input directory
 set EMISpath2 = $DATADIR/emissions      ##   gridded surface residential wood combustion emissions directory
 set IN_PTpath = $DATADIR/emissions            ##   point source emissions input directory
 set IN_LTpath = $DATADIR/MCIP                   ##   lightning NOx input directory
 set METpath   = $DATADIR/MCIP                   ##   meteorology input directory
 set OMIpath   = $BLD                                ##   ozone column data for the photolysis model
 set LUpath    = $DATADIR/land                       ##   BELD landuse data for windblown dust model
 set SZpath    = $DATADIR/land                       ##   surf zone file for in-line seaspray emissions
#set JVALpath  = $DATADIR/jproc                      ##   offline photolysis rate table directory

# =====================================================================
#>      Begin Loop Through Simulation Days
# =====================================================================
set rtarray = ""

set TODAYG = ${START_DATE}
set TODAYJ = `date -ud "${START_DATE}" +%Y%j`##   Convert YYYY-MM-DD to YYYYJJJ
set START_DAY = ${TODAYJ}
set STOP_DAY = `date -ud "${END_DATE}" +%Y%j`##   Convert YYYY-MM-DD to YYYYJJJ
set NDAYS = 0

#>      Print attributes of the run
if ( $CTM_DIAG_LVL != 0 ) then
    echo ${bar}
    echo "Environment:"
    env | sort
    echo ${bar}
    echo "GRIDDESC:"
    ls -l ${GRIDDESC}
    echo "ICpath=${ICpath}:"
    ls -lR ${ICpath}
    echo "BCpath=${BCpath}:"
    ls -lR ${BCpath}
    echo "EMISpath=${EMISpath}:"
    ls -lR ${EMISpath}
    echo "EMISpath2=${EMISpath2}"
    ls -lR ${EMISpath2}
    echo "IN_PTpath=${IN_PTpath}:"
    ls -lR ${IN_PTpath}
    echo "IN_LTpath=${IN_LTpath}:"
    ls -lR ${IN_LTpath}
    echo "METpath=${METpath}:"
    ls -lR ${METpath}
    echo "NMLDIR=OMIpath=${NMLDIR}"
    ls -lR ${NMLDIR}/*.dat ${NMLDIR}/*.nml ${NMLDIR}/*.ctl ${NMLDIR}/CSQ*
    echo "LUpath=${LUpath}:"
    ls -lR ${LUpath}
    echo "SZpath=${SZpath}:"
    ls -lR ${SZpath}
    echo "OUTDIR=${OUTDIR}:"
    ls -lR ${OUTDIR}
    echo ${bar}
    ls -l $EXEC
    size  $EXEC
    unlimit
    limit
    which mpirun
    echo ${bar}
    echo " "
endif

while ($TODAYJ <= $STOP_DAY )  #>Compare dates in terms of YYYYJJJ

    @ NDAYS = ${NDAYS} + 1

    #>      Retrieve Calendar day Information
    set YYYYMMDD = `/usr/local/bin/jul2greg ${TODAYJ}`             #>      Convert YYYY-MM-DD to YYYYMMDD
    set YYMMDD   = `echo $YYYYMMDD | cut -c 3-8`    #>      Convert YYYYMMDD to YYMMDD
    set YYYYJJJ  = $TODAYJ

    #>      Calculate Yesterday's Date
    set YESTERDAY = `/usr/local/bin/julshift $YYYYJJJ -1`
    set YESTERDAYG = `/usr/local/bin/jul2greg ${YESTERDAY}`

    if ( $CTM_DIAG_LVL != 0 ) then
        echo ${bar}
        echo "Processing  ${TODAYJ}:  YYMMDD=${YYMMDD}  YYYYJJJ=${YYYYJJJ}"
    endif
    # =====================================================================
    #>      Set Output String and Propagate Model Configuration Documentation
    # =====================================================================
    echo ""
    echo "Set up input and output files for Day ${YYYYMMDD}."

    #>      set output file name extensions
    setenv CTM_APPL ${RUNID}_${YYYYMMDD}

    #>      Copy Model Configuration To Output Folder
    if ( ! -d "$OUTDIR" ) mkdir -p $OUTDIR
    cp $BLD/CCTM_${VRSN}.cfg $OUTDIR/CCTM_${CTM_APPL}.cfg

    # =====================================================================
    #>      Input Files (Some are Day-Dependent)
    # =====================================================================

    #>      Initial conditions
    if ($NEW_START == true || $NEW_START == TRUE ) then
       setenv ICFILE ICON_v53_2016fh_regrid_20151222
       setenv INIT_MEDC_1 notused
       setenv INITIAL_RUN Y #related to restart soil information file
    else
       set ICpath = $OUTDIR
       setenv ICFILE CCTM_CGRID_${RUNID}_${YESTERDAYG}.nc
       setenv INIT_MEDC_1 $ICpath/CCTM_MEDIA_CONC_${RUNID}_${YESTERDAYG}.nc
       setenv INITIAL_RUN N
    endif
    #>      Boundary conditions
    #set BCFILE = BCON_${YYYYMMDD}_bench.nc
     set BCFILE = BCON_v53_2016fh_regrid_${YYYYMMDD}

    #>      Off-line photolysis rates
    #set JVALfile  = JTABLE_${YYYYJJJ}

    #>      Ozone column data
    set OMIfile   = OMI_1979_to_2019.dat

    #>      Optics file
    set OPTfile = PHOT_OPTICS.dat

    #>      MCIP meteorology files
    setenv GRID_BDY_2D $METpath/GRIDBDY2D.$GRID_NAME.${NZ}L.$YYMMDD
    setenv GRID_CRO_2D $METpath/GRIDCRO2D.$GRID_NAME.${NZ}L.$YYMMDD
    setenv GRID_CRO_3D $METpath/GRIDCRO3D.$GRID_NAME.${NZ}L.$YYMMDD
    setenv GRID_DOT_2D $METpath/GRIDDOT2D.$GRID_NAME.${NZ}L.$YYMMDD
    setenv MET_CRO_2D  $METpath/METCRO2D.$GRID_NAME.${NZ}L.$YYMMDD
    setenv MET_CRO_3D  $METpath/METCRO3D.$GRID_NAME.${NZ}L.$YYMMDD
    setenv MET_DOT_3D  $METpath/METDOT3D.$GRID_NAME.${NZ}L.$YYMMDD
    setenv MET_BDY_3D  $METpath/METBDY3D.$GRID_NAME.${NZ}L.$YYMMDD
# setenv LUFRAC_CRO  $METpath/LUFRAC_CRO.$GRID_NAME.${NZ}L.$YYMMDD


    #>      Emissions Control File
    #>
    #>      IMPORTANT NOTE
    #>
    #>      The emissions control file defined below is an integral part of controlling the behavior of the model simulation.
    #>      Among other things, it controls the mapping of species in the emission files to chemical species in the model and
    #>      several aspects related to the simulation of organic aerosols.
    #>      Please carefully review the emissions control file to ensure that it is configured to be consistent with the assumptions
    #>      made when creating the emission files defined below and the desired representation of organic aerosols.
    #>      For further information, please see:
    #>      + AERO7 Release Notes section on 'Required emission updates':
    #>        https://github.com/USEPA/CMAQ/blob/master/DOCS/Release_Notes/aero7_overview.md
    #>      + CMAQ User's Guide section 6.9.3 on 'Emission Compatability':
    #>        https://github.com/USEPA/CMAQ/blob/master/DOCS/Users_Guide/CMAQ_UG_ch06_model_configuration_options.md#6.9.3_Emission_Compatability
    #>      + Emission Control (DESID) Documentation in the CMAQ User's Guide:
    #>        https://github.com/USEPA/CMAQ/blob/master/DOCS/Users_Guide/Appendix/CMAQ_UG_appendixB_emissions_control.md
    #>
    setenv EMISSCTRL_NML ${BLD}/EmissCtrl_${MECH}.nml

    #>      Spatial Masks For Emissions Scaling
    #setenv CMAQ_MASKS $SZpath/12US1_surf_bench.nc #>      horizontal grid-dependent surf zone file
     setenv CMAQ_MASKS $SZpath/12US1_surf.ncf

    #> Determine Representative Emission Days
    set EMDATES = $DATADIR/emissions/smk_merge_dates_${YYYYMM}.txt
    set intable = `grep "^${YYYYMMDD}" $EMDATES`
    set Date     = `echo $intable[1] | cut -d, -f1`
    set aveday_N = `echo $intable[2] | cut -d, -f1`
    set aveday_Y = `echo $intable[3] | cut -d, -f1`
    set mwdss_N  = `echo $intable[4] | cut -d, -f1`
    set mwdss_Y  = `echo $intable[5] | cut -d, -f1`
    set week_N   = `echo $intable[6] | cut -d, -f1`
    set week_Y   = `echo $intable[7] | cut -d, -f1`
    set all      = `echo $intable[8] | cut -d, -f1`


    #>      Gridded Emissions Files
    setenv N_EMIS_GR 2
    #set EMISfile  = emis_mole_all_${YYYYMMDD}_cb6_bench.nc
    set EMISfile  = emis_mole_all_${YYYYMMDD}_12US2_nobeis_norwc_2016fh_16j.ncf
    setenv GR_EMIS_001          ${EMISpath}/${EMISfile}
    setenv GR_EMIS_LAB_001      GRIDDED_EMIS
    setenv GR_EM_SYM_DATE_001   F

    #set EMISfile  = emis_mole_rwc_${YYYYMMDD}_12US1_cmaq_cb6_2016ff_16j.nc
    set EMISfile  = emis_mole_all_${YYYYMMDD}_12US2_withbeis_withrwc_2016fh_16j.ncf
    setenv GR_EMIS_002          ${EMISpath2}/${EMISfile}
    #setenv GR_EMIS_LAB_002      GR_RES_FIRES
    setenv GR_EMIS_LAB_002 GRIDDED_RWC
    setenv GR_EM_SYM_DATE_002   F

    #>      In-line point emissions configuration
    setenv N_EMIS_PT 9          #>      Number of elevated source groups

    set STKCASEG = 12US1_2016fh_16j           # Stack Group Version Label
    set STKCASEE = 12US1_cmaq_cb6_2016fh_16j  # Stack Emission Version Label

    # Time-Independent Stack Parameters for Inline Point Sources
    setenv STK_GRPS_001 $IN_PTpath/ptnonipm/stack_groups_ptnonipm_${STKCASEG}.ncf
    setenv STK_GRPS_002 $IN_PTpath/ptegu/stack_groups_ptegu_${STKCASEG}.ncf
    setenv STK_GRPS_003 $IN_PTpath/othpt/stack_groups_othpt_${STKCASEG}.ncf
    setenv STK_GRPS_004 $IN_PTpath/ptagfire/stack_groups_ptagfire_${YYYYMMDD}_${STKCASEG}.ncf
    setenv STK_GRPS_005 $IN_PTpath/ptfire/stack_groups_ptfire_${YYYYMMDD}_${STKCASEG}.ncf
    setenv STK_GRPS_006 $IN_PTpath/ptfire_othna/stack_groups_ptfire_othna_${YYYYMMDD}_${STKCASEG}.ncf
    setenv STK_GRPS_007 $IN_PTpath/pt_oilgas/stack_groups_pt_oilgas_${STKCASEG}.ncf
    setenv STK_GRPS_008 $IN_PTpath/cmv_c3_12/stack_groups_cmv_c3_12_${STKCASEG}.ncf
    setenv STK_GRPS_009 $IN_PTpath/cmv_c1c2_12/stack_groups_cmv_c1c2_12_12US1_2016fh_16j.ncf

    setenv LAYP_STDATE $YYYYJJJ
    setenv LAYP_STTIME $STTIME
    setenv LAYP_NSTEPS $NSTEPS

    # Emission Rates for Inline Point Sources
    #setenv STK_EMIS_001 $IN_PTpath/ptnonipm/inln_mole_ptnonipm_${YYYYMMDD}_${STKCASEE}.ncf
    #setenv STK_EMIS_002 $IN_PTpath/ptegu/inln_mole_ptegu_${YYYYMMDD}_${STKCASEE}.ncf
    #setenv STK_EMIS_003 $IN_PTpath/othpt/inln_mole_othpt_${YYYYMMDD}_${STKCASEE}.ncf
    #setenv STK_EMIS_004 $IN_PTpath/ptagfire/inln_mole_ptagfire_${YYYYMMDD}_${STKCASEE}.ncf
    #setenv STK_EMIS_005 $IN_PTpath/ptfire/inln_mole_ptfire_${YYYYMMDD}_${STKCASEE}.ncf
    #setenv STK_EMIS_006 $IN_PTpath/ptfire_othna/inln_mole_ptfire_othna_${YYYYMMDD}_${STKCASEE}.ncf
    #setenv STK_EMIS_007 $IN_PTpath/pt_oilgas/inln_mole_pt_oilgas_${YYYYMMDD}_${STKCASEE}.ncf
    #setenv STK_EMIS_008 $IN_PTpath/cmv_c3/inln_mole_cmv_c3_${YYYYMMDD}_${STKCASEE}.ncf
    setenv STK_EMIS_001 $IN_PTpath/ptnonipm/inln_mole_ptnonipm_${mwdss_Y}_${STKCASEE}.ncf
  setenv STK_EMIS_002 $IN_PTpath/ptegu/inln_mole_ptegu_${YYYYMMDD}_${STKCASEE}.ncf
  setenv STK_EMIS_003 $IN_PTpath/othpt/inln_mole_othpt_${mwdss_N}_${STKCASEE}.ncf
  setenv STK_EMIS_004 $IN_PTpath/ptagfire/inln_mole_ptagfire_${YYYYMMDD}_${STKCASEE}.ncf
  setenv STK_EMIS_005 $IN_PTpath/ptfire/inln_mole_ptfire_${YYYYMMDD}_${STKCASEE}.ncf
  setenv STK_EMIS_006 $IN_PTpath/ptfire_othna/inln_mole_ptfire_othna_${YYYYMMDD}_${STKCASEE}.ncf
  setenv STK_EMIS_007 $IN_PTpath/pt_oilgas/inln_mole_pt_oilgas_${mwdss_Y}_${STKCASEE}.ncf
  setenv STK_EMIS_008 $IN_PTpath/cmv_c3_12/inln_mole_cmv_c3_12_${YYYYMMDD}_${STKCASEE}.ncf
  setenv STK_EMIS_009 $IN_PTpath/cmv_c1c2_12/inln_mole_cmv_c1c2_12_${YYYYMMDD}_${STKCASEE}.ncf

    # Label Each Emissions Stream
    setenv STK_EMIS_LAB_001 PT_NONEGU
    setenv STK_EMIS_LAB_002 PT_EGU
    setenv STK_EMIS_LAB_003 PT_OTHER
    setenv STK_EMIS_LAB_004 PT_AGFIRES
    setenv STK_EMIS_LAB_005 PT_FIRES
    setenv STK_EMIS_LAB_006 PT_OTHFIRES
    setenv STK_EMIS_LAB_007 PT_OILGAS
    setenv STK_EMIS_LAB_008 PT_CMV_c3
    setenv STK_EMIS_LAB_009 PT_CMV_C1_C2

    # Stack emissions diagnostic files
    #setenv STK_EMIS_DIAG_001 2DSUM
    #setenv STK_EMIS_DIAG_002 2DSUM
    #setenv STK_EMIS_DIAG_003 2DSUM
    #setenv STK_EMIS_DIAG_004 2DSUM
    #setenv STK_EMIS_DIAG_005 2DSUM

    # Allow CMAQ to Use Point Source files with dates that do not
    # match the internal model date
    setenv STK_EM_SYM_DATE_001 T
    setenv STK_EM_SYM_DATE_002 T
    setenv STK_EM_SYM_DATE_003 T
    setenv STK_EM_SYM_DATE_004 T
    setenv STK_EM_SYM_DATE_005 T
    setenv STK_EM_SYM_DATE_006 T
    setenv STK_EM_SYM_DATE_007 T
    setenv STK_EM_SYM_DATE_008 T
    setenv STK_EM_SYM_DATE_009 T

    #>      Lightning NOx configuration
    if ( $CTM_LTNG_NO == 'Y' ) then
       setenv LTNGNO "InLine"    #>      set LTNGNO to "Inline" to activate in-line calculation

    #>      In-line lightning NOx options
       setenv USE_NLDN  Y        #>      use hourly NLDN strike file [ default: Y ]
       if ( $USE_NLDN == Y ) then
          setenv NLDN_STRIKES ${IN_LTpath}/NLDN.12US1.${YYYYMMDD}_bench.nc
       endif
       setenv LTNGPARMS_FILE ${IN_LTpath}/LTNG_AllParms_12US1_bench.nc #>      lightning parameter file
    endif

    #>      In-line biogenic emissions configuration
    if ( $CTM_BIOGEMIS == 'Y' ) then
       set IN_BEISpath = ${DATADIR}/land
       setenv GSPRO      $BLD/gspro_biogenics.txt
       setenv B3GRD      $IN_BEISpath/b3grd_bench.nc
       setenv BIOSW_YN   Y     #>      use frost date switch [ default: Y ]
       setenv BIOSEASON  $IN_BEISpath/bioseason.cmaq.2016_12US1_full_bench.ncf
                               #>      ignore season switch file if BIOSW_YN = N
       setenv SUMMER_YN  Y     #>      Use summer normalized emissions? [ default: Y ]
       setenv PX_VERSION Y     #>      MCIP is PX version? [ default: N ]
       setenv SOILINP    $OUTDIR/CCTM_SOILOUT_${RUNID}_${YESTERDAYG}.nc
                               #>      Biogenic NO soil input file; ignore if INITIAL_RUN = Y
    endif

    #>      Windblown dust emissions configuration
    if ( $CTM_WB_DUST == 'Y' ) then
       # Input variables for BELD3 Landuse option
       setenv DUST_LU_1 $LUpath/beld3_12US1_459X299_output_a_bench.nc
       setenv DUST_LU_2 $LUpath/beld4_12US1_459X299_output_tot_bench.nc
    endif

    #>      In-line sea spray emissions configuration
    setenv OCEAN_1 $SZpath/12US1_surf.ncf #>      horizontal grid-dependent surf zone file

    #>      Bidirectional ammonia configuration
    if ( $CTM_ABFLUX == 'Y' ) then
       setenv E2C_SOIL ${LUpath}/epic_festc1.4_20180516/2016_US1_soil_bench.nc
       setenv E2C_CHEM ${LUpath}/epic_festc1.4_20180516/2016_US1_time${YYYYMMDD}_bench.nc
       setenv E2C_CHEM_YEST ${LUpath}/epic_festc1.4_20180516/2016_US1_time${YESTERDAY}_bench.nc
       setenv E2C_LU ${LUpath}/beld4_12kmCONUS_2011nlcd_bench.nc
    endif

    #>      Inline Process Analysis
    setenv CTM_PROCAN N        #>      use process analysis [ default: N]
    if ( $?CTM_PROCAN ) then   # $CTM_PROCAN is defined
       if ( $CTM_PROCAN == 'Y' || $CTM_PROCAN == 'T' ) then
       #>      process analysis global column, row and layer ranges
       #       setenv PA_BCOL_ECOL "10 90"  # default: all columns
       #       setenv PA_BROW_EROW "10 80"  # default: all rows
       #       setenv PA_BLEV_ELEV "1  4"   # default: all levels
          setenv PACM_INFILE ${NMLDIR}/pa_${MECH}.ctl
          setenv PACM_REPORT $OUTDIR/"PA_REPORT".${YYYYMMDD}
       endif
    endif

    #>      Integrated Source Apportionment Method (ISAM) Options
    setenv CTM_ISAM N
    if ( $?CTM_ISAM ) then
        if ( $CTM_ISAM == 'Y' || $CTM_ISAM == 'T' ) then
                setenv SA_IOLIST ${WORKDIR}/isam_control.txt
                setenv ISAM_BLEV_ELEV " 1 1"
                setenv AISAM_BLEV_ELEV " 1 1"

                #>      Set Up ISAM Initial Condition Flags
                if ($NEW_START == true || $NEW_START == TRUE ) then
                   setenv ISAM_NEW_START Y
                   setenv ISAM_PREVDAY
                else
                   setenv ISAM_NEW_START N
                   setenv ISAM_PREVDAY "$OUTDIR/CCTM_SA_CGRID_${RUNID}_${YESTERDAYG}.nc"
                endif

                #>      Set Up ISAM Output Filenames
                setenv SA_ACONC_1      "$OUTDIR/CCTM_SA_ACONC_${CTM_APPL}.nc -v"
                setenv SA_CONC_1       "$OUTDIR/CCTM_SA_CONC_${CTM_APPL}.nc -v"
                setenv SA_DD_1         "$OUTDIR/CCTM_SA_DRYDEP_${CTM_APPL}.nc -v"
                setenv SA_WD_1         "$OUTDIR/CCTM_SA_WETDEP_${CTM_APPL}.nc -v"
                setenv SA_CGRID_1      "$OUTDIR/CCTM_SA_CGRID_${CTM_APPL}.nc -v"

                #>      Set optional ISAM regions files
            #      setenv ISAM_REGIONS /work/MOD3EVAL/nsu/isam_v53/CCTM/scripts/input/RGN_ISAM.nc

        endif
    endif


    #>      Sulfur Tracking Model (STM)
    setenv STM_SO4TRACK N        #>      sulfur tracking [ default: N ]
    if ( $?STM_SO4TRACK ) then
        if ( $STM_SO4TRACK == 'Y' || $STM_SO4TRACK == 'T' ) then

            #>      option to normalize sulfate tracers [ default: Y ]
            setenv STM_ADJSO4 Y

        endif
    endif

    # =====================================================================
    #>      Output Files
    # =====================================================================

    #>      set output file names
    setenv S_CGRID         "$OUTDIR/CCTM_CGRID_${CTM_APPL}.nc"         #>      3D Inst. Concentrations
    setenv CTM_CONC_1      "$OUTDIR/CCTM_CONC_${CTM_APPL}.nc -v"       #>      On-Hour Concentrations
    setenv A_CONC_1        "$OUTDIR/CCTM_ACONC_${CTM_APPL}.nc -v"      #>      Hourly Avg. Concentrations
    setenv MEDIA_CONC      "$OUTDIR/CCTM_MEDIA_CONC_${CTM_APPL}.nc -v" #>      NH3 Conc. in Media
    setenv CTM_DRY_DEP_1   "$OUTDIR/CCTM_DRYDEP_${CTM_APPL}.nc -v"     #>      Hourly Dry Deposition
    setenv CTM_DEPV_DIAG   "$OUTDIR/CCTM_DEPV_${CTM_APPL}.nc -v"       #>      Dry Deposition Velocities
    setenv B3GTS_S         "$OUTDIR/CCTM_B3GTS_S_${CTM_APPL}.nc -v"    #>      Biogenic Emissions
    setenv SOILOUT         "$OUTDIR/CCTM_SOILOUT_${CTM_APPL}.nc"       #>      Soil Emissions
    setenv CTM_WET_DEP_1   "$OUTDIR/CCTM_WETDEP1_${CTM_APPL}.nc -v"    #>      Wet Dep From All Clouds
    setenv CTM_WET_DEP_2   "$OUTDIR/CCTM_WETDEP2_${CTM_APPL}.nc -v"    #>      Wet Dep From SubGrid Clouds
    setenv CTM_PMDIAG_1    "$OUTDIR/CCTM_PMDIAG_${CTM_APPL}.nc -v"     #>      On-Hour Particle Diagnostics
    setenv CTM_APMDIAG_1   "$OUTDIR/CCTM_APMDIAG_${CTM_APPL}.nc -v"    #>      Hourly Avg. Particle Diagnostics
    setenv CTM_RJ_1        "$OUTDIR/CCTM_PHOTDIAG1_${CTM_APPL}.nc -v"  #>      2D Surface Summary from Inline Photolysis
    setenv CTM_RJ_2        "$OUTDIR/CCTM_PHOTDIAG2_${CTM_APPL}.nc -v"  #>      3D Photolysis Rates
    setenv CTM_RJ_3        "$OUTDIR/CCTM_PHOTDIAG3_${CTM_APPL}.nc -v"  #>      3D Optical and Radiative Results from Photolysis
    setenv CTM_SSEMIS_1    "$OUTDIR/CCTM_SSEMIS_${CTM_APPL}.nc -v"     #>      Sea Spray Emissions
    setenv CTM_DUST_EMIS_1 "$OUTDIR/CCTM_DUSTEMIS_${CTM_APPL}.nc -v"   #>      Dust Emissions
    setenv CTM_IPR_1       "$OUTDIR/CCTM_PA_1_${CTM_APPL}.nc -v"       #>      Process Analysis
    setenv CTM_IPR_2       "$OUTDIR/CCTM_PA_2_${CTM_APPL}.nc -v"       #>      Process Analysis
    setenv CTM_IPR_3       "$OUTDIR/CCTM_PA_3_${CTM_APPL}.nc -v"       #>      Process Analysis
    setenv CTM_IRR_1       "$OUTDIR/CCTM_IRR_1_${CTM_APPL}.nc -v"      #>      Chem Process Analysis
    setenv CTM_IRR_2       "$OUTDIR/CCTM_IRR_2_${CTM_APPL}.nc -v"      #>      Chem Process Analysis
    setenv CTM_IRR_3       "$OUTDIR/CCTM_IRR_3_${CTM_APPL}.nc -v"      #>      Chem Process Analysis
    setenv CTM_DRY_DEP_MOS "$OUTDIR/CCTM_DDMOS_${CTM_APPL}.nc -v"      #>      Dry Dep
    setenv CTM_DRY_DEP_FST "$OUTDIR/CCTM_DDFST_${CTM_APPL}.nc -v"      #>      Dry Dep
    setenv CTM_DEPV_MOS    "$OUTDIR/CCTM_DEPVMOS_${CTM_APPL}.nc -v"    #>      Dry Dep Velocity
    setenv CTM_DEPV_FST    "$OUTDIR/CCTM_DEPVFST_${CTM_APPL}.nc -v"    #>      Dry Dep Velocity
    setenv CTM_VDIFF_DIAG  "$OUTDIR/CCTM_VDIFF_DIAG_${CTM_APPL}.nc -v" #>      Vertical Dispersion Diagnostic
    setenv CTM_VSED_DIAG   "$OUTDIR/CCTM_VSED_DIAG_${CTM_APPL}.nc -v"  #>      Particle Grav. Settling Velocity
    setenv CTM_LTNGDIAG_1  "$OUTDIR/CCTM_LTNGHRLY_${CTM_APPL}.nc -v"   #>      Hourly Avg Lightning NO
    setenv CTM_LTNGDIAG_2  "$OUTDIR/CCTM_LTNGCOL_${CTM_APPL}.nc -v"    #>      Column Total Lightning NO
    setenv CTM_VEXT_1      "$OUTDIR/CCTM_VEXT_${CTM_APPL}.nc -v"       #>      On-Hour 3D Concs at select sites

    #>      set floor file (neg concs)
    setenv FLOOR_FILE ${OUTDIR}/FLOOR_${CTM_APPL}.txt

    #>      look for existing log files and output files
    ( ls CTM_LOG_???.${CTM_APPL} > buff.txt ) >& /dev/null
    ( ls ${LOGDIR}/CTM_LOG_???.${CTM_APPL} >> buff.txt ) >& /dev/null
    set log_test = `cat buff.txt`; rm -f buff.txt
    set OUT_FILES = (${FLOOR_FILE} ${S_CGRID} ${CTM_CONC_1} ${A_CONC_1} ${MEDIA_CONC}       \
               ${CTM_DRY_DEP_1} $CTM_DEPV_DIAG $B3GTS_S $SOILOUT $CTM_WET_DEP_1             \
               $CTM_WET_DEP_2 $CTM_PMDIAG_1 $CTM_APMDIAG_1                                  \
               $CTM_RJ_1 $CTM_RJ_2 $CTM_RJ_3 $CTM_SSEMIS_1 $CTM_DUST_EMIS_1 $CTM_IPR_1      \
               $CTM_IPR_2 $CTM_IPR_3 $CTM_IRR_1 $CTM_IRR_2 $CTM_IRR_3 $CTM_DRY_DEP_MOS      \
               $CTM_DRY_DEP_FST $CTM_DEPV_MOS $CTM_DEPV_FST $CTM_VDIFF_DIAG $CTM_VSED_DIAG  \
               $CTM_LTNGDIAG_1 $CTM_LTNGDIAG_2 $CTM_VEXT_1 )
    if ( $?CTM_ISAM ) then
       if ( $CTM_ISAM == 'Y' || $CTM_ISAM == 'T' ) then
          set OUT_FILES = (${OUT_FILES} ${SA_ACONC_1} ${SA_CONC_1} ${SA_DD_1} ${SA_WD_1}    \
                           ${SA_CGRID_1} )
       endif
    endif
    set OUT_FILES = `echo $OUT_FILES | sed "s; -v;;g" | sed "s;MPI:;;g" `
    ( ls $OUT_FILES > buff.txt ) >& /dev/null
    set out_test = `cat buff.txt`; rm -f buff.txt

    #>      delete previous output if requested
    if ( $CLOBBER_DATA == true || $CLOBBER_DATA == TRUE  ) then
       echo
       echo "Existing Logs and Output Files for Day ${TODAYG} Will Be Deleted"

       #>      remove previous log files
       foreach file ( ${log_test} )
          #echo "Deleting log file: $file"
          /bin/rm -f $file
       end

       #>      remove previous output files
       foreach file ( ${out_test} )
          #echo "Deleting output file: $file"
          /bin/rm -f $file
       end
       /bin/rm -f ${OUTDIR}/CCTM_EMDIAG*${RUNID}_${YYYYMMDD}.nc

    else
       #>      error if previous log files exist
        if ( "$log_test" != "" ) then
            echo "*** Logs exist - run ABORTED ***"
            echo "*** To overide, set CLOBBER_DATA = TRUE in run_cctm.csh ***"
                echo "*** and these files will be automatically deleted. ***"
                exit 1
        endif

        #>      error if previous output files exist

        if ( "$out_test" != "" ) then
                echo "*** Output Files Exist - run will be ABORTED ***"
                foreach file ( $out_test )
                   echo " cannot delete $file"
                end
                echo "*** To overide, set CLOBBER_DATA = TRUE in run_cctm.csh ***"
                echo "*** and these files will be automatically deleted. ***"
                exit 1
        endif
    endif

    #>      for the run control ...
    setenv CTM_STDATE      $YYYYJJJ
    setenv CTM_STTIME      $STTIME
    setenv CTM_RUNLEN      $NSTEPS
    setenv CTM_TSTEP       $TSTEP
    setenv INIT_CONC_1 $ICpath/$ICFILE
    setenv BNDY_CONC_1 $BCpath/$BCFILE
    setenv OMI $OMIpath/$OMIfile
    setenv OPTICS_DATA $OMIpath/$OPTfile
   #setenv XJ_DATA $JVALpath/$JVALfile
    set TR_DVpath = $METpath
    set TR_DVfile = $MET_CRO_2D

    #>      species defn & photolysis
    setenv gc_matrix_nml ${NMLDIR}/GC_$MECH.nml
    setenv ae_matrix_nml ${NMLDIR}/AE_$MECH.nml
    setenv nr_matrix_nml ${NMLDIR}/NR_$MECH.nml
    setenv tr_matrix_nml ${NMLDIR}/Species_Table_TR_0.nml

    #>      check for photolysis input data
    setenv CSQY_DATA ${NMLDIR}/CSQY_DATA_$MECH


    if (! (-e $CSQY_DATA ) ) then
       echo " $CSQY_DATA  not found "
       exit 1
    endif
    if (! (-e $OPTICS_DATA ) ) then
       echo " $OPTICS_DATA  not found "
       exit 1
    endif

    # ===================================================================
    #>      Execution Portion
    # ===================================================================

    #>      Print attributes of the executable

    #>      Print Startup Dialogue Information to Standard Out
    echo
    echo "CMAQ Processing of Day $YYYYMMDD Began at `date`"
    echo

    unset   err_status

    if ( $?DEBUG ) then

        unsetenv LOGFILE
        if ( $PROC == mpi ) then
            mpirun -np $NPROCS ddd ${EXEC}
        else
            ddd ${EXEC}
        endif
        set err_status = ${status}      ##  save exit-status:  normal/success is 0, abnormal/failure non-zero
        exit( ${err_status} )

    else if ( $PROC == mpi ) then

        ( /usr/bin/time -p mpirun --oversubscribe -np $NPROCS ${EXEC} ) |& tee buff_${EXECUTION_ID}.txt
        set err_status = ${status}      ##  save exit-status:  normal/success is 0, abnormal/failure non-zero

    else

        ( /usr/bin/time ${EXEC} ) |& tee buff_${EXECUTION_ID}.txt
        set err_status = ${status}      ##  save exit-status:  normal/success is 0, abnormal/failure non-zero

    endif

    #>      Abort script if abnormal termination
    if ( ${err_status} != 0 ) then
        echo ""
        echo "****************************************************************"
        echo "** Error for run starting ${CTM_STDATE}:                      **"
        echo "**    STATUS=${err_status} for program $BLD/$EXEC             **"
        echo "**    The runscript will now ABORT rather than                **"
        echo "**    proceed to subsequent days.                             **"
        echo "****************************************************************"
        exit( ${err_status} )
    else if ( ! -e $OUTDIR/CCTM_CGRID_${CTM_APPL}.nc ) then
        set err_status = 2
        echo ""
        echo "****************************************************************"
        echo "** Error for run starting ${CTM_STDATE}                       **"
        echo "**   CGRID file was not written.                              **"
        echo "**   This indicates that CMAQ was interrupted or an issue     **"
        echo "**   exists with writing output. The runscript will now       **"
        echo "**   abort rather than proceeding to subsequent days.         **"
        echo "****************************************************************"
        exit( ${err_status} )
    endif

    #>      Harvest Timing Output so that it may be reported below
    set rtarray = "${rtarray} `tail -3 buff_${EXECUTION_ID}.txt | grep -Eo '[+-]?[0-9]+([.][0-9]+)?' | head -1` "
    rm -rf buff_${EXECUTION_ID}.txt

    #>      Print Concluding Text
    echo
    echo "CMAQ Processing of Day $YYYYMMDD Finished at `date`"
    echo
    echo "\\\\\=====\\\\\=====\\\\\=====\\\\\=====/////=====/////=====/////=====/////"
    echo

    # ===================================================================
    #>      Finalize Run for This Day and Loop to Next Day
    # ===================================================================

    #>      Save Log Files and Move on to Next Simulation Day
    mv CTM_LOG_???.${CTM_APPL} $LOGDIR
    if ( $CTM_DIAG_LVL != 0 ) then
        mv CTM_DIAG_???.${CTM_APPL} $LOGDIR
    endif

    #>      The next simulation day will, by definition, be a restart
    setenv NEW_START false

    #>      Increment both Gregorian and Julian Days
    set TODAYG = `date -ud "${TODAYG}+1days" +%Y-%m-%d` #>      Add a day for tomorrow
    set TODAYJ = `/usr/local/bin/julshift $TODAYJ ${RUN_DAYS}`

end         #  Loop to the next Simulation Day


# ===================================================================
#>      Generate Timing Report
# ===================================================================
#>      Retrieve the number of columns, rows, and layers in this simulation
#>      from $MET_CRO_3D header:
set NZ      = `ncdump -h $MET_CRO_3D | grep NLAYS | cut -d= -f2 | sed -e "s/ ;//"`
set NX      = `ncdump -h $MET_CRO_3D | grep NCOLS | cut -d= -f2 | sed -e "s/ ;//"`
set NY      = `ncdump -h $MET_CRO_3D | grep NROWS | cut -d= -f2 | sed -e "s/ ;//"`
@   NCELLS  = ${NX} * ${NY} * ${NZ}

set RTMTOT = 0
foreach it ( `seq ${NDAYS}` )
    set rt = `echo ${rtarray} | cut -d' ' -f${it}`
    set RTMTOT = `echo "${RTMTOT} + ${rt}" | bc -l`
end

set RTMAVG = `echo "scale=2; ${RTMTOT} / ${NDAYS}" | bc -l`
set RTMTOT = `echo "scale=2; ${RTMTOT} / 1" | bc -l`


echo
echo "=================================="
echo "  ***** CMAQ TIMING REPORT *****"
echo "=================================="
echo "Start Day: ${START_DATE}"
echo "End Day:   ${END_DATE}"
echo "Number of Simulation Days: ${NDAYS}"
echo "Domain Name:               ${GRID_NAME}"
echo "Number of Grid Cells:      ${NCELLS}  (ROW x COL x LAY)"
echo "Number of Layers:          ${NZ}"
echo "Number of Processes:       ${NPROCS}"
echo "   All times are in seconds."
echo
echo "Num  Day        Wall Time"

set d = 0
set day = ${START_DATE}
foreach it ( `seq ${NDAYS}` )
    # Set the right day and format it
    set d = `echo "${d} + 1"  | bc -l`
    set n = `printf "%02d" ${d}`

    # Choose the correct time variables
    set rt = `echo ${rtarray} | cut -d' ' -f${it}`

    # Write out row of timing data
    echo "${n}   ${day}   ${rt}"

    # Increment day for next loop
    set day = `date -ud "${day}+1days" +%Y-%m-%d`
end

echo "     Total Time = ${RTMTOT}"
echo "      Avg. Time = ${RTMAVG}"

exit( 0 )
