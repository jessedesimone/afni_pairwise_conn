#!/bin/bash

# module to handle 1D files that will be used in the creation of group-level correlation matrix
# create 1D file of time series for each roi

# =================================================================
echo "++ running 1d_handler.sh"

# configuration
source config_directories.sh; mkdir -p $mat_out_dir   
flist='id_subj'
isub=`cat ${data_dir}/$flist`
tpref='_tmp'
topref='all_subs'

# ------------------ concatenate 1D time-series for each roi --------------------------
# : 'this will create n .txt files for n ROIs; each .txt file will have y columns for y subjects'
echo "++ concatenating 1D time-series across subjects for each roi"
firstsub=$(head -n 1 $data_dir/$flist)       #find first sub
iroi=`cat $data_dir/$firstsub/${tpref}_roi_mask_list.txt `     #index temp list of rois
for roi in ${iroi[@]}; do 
    echo "processing $roi" 
    input=`ls $data_dir/*/1d_files/*_${roi}.1D`
    1dcat -csvout $input > $mat_out_dir/${tpref}_${topref}_${roi}.csv
done

# ------------------ enter python and handle csv files --------------------------
python3.9 handler_helper.py

# ------------------ clean up --------------------------
rm -rf $mat_out_dir/${tpref}*

echo "++ 1d_handler.sh done"
exit 0