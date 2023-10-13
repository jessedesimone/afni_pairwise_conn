# Instructions
## Clone git repository & configure directories
- Fork repository to your GitHub account and clone repository to local machine <br/> 
```bash
git clone git@github.com:*username*/afni_pairwise_conn.git
```
- Navigate to src and open config_directories.sh
- Update the paths to your package; you should really only need to update the top directory (i.e., location where you downloaded the package)

## data preprocessing
- Required input file is error time series (e.g., errts.*+tlrc) file from standard afni_proc.py preproccing pipeline 
- I used the afni_proc.py anaticor option (Example 9b. Resting state analysis with ANATICOR) for data preprocessing so input files have the file name "errts.*subj*.anaticor+tlrc"
- Any error time series file from afni_proc.py or FSL FEAT should work, but user will need to update the scripts within this package with the correct file naming
- Error time series file should be aligned to standard MNI space (I used the MNI152_T1 template)

## setup
### Configure python virtual environment
- This package includes python source code from afni 
- matplotlib package is required for netcorr.tcsh
- For me, the terminal command is: 
```bash
source ~/env/bin/activate
``` 
- This is built into the main.sh script configuration so update as needed
- The dependencies.sh script will check that matplotlib is installed and will exit if not

### reference lists
- in reference directory, create (or update existing) two text files: (1) roi_labels.txt; and (2) roi_centers.txt
- roi_labels.txt: two columns: (1) roi number (i.e., 1..n); and (2) label (e.g., RH_DefaultA_pCunPCC)
- roi_centers.txt: 3 columns representing (x,y,z) MNI coordinates and LPI (i.e., left=left) orientation for the corresponding ROI in roi_labels.txt (row 1 in roi_centers.txt corresponds to row 1 in roi_labels.txt)
- see reference directory for example (MNI coordinates for Yeo connectivity atlas 17 network parcellation) https://github.com/ThomasYeoLab/CBIG/blob/master/stable_projects/brain_parcellation/Yeo2011_fcMRI_clustering/README.md
- create text file for each network (e.g. default_mode.txt); each row will contain a unique roi label; column format is the same as roi_labels.txt

### data
- In the data directory, create a subdirectory for each subject 
- For each subject add errts.*.anaticor+tlrc (epi error time series) and standard space anatomical image to the respective subdirectory
- The anatomical file will be used for QC purposes
- Store MNI template used in the afni_proc.py registration/warping procedure in nifti directory
- Create subject list using the following command: <br/>
```bash
touch data/id_subj
```
- Add each subject's unique identifier to the first column of id_subj

## run main.sh driver
```bash
./src/main.sh
```
- script will loop through each subject
- runs src/roi_setup.tcsh to create masks for each roi
- runs src/roi_map.tcsh to create final_roi_map.*
- runs src/netcorr.tcsh to create whole-brain voxelwise z-score corrrelation maps, matrix files and correlation plots
- runs src/1d_creator.sh to create 1D time-series files for each roi for each subject



# NEXT STEP
- create concatenated 1dfiles containing the z-score for given roi across all subjects
1dcat sub_01_roi_mask_001.1D sub_02_roi_mask_001.1D > ${all_subs}_roi_mask_001.1D
- this will creeate n 1d files for n ROIs
- then get average for each roi; put into 1D file
- this will produce a single 1D file with the average time series for each ROI
- then concatenate the averages for all ROIs in a given network
- 17 total txt files; 1 per network; multiple ROIs in each





'''
## subject-level analysis
# - create spherical 6mm ROIs based on text file input (use the bash iter_two_lists.sh script) (3dUndump)
# - for each network, create ROI map (each subject will have an ROI map for 17 total networks)
# e.g. network 1
# ```bash
# 3dcalc \
# -a rFrontal+tlrc \
# -b rParietal+tlrc \
# -c rControl+tlrc \
# -expr 'a+b*2+c*3' \
# -prefix ${sub}_ROImap
# ```
# ### resample roi map
# ```bash
# #resample roi to resolution of errts file
# 3dresample -master ${errts_file} -rmode NN -prefix ${roi_dir}/${sub}_${roi}.nii -inset
# ```

# ### 1D file creation
# - for each ROI, create individual 1D files for each ROI time series (3dmaskave or 3dROIstats) 
# ```bash
# 3dROIstats -quiet -mask_f2short -mask ${roi_dir}/${sub}_${roi}.nii ${errts_file} > ${roi_dir}/${sub}_${roi}.1D

# 3dmaskave -mask ${sub}_${roi}.nii ${errts_file} > ${roi_dir}/${sub}_${roi}.1D 
# ```
'''


### QC correlation matrix
- create correlation matrix for each subject x network combination (17 total for each subject)
- this is for QC purposes
```bash
3dNetCorr \
-inset ${errts} \
-in_rois ${sub}_ROImap+tlrc \
-fish_z \
-ts_wb_corr \
-prefix ROImap_matrix
```

## group-level analysis
### average time-series 
- create 1D file for average time series for each ROI (114 total average time-series)
```bash
for sub in ${SUB[@]}; do
    for roi in ${ROI[@]}; do
        cat ${sub}/${roi_dir}/${sub}_${roi}.1D >> ${output_dir}/${roi}_all_subs.1D
    done
done
```
- each 1D file will have a column containing the time-series for each subject
- then use 3dTstat to find the average time-series for each roi (114 total average 1D files)
```bash
for roi in ${ROI[@]}; do
    3dTstat -mean -prefix ${output_dir}/${roi}_avg.1D ${output_dir}/${roi}_all_subs.1D
done
```
----------------- Processing 1D files with 3dTstat -----------------
To analyze a 1D file and get statistics on each of its columns,
you can do something like this:
  3dTstat -stdev -bmv -prefix stdout: file.1D\'
where the \' means to transpose the file on input, since 1D files
read into 3dXXX programs are interpreted as having the time direction
along the rows rather than down the columns.  In this example, the
output is written to the screen, which could be captured with '>'
redirection.  Note that if you don't give the '-prefix stdout:'
option, then the output will be written into a NIML-formatted 1D
dataset, which you might find slightly confusing (but still usable).

- then concatenate all ROIs into a spreadsheet for each network (17 total spreadsheets with multiple ROIs in each); uses ${output_dir}/${roi}_avg.1D as input

## analysis
- compute partial correlation matrix between average time series foir each network (17 total connectivity matrices)
- mantel_test() in python to compare correlation matrices if needed
- use CONN toolbox to compare network connectivity between two or more groups and generate figures

partial correlation matrix in R
https://towardsdatascience.com/keeping-an-eye-on-confounds-a-walk-through-for-calculating-a-partial-correlation-matrix-2ac6b831c5b6