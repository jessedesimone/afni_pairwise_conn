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
#set the python virtual environment
: 'depends on system | may not be needed'
source ~/env/bin/activate
: 'uncomment if you need to check dependencies
code should run fine on current LRN systems'
source dependencies.sh

#define roi coordinate files
ilist=${ref_dir}/roi_centers.txt
ilabtxt=${ref_dir}/roi_labels.txt

#create anat mask file
if [ ! -f ${nii_dir}/anat_mask.nii ]; then
    : 'create mask if it does not already exist'
    echo "++ creating mask of anatomical template" 2>&1 | tee -a $log_file
    : 'mask the anatomical template'
    3dcalc -a ${anat_template} -expr 'step(a)' -prefix ${nii_dir}/anat_mask0.nii
    : 'find the errts input file for the first subject and resample to epi dimensions'
    firstsub=$(head -n 1 ${data_dir}/id_subj)
    3dresample -master ${data_dir}/$firstsub/errts.${firstsub}.anaticor+tlrc -rmode NN -prefix ${nii_dir}/anat_mask.nii -inset ${nii_dir}/anat_mask0.nii
    : 'create erode mask for use in group processing'
    fslmaths ${nii_dir}/anat_mask.nii -kernel sphere 3 -ero ${nii_dir}/anat_mask_ero.nii.gz
    # clean up
    rm -rf ${nii_dir}/anat_mask0.nii
fi
anat_mask=${nii_dir}/anat_mask.nii
echo "++ output mask dataset $anat_mask"

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
    cp $anat_mask ${data_dir}/${sub}/anat_mask.nii
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

        sleep 2

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

        sleep 2

        #==========network correlation==========
        echo "==========network correlation (voxelwise)==========" 2>&1 | tee -a $log_file
        : 'run netcorr.tcsh'
        : 'run script if outdir does not exist '
        if [ ! -d NETCORR_000_INDIV ]; then
            tcsh -c ${src_dir}/netcorr.tcsh 2>&1 | tee -a $log_file
        else 
            : 'if outdir does exist, check to see if number of outfiles matches
            the specified number of ROI centers | only run if they do not match |
            overwrite protection'
            roi_in=$(grep -c ".*" ${ref_dir}/roi_centers.txt)
            echo "++ number of ROIs = $roi_in" 2>&1 | tee -a $log_file
            roi_in=$((roi_in))
            roi_out=$(ls -l NETCORR_000_INDIV/WB_Z_ROI_*.nii.gz | grep ^- | wc -l)
            if [ "$roi_in" -eq "$roi_out" ]; then
                echo "outfiles already exist | skipping step" 2>&1 | tee -a $log_file
            else
                echo "++ !!! OVERWRITING EXISTING DATASET | final_roi_map.nii.gz !!!" 2>&1 | tee -a $log_file
                rm -rf NETCORR_000_INDIV/WB_Z_ROI_*.nii.gz
                echo "creating new newtwork correlation maps" 2>&1 | tee -a $log_file
                tcsh -c ${src_dir}/netcorr.tcsh 2>&1 | tee -a $log_file
            fi
        fi

        sleep 2

        #==========1d file creation==========
        echo "==========1d file creation=========="
        : 'run 1d_creator.sh'
        : 'run script if outdir does not exist '
        if [ ! -d "1d_files" ]; then
            tcsh -c ${src_dir}/1d_creator.sh 2>&1 | tee -a $log_file
        else
            : 'if outdir does exist, check to see if number of outfiles matches
            the specified number of ROI centers | only run if they do not match |
            overwrite protection'
            roi_in=$(grep -c ".*" ${ref_dir}/roi_centers.txt)
            echo "++ number of ROIs = $roi_in" 2>&1 | tee -a $log_file
            roi_in=$((roi_in))
            roi_out=$(ls -l 1d_files/${sub}_roi_mask_*.1D | grep ^- | wc -l)
            if [ "$roi_in" -eq "$roi_out" ]; then
                echo "outfiles already exist | skipping step" 2>&1 | tee -a $log_file
            else
                echo "++ !!! OVERWRITING EXISTING DATASET | ROI time series files !!!" 2>&1 | tee -a $log_file
                rm -rf 1d_files/${sub}_roi_mask_*.1D
                echo "creating ROI time series files" 2>&1 | tee -a $log_file
                tcsh -c ${src_dir}/1d_creator.sh 2>&1 | tee -a $log_file
            fi

        fi

    else
        : 'terminate script if missing input files' 2>&1 | tee -a $log_file
        echo "!! ERROR: anat and/or epi infiles not found for $sub" 2>&1 | tee -a $log_file
        echo "terminating script" 2>&1 | tee -a $log_file
        exit 1
    fi

done

cd $src_dir
sleep 2

#==========1d file handling==========
echo "==========1d file handling=========="
: 'run 1d_handler.sh'
outfile=${mat_out_dir}'/final_matrix_input.csv'
if [[ ! -d $mat_out_dir ]] || [[ ! -f $outfile ]]; then
    : 'run script if connmat outfile does not exist '
    source ${src_dir}/1d_handler.sh 2>&1 | tee -a $log_file
elif [ -f $outfile ]; then
    : 'if outfile exists run column check to confirm correct number of rois'
    roi_in=$(grep -c ".*" ${ref_dir}/roi_centers.txt)
    echo "++ number of ROIs = $roi_in" 2>&1 | tee -a $log_file
    roi_in=$((roi_in))
    roi_out=$(head -1 $outfile | sed 's/[^,]//g' | wc -c)
    roi_out=$((roi_out))
    if [ "$roi_in" -eq "$roi_out" ]; then
        echo "outfile already exist | skipping step" 2>&1 | tee -a $log_file
    else
        echo "++ !!! OVERWRITING EXISTING DATASET | final matrix input !!!" 2>&1 | tee -a $log_file
        rm -rf 1d_files/${sub}_roi_mask_*.1D
        source ${src_dir}/1d_handler.sh 2>&1 | tee -a $log_file
    fi
fi

#==========plot correlation matrix==========
echo "==========plotting and saving final correlation matrix=========="
: 'run corrmat.py'
outfile=${mat_out_dir}'/group_corrmat.jpg'
if [ ! -f ${mat_out_dir}'/group_corrmat.jpg' ]; then
    : 'run if outfile does not exist'
    awk '{ print $2 }' ${ref_dir}/roi_labels.txt > ${ref_dir}/_tmp_roi_labels_corrmat.txt     #create tmp txt file of roi_labels    
    python3 corrmat.py
    rm -rf ${ref_dir}/_tmp_roi_labels_corrmat.txt       #remove tmp file
else

    ##WORKING HERE: INPUT CONTINGENCY STATEMENT

fi


echo "++ main.sh finished"

