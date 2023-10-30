#!/bin/bash
: 'configure directories for data processing stage'
echo "configuring directories"
top=/Users/jessedesimone/desimone_github        #parent directory
pkg_dir=${top}/afni_pairwise_conn       #package directory
data_dir=${pkg_dir}/data_proc       #processed data directory
src_dir=${pkg_dir}/src      #source code directory
log_dir=${pkg_dir}/logs; mkdir -p $log_dir      #log directory
ref_dir=${pkg_dir}/reference      #reference directory
nii_dir=${pkg_dir}/nifti        #nifti directory
out_dir=${pkg_dir}/output       #output directory
mat_out_dir=${pkg_dir}/corrmat      #connmat output directory


