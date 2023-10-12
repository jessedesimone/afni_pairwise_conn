#!/bin/bash
: 'main script for basic configuration and calling other modules'

#==========configuration==========
echo "++ main.sh started"
#set directories
: 'call config_directories.sh'
source config_directories.sh

#set datetime
: 'used for datetime stamp log files'
dt=$(date "+%Y.%m.%d.%H.%M.%S")

#create log file
: 'log file will capture terminal output each time driver is run
can be used to check for and troubleshoot errors'
log_file=${log_dir}/log_fmriconnmap_indiv.${dt}
touch $log_file
echo "++ Start time: $dt" 2>&1 | tee $log_file

#check dependencies
: 'uncomment if you need to check dependencies
code should run fine on current LRN systems'
source dependencies.sh

#define roi coordinate files
ilist=${ref_dir}/roi_centers.txt
ilabtxt=${ref_dir}/roi_labels.txt

#define subjects
echo "++ Starting subject-level analysis" 2>&1 | tee -a $log_file
flist='id_subj'
SUB=`cat ${data_dir}/$flist`
echo "number of subjects in analysis:" 2>&1 | tee -a $log_file
awk 'END { print NR }' ${data_dir}/$flist 2>&1 | tee -a $log_file

for sub in ${SUB[@]}
do
    echo " " 2>&1 | tee -a $log_file
    echo "*** SUBJECT: $sub ***" 2>&1 | tee -a $log_file

    #define infiles
    epi=errts.${sub}.anaticor+tlrc
    anat=anat_final.${sub}+tlrc

    # copy some files
    cp $ilist ${data_dir}/${sub}/roi_centers.txt
    cp $ilabtxt ${data_dir}/${sub}/roi_labels.txt
    echo $sub > ${data_dir}/${sub}/subname.txt
    
    #enter directory
    cd $data_dir/$sub

    #==========subject-level processing==========

    if [[ -f ${epi}.HEAD ]] && [[ -f ${anat}.HEAD ]]; then
        : 'check that infiles for subject exist, then proceed'
        echo "infiles for $sub found" 2>&1 | tee -a $log_file

        #==========ROI setup==========
        echo "==========ROI setup==========" 2>&1 | tee -a $log_file
        : 'run roi_setup.tcsh'
        : 'check to see if number of outfiles match number of roi centers specified
        only run script if they do not match | overwrite protection'
        roi_in=$(grep -c ".*" ${ref_dir}/roi_centers.txt)
        roi_in=$((roi_in))
        roi_out=$(ls -l roi_mask_* | grep ^- | wc -l)
        roi_out=$((roi_out))
        if [ "$roi_in" -eq "$roi_out" ]; then
            echo "outfiles already exist | skipping step" 2>&1 | tee -a $log_file
        else
            echo "drawing ROIs" 2>&1 | tee -a $log_file
            tcsh -c ${src_dir}/roi_setup.tcsh 2>&1 | tee -a $log_file
        fi

        sleep 5

        #==========ROI map==========
        echo "==========ROI map==========" 2>&1 | tee -a $log_file
        : 'run script if outfile does not exist '
        outfile=final_roi_map.nii.gz
        if [ ! -f $outfile ]; then
            echo "creating ROI map" 2>&1 | tee -a $log_file
            tcsh -c ${src_dir}/roi_map.tcsh 2>&1 | tee -a $log_file
        else
            : 'if outfile does exist, check to make sure that it
            contains the correct number of ROIs | only run if the
            number of ROIs does not match the specified ROI centers |
            overwrite protection'
            roi_in=$(grep -c ".*" ${ref_dir}/roi_centers.txt)
            echo "++ number of ROIs = $roi_in" 2>&1 | tee -a $log_file
            roi_in=$((roi_in))

            if (( $roi_in < 10)); then
                roi_out1=$(grep -n "ni_dimen" final_roi_map.niml.lt)
                roi_out2="${roi_out1:12}"
                roi_out="${roi_out2: :1}"
            elif (( $roi_in > 10)) && (( $roi_in < 100)); then
                roi_out1=$(grep -n "ni_dimen" final_roi_map.niml.lt)
                roi_out2="${roi_out1:12}"
                roi_out="${roi_out2: :2}"
            elif (( $roi_in > 100)); then
                roi_out1=$(grep -n "ni_dimen" final_roi_map.niml.lt)
                roi_out2="${roi_out1:12}"
                roi_out="${roi_out2: :3}"
            fi

            if [ "$roi_in" -eq "$roi_out" ]; then
                echo "++ outfile already contains correct number of ROIs | skipping step" 2>&1 | tee -a $log_file
            else
                echo "++ !!! OVERWRITING EXISTING DATASET | final_roi_map.nii.gz !!!" 2>&1 | tee -a $log_file
                rm -rf $outfile
                echo "creating new ROI map" 2>&1 | tee -a $log_file
                tcsh -c ${src_dir}/roi_map.tcsh 2>&1 | tee -a $log_file
            fi
        fi

    else
        : 'terminate script if missing input files' 2>&1 | tee -a $log_file
        echo "!! ERROR: anat and/or epi infiles not found for $sub" 2>&1 | tee -a $log_file
        echo "terminating script" 2>&1 | tee -a $log_file
        exit 1
    fi

done
