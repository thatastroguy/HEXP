#!/bin/bash

# SIXTE NuSTAR Simulations for Dual AGNs and Mergers
# Author: R. W. Pfeifle
# Creation Date: 25 April 2023 (branched from sixte_duals_simulations.sh)
# Last Revision: 25 April 2023

ARG1="$1" # Choice of separation
ARG2="$2" # RA
ARG3="$3" # Dec
ARG4="$4" # Choice of exposure time
ARG5="$5" # NH value naming convention for the AGN pairing

. /Users/ryan/heasoft-6.30.1/x86_64-apple-darwin21.5.0/headas-init.sh     # Initialize heainit
export SIMPUT=/Users/ryan/simput/
export SIXTE=/Users/ryan/simput
. ${SIXTE}/bin/sixte-install.sh

export HEADASNOQUERY=
export HEADASPROMPT=/dev/null

#After generating the simput files, we now need to merge the simput files together before simulating the observation

#xmldir=${SIXTE}share/instruments
#xml=${xmldir}/hex-p/het/hexp_het_ff.xml

# Here we're generating the FPMA (1 of 2) event file using our simput file from SOXS...
$SIXTE/bin/runsixt XMLFile=${SIXTE}/share/instruments/nustar/nustar.xml Prefix=sixtesim_ RA=${ARG2} Dec=${ARG3} Simput=dualagn_${ARG1}as_simput${ARG5}.fits EvtFile=${ARG1}as_evt${ARG4%???}ks_FPMA${ARG5}.fits Exposure=${ARG4}
# Here we're generating the FPMB (2 of 2) event file using our simput file from SOXS...
$SIXTE/bin/runsixt XMLFile=${SIXTE}/share/instruments/nustar/nustar.xml Prefix=sixtesim_ RA=${ARG2} Dec=${ARG3} Simput=dualagn_${ARG1}as_simput${ARG5}.fits EvtFile=${ARG1}as_evt${ARG4%???}ks_FPMB${ARG5}.fits Exposure=${ARG4}

# Here we're using the radec2xy tool to add X,Y sky coordinates and a WCS to the event files...
$SIXTE/bin/radec2xy EvtFile=sixtesim_${ARG1}as_evt${ARG4%???}ks_FPMA${ARG5}.fits projection=TAN RefRA=${ARG2} RefDec=${ARG3}
$SIXTE/bin/radec2xy EvtFile=sixtesim_${ARG1}as_evt${ARG4%???}ks_FPMB${ARG5}.fits projection=TAN RefRA=${ARG2} RefDec=${ARG3}

# Here we're generating image files for each HET (just in case we want to compare them to the combined image) and the LET
$SIXTE/bin/imgev EvtFile=sixtesim_${ARG1}as_evt${ARG4%???}ks_FPMA${ARG5}.fits Image=IMAGE_${ARG1}as_img${ARG4%???}ks_FPMA${ARG5}.fits CoordinateSystem=0 Projection=TAN NAXIS1=325 NAXIS2=325 CUNIT1=deg CUNIT2=deg CRVAL1=${ARG2} CRVAL2=${ARG3} CRPIX1=190.5 CRPIX2=135.5 CDELT1=-6.7805656e-4 CDELT2=6.7805656e-4 history=true clobber=yes
$SIXTE/bin/imgev EvtFile=sixtesim_${ARG1}as_evt${ARG4%???}ks_FPMB${ARG5}.fits Image=IMAGE_${ARG1}as_img${ARG4%???}ks_FPMB${ARG5}.fits CoordinateSystem=0 Projection=TAN NAXIS1=325 NAXIS2=325 CUNIT1=deg CUNIT2=deg CRVAL1=${ARG2} CRVAL2=${ARG3} CRPIX1=190.5 CRPIX2=135.5 CDELT1=-6.7805656e-4 CDELT2=6.7805656e-4 history=true clobber=yes

# Here we are generating a combined HET image, saved as 2HETeff
ftmerge \
sixtesim_${ARG1}as_evt${ARG4%???}ks_FPMA${ARG5}.fits,sixtesim_${ARG1}as_evt${ARG4%???}ks_FPMB${ARG5}.fits \
sixtesim_${ARG1}as_evt${ARG4%???}ks_2FPMeff${ARG5}.fits clobber=yes

# Here we're generating the image files from the effective 2 camera FPM image
$SIXTE/bin/imgev EvtFile=sixtesim_${ARG1}as_evt${ARG4%???}ks_2FPMeff${ARG5}.fits Image=IMAGE_${ARG1}as_img${ARG4%???}ks_2FPMeff${ARG5}.fits CoordinateSystem=0 Projection=TAN NAXIS1=325 NAXIS2=325 CUNIT1=deg CUNIT2=deg CRVAL1=${ARG2} CRVAL2=${ARG3} CRPIX1=190.5 CRPIX2=135.5 CDELT1=-6.7805656e-4 CDELT2=6.7805656e-4 history=true clobber=yes
# Note: 
#   CRVAL1: RA coordinate for observation
#   CRVAL2: Dec coordinate for observation
# The above values MUST match the original RA and Dec values of the simulated event file!!
# Calculate CDELT by taking xdelt and ydelt in the xml file (in units of m) and dividing by 20m (the focal length) and multiplying by 180/PI

# Now we'll extract spectra for the two positions of the AGNs. In these simulations, we always assume there are two AGNs, \
# and we will always extract two spectra, even in the case of convolved sources (for simplicity of the code).

# Extraction for AGN 1. Extracting from FPMA and FPMB
$SIXTE/bin/makespec \
EvtFile=sixtesim_${ARG1}as_evt${ARG4%???}ks_FPMA.fits \
Spectrum=SPEC_AGN1_${ARG1}as_${ARG4%???}ks_FPMA.pha \
EventFilter="regfilter(\"cir1_${ARG1}.reg\")" \
RSPPath=${SIXTE}/share/instruments/nustar/ clobber=yes #,RA,DEC

$SIXTE/bin/makespec \
EvtFile=sixtesim_${ARG1}as_evt${ARG4%???}ks_FPMB.fits \
Spectrum=SPEC_AGN1_${ARG1}as_${ARG4%???}ks_FPMB.pha \
EventFilter="regfilter(\"cir1_${ARG1}.reg\")" \
RSPPath=${SIXTE}/share/instruments/nustar/ clobber=yes

# Extraction for AGN 2. Extracting from FPMA and FPMB
$SIXTE/bin/makespec \
EvtFile=sixtesim_${ARG1}as_evt${ARG4%???}ks_FPMA.fits \
Spectrum=SPEC_AGN2_${ARG1}as_${ARG4%???}ks_FPMA.pha \
EventFilter="regfilter(\"cir2_${ARG1}.reg\")" \
RSPPath=${SIXTE}/share/instruments/nustar/ clobber=yes

$SIXTE/bin/makespec \
EvtFile=sixtesim_${ARG1}as_evt${ARG4%???}ks_FPMB.fits \
Spectrum=SPEC_AGN2_${ARG1}as_${ARG4%???}ks_FPMB.pha \
EventFilter="regfilter(\"cir2_${ARG1}.reg\")" \
RSPPath=${SIXTE}/share/instruments/nustar/ clobber=yes
