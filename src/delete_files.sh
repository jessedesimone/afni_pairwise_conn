#!/bin/bash
: 'this module will remove all output files of this package'
source config_directories.sh
rm -rf $mat_out_dir
rm -rf $data_dir/*/1d_files
rm -rf $data_dir/*/NETCORR*
rm -rf $data_dir/*/_tmp*
rm -rf $data_dir/*/*roi*
rm -rf $data_dir/*/anat_mask.nii
rm -rf $data_dir/*/subname.txt