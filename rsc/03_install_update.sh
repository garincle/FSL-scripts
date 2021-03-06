#!/bin/bash
# Installs required files.
# CAVE: for AFNI tools: may need to install or link /usr/lib[64]/libXp.so.6

# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 03/01/2013

cd $(dirname $0)
if [ $# -lt 1 ] ; then echo "Usage: update [32|64]" ; exit 1 ; fi
if [ x$FSLDIR = "x" ] ; then echo "FSLDIR variable is not defined ! Exiting." ; exit 1 ; fi
if [ x$FREESURFER_HOME = "x" ] ; then echo "FREESURFER_HOME variable is not defined ! Exiting." ; exit 1 ; fi
v5=$(cat $FSLDIR/etc/fslversion | grep ^5 | wc -l)
clear

# display dir. variables
echo ""
echo "FSLDIR:                   '$FSLDIR'"
echo "FREESURFER_HOME:          '$FREESURFER_HOME'"
# display FSL version
fslversion=$(cat $FSLDIR/etc/fslversion)
echo "FSL version:              '${fslversion}'."
# display FREESURFER version
echo "FREESURFER build-stamp:   '`cat $FREESURFER_HOME/build-stamp.txt`'."
# wait to check
echo ""
read -p "Press key to continue..."
echo ""

# copy patched fsl_sub
cp -iv fsl/fsl5/fsl_sub_patched $FSLDIR/bin/fsl_sub # contains a RAM limit and JOB-ID redirection, should also work for FSL < v.5
chmod +x $FSLDIR/bin/fsl_sub

# add templates
cp -iv fsl/templates/MNI152*.nii.gz $FSLDIR/data/standard/
cp -iv fsl/templates/avg152T1*.nii.gz $FSLDIR/data/standard/
cp -iv fsl/templates/rsn*.nii.gz $FSLDIR/data/standard/
cp -iv fsl/templates/rsn_labels* $FSLDIR/data/standard/

# for FSL 4.9.1 only
if [ $v5 -eq 0 ] ; then
  cp -iv fsl/fsl4/tbss_x/tbss_x $FSLDIR/bin/tbss_x
  chmod +x $FSLDIR/bin/tbss_x   
  cp -iv fsl/fsl4/topup/b02b0.cnf $FSLDIR/etc/flirtsch/b02b0.cnf
  cp -iv fsl/fsl4/featlib_v4.tcl $FSLDIR/tcl/featlib.tcl
  cp -iv fsl/fsl4/slices_summary $FSLDIR/bin/ # this one is needed for FSLNets
  chmod +x $FSLDIR/bin/slices_summary
fi

for bit in 32 64 ; do
  if [ $1 -eq ${bit} ] ; then
    if [ $v5 -eq 0 ] ; then # for FSL 4.9.1
      cp -iv fsl/fsl4/topup/topup_${bit} $FSLDIR/bin/topup
      chmod +x $FSLDIR/bin/topup
      cp -iv fsl/fsl4/topup/applytopup_${bit} $FSLDIR/bin/applytopup
      chmod +x $FSLDIR/bin/applytopup
      cp -iv fsl/fsl4/tbss_x/swap_voxelwise_${bit} $FSLDIR/bin/swap_voxelwise
      chmod +x $FSLDIR/bin/swap_voxelwise
      cp -iv fsl/fsl4/tbss_x/swap_subjectwise_${bit} $FSLDIR/bin/swap_subjectwise      
      chmod +x $FSLDIR/bin/swap_subjectwise
    fi  
    # AFNI tools
    cp -iv afni/3dDespike_${bit} scripts/bin/3dDespike
    chmod +x scripts/bin/3dDespike
    cp -iv afni/3dTcat_${bit} scripts/bin/3dTcat
    chmod +x scripts/bin/3dTcat
    cp -iv afni/3dTstat_${bit} scripts/bin/3dTstat
    chmod +x scripts/bin/3dTstat
    cp -iv afni/3dcalc_${bit} scripts/bin/3dcalc
    chmod +x scripts/bin/3dcalc
    cp -iv afni/3dDetrend_${bit} scripts/bin/3dDetrend
    chmod +x scripts/bin/3dDetrend
    # fslmaths5 (for filling in holes in binary masks; -fillh switch)
    cp -iv fsl/fsl5/fslmaths5_${bit} scripts/bin/fslmaths5
    chmod +x scripts/bin/fslmaths5
    # sort v.8 (supports natural version sorting; -v switch)
    cp -iv scripts/bin/sort8_${bit} scripts/bin/sort8
    chmod +x scripts/bin/sort8
  fi
done

# for Freesurfer
if [ ! -d $FREESURFER_HOME/subjects/fsaverage/tmp ] ; then
  mkdir $FREESURFER_HOME/subjects/fsaverage/tmp
  chmod 777 $FREESURFER_HOME/subjects/fsaverage/tmp # need write access so that cursor postion in tksurfer/tkmedit can be saved ! (!)
fi
if [ -f $FREESURFER_HOME/bin/fsl_sub_mgh ] ; then # for TRACULA
  if [ "$(readlink $FREESURFER_HOME/bin/fsl_sub_mgh)" != "$FSLDIR/bin/fsl_sub" ] ; then
    mv -iv $FREESURFER_HOME/bin/fsl_sub_mgh $FREESURFER_HOME/bin/fsl_sub_mgh_sav
    ln -vsi $FSLDIR/bin/fsl_sub $FREESURFER_HOME/bin/fsl_sub_mgh
  fi
fi
if [ -f $FREESURFER_HOME/bin/fsl_sub_seychelles ] ; then # for TRACULA
  if [ "$(readlink $FREESURFER_HOME/bin/fsl_sub_seychelles)" != "$FSLDIR/bin/fsl_sub" ] ; then
    mv -iv $FREESURFER_HOME/bin/fsl_sub_seychelles $FREESURFER_HOME/bin/fsl_sub_seychelles_sav
    ln -vsi $FSLDIR/bin/fsl_sub $FREESURFER_HOME/bin/fsl_sub_seychelles
  fi
fi
mkdir -p $FREESURFER_HOME/qdec/stats_table # for qdec to work
chmod 777 $FREESURFER_HOME/qdec/stats_table

# are all required progs / files installed ?
$(dirname $0)/scripts/_check_progs.sh

# done
echo "`basename $0` : done."

