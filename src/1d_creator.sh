#!/bin/bash

# module to handle 1D files that will be used in the creation of group-level correlation matrix
# create 1D file of time series for each roi

# =================================================================
echo "++ running 1d_handler.sh"

# configuration
vsub=`cat subname.txt`      #subj name
vepi=errts.${vsub}.anaticor+tlrc        #epi infile
odir=1d_files; mkdir -p $odir       #output directory
tpref=_tmp      #temp file prefix
opref=${vsub}     #output file prefix

# ------------------ create temp list of rois --------------------------
ls roi_mask_* > ${tpref}_roi_mask_list.txt
sed -e 's!.nii.gz!!' ${tpref}_roi_mask_list.txt > ${tpref}_roi_mask_list2.txt
rm -rf ${tpref}_roi_mask_list.txt; mv ${tpref}_roi_mask_list2.txt ${tpref}_roi_mask_list.txt

# ------------------ create 1D time-series for each ROI --------------------------
echo "computing roi stats"
ROI=`cat ${tpref}_roi_mask_list.txt `
for roi in ${ROI[@]}; do
    echo "extracting time series for $roi"
    3dmaskave -mask ${roi}.nii.gz $vepi > $odir/${tpref}_${opref}_${roi}.1D
    cat $odir/${tpref}_${opref}_${roi}.1D | sed 's/|/ /' | awk '{print $1}' > $odir/${opref}_${roi}.1D
done

# ------------------ clean up --------------------------
rm -rf ${tpref}*
rm -rf $odir/${tpref}*

echo "++ 1d_handler.sh done"
exit 0