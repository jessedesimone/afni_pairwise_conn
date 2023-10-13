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
firstsub=$(head -n 1 ${data_dir}/id_subj)       #find first sub
- go into first sub folder
- create tmp list of roi_masks_00*
- for each roi in roi_mask tmp list, concat all subjects into single tmp txt file (this will create n txt lists for n ROIs) using 1dcat
- these files will go to connmat directory
- then use 3dTstat to get the average



ls roi_mask_* > ${tpref}_roi_mask_list.txt
sed -e 's!.nii.gz!!' ${tpref}_roi_mask_list.txt > ${tpref}_roi_mask_list2.txt
rm -rf ${tpref}_roi_mask_list.txt; mv ${tpref}_roi_mask_list2.txt ${tpref}_roi_mask_list.txt

# ------------------ create 1D time-series for each ROI --------------------------


# ------------------ clean up --------------------------


echo "++ 1d_handler.sh done"
exit 0