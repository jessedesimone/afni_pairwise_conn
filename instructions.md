# Instructions
## clone git repository
- fork repository to your GitHub account and clone repository to local machine <br/> 
```bash
git clone git@github.com:*username*/afni_pairwise_conn.git
```
- navigate to src and open config_directories.sh
- update the paths to your package; you should really only need to update the top directory (i.e., location where you downloaded the package)

## data preprocessing
- required input file is error time series (e.g., errts.*+tlrc) file from standard afni_proc.py preproccing pipeline 
- I used the afni_proc.py anaticor option (Example 9b. Resting state analysis with ANATICOR) for data preprocessing so input files have the file name "errts.*subj*.anaticor+tlrc"
- any error time series file from afni_proc.py or FSL FEAT should work, but user will need to update the scripts within this package with the correct file naming
- error time series file should be aligned to standard MNI space (I used the MNI152_T1 template)

## setup
### configure python virtual environment
- this package includes python source code from afni and other python modules
- matplotlib and pandas packages must be installed in your python environment
- [dependencies.sh](./src/dependencies.sh) script will check that matplotlib is installed and will exit if not
- install packages
```bash 
pip install <"package name">
```
- activation of python environment is built into [main.sh](./src/main.sh) configuration so update as needed
- on my system, the source code to activate the env is:
```bash
source ~/env/bin/activate
```

### reference lists
- in reference directory, create (or update existing) two text files: (1) [roi_labels.txt](./reference/roi_labels.txt.sh); and (2) [roi_centers.txt](./reference/roi_centers.txt.sh)
- roi_labels.txt: two columns: (1) roi number (i.e., 1..n); and (2) label (e.g., RH_DefaultA_pCunPCC)
- roi_centers.txt: 3 columns representing (x,y,z) MNI coordinates and LPI (i.e., left=left) orientation for the corresponding ROI in roi_labels.txt (row 1 in roi_centers.txt corresponds to row 1 in roi_labels.txt)
- see reference directory for example (MNI coordinates for Yeo 17 network parcellation connectivity atlas) https://github.com/ThomasYeoLab/CBIG/blob/master/stable_projects/brain_parcellation/Yeo2011_fcMRI_clustering/README.md

### data
- in the data directory, create a sub-directory for each subject 
- for each subject add "errts.*subj*.anaticor+tlrc" (epi error time series) and standard space anatomical image to the respective sub-directory
- the anatomical file will be used for QC purposes (package produces jpeg files illustrating the location of the rois overlayed over anatomical imaging)
- store MNI template used in the afni_proc.py registration/warping procedure in nifti directory
- create subject list using the following command:
```bash
touch data_proc/id_subj
```
- Add each subject's unique identifier to the first column of id_subj
```bash
ls sub* > data_proc/id_subj
```

## run main.sh driver
```bash
./src/main.sh
```
- script will loop through each subject
- runs src/roi_setup.tcsh to create masks for each roi
- runs src/roi_map.tcsh to create final_roi_map.*
- runs src/netcorr.tcsh to create whole-brain voxelwise z-score corrrelation maps, matrix files and correlation plots
- runs src/1d_creator.sh to create 1D time-series files for each roi for each subject
- runs src/1d_handler.sh and src/1d_handler_helper.py to create average time-series files for each roi (averaged across subjects at each TR) and produce a final csv file for computing 








## analysis
- compute partial correlation matrix between average time series foir each network (17 total connectivity matrices)
- mantel_test() in python to compare correlation matrices if needed
- use CONN toolbox to compare network connectivity between two or more groups and generate figures

partial correlation matrix in R
https://towardsdatascience.com/keeping-an-eye-on-confounds-a-walk-through-for-calculating-a-partial-correlation-matrix-2ac6b831c5b6