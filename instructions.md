# Instructions
- create txt files for all roi_numb, roi_labels and roi_coord (3 different and corresponding spreadsheets)
- create txt files for each network (i.e., each line will be a unique roi_label)


## subject-level analysis

- create spherical 6mm ROIs based on text file input (use the bash iter_two_lists.sh script) (3dUndump)
- for each network, create ROI map (each subject will have an ROI map for 17 total networks)
e.g. network 1
```bash
3dcalc \
-a rFrontal+tlrc \
-b rParietal+tlrc \
-c rControl+tlrc \
-expr 'a+b*2+c*3' \
-prefix ${sub}_ROImap
```
### resample roi map
```bash
#resample roi to resolution of errts file
3dresample -master ${errts_file} -rmode NN -prefix ${roi_dir}/${sub}_${roi}.nii -inset
```

### 1D file creation
- for each ROI, create individual 1D files for each ROI time series (3dmaskave or 3dROIstats) 
```bash
3dROIstats -quiet -mask_f2short -mask ${roi_dir}/${sub}_${roi}.nii ${errts_file} > ${roi_dir}/${sub}_${roi}.1D

3dmaskave -mask ${sub}_${roi}.nii ${errts_file} > ${roi_dir}/${sub}_${roi}.1D 
```

- for each ROImap (above), concatenate all 1D files (from all ROIs) into single spreadsheet
- use code from above but replace -mask ${sub}_${roi}.nii with ${sub}_ROImap+tlrc; use .xls or .txt or .csv extension instead of 1D for output file

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