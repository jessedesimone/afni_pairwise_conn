#!/bin/bash
: 'main script for basic configuration and calling other modules'

#==========configuration==========
echo "++ main.sh started"

#set datetime
: 'used for datetime stamp log files'
dt=$(date "+%Y.%m.%d.%H.%M.%S")

#set directories
: 'call config_directories.sh'
source config_directories.sh

#check dependencies
: 'uncomment if you need to check dependencies
code should run fine on current LRN systems'
source dependencies.sh

#create log file
: 'log file will capture terminal output each time driver is run
can be used to check for and troubleshoot errors'
log_file=${log_dir}/log_fmriconnmap_indiv.${dt}
touch $log_file
echo "++ Start time: $dt" 2>&1 | tee $log_file
echo "++ Starting subject-level analysis" 2>&1 | tee -a $log_file

#define subjects
flist='id_subj'
SUB=`cat ${data_dir}/$flist`
echo "number of subjects in analysis" 2>&1 | tee -a $log_file
awk 'END { print NR }' ${data_dir}/$flist 2>&1 | tee -a $log_file