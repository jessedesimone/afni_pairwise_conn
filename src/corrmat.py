#!/usr/bin/env python3

#import packages
import os
import pandas as pd
from helpers import *

#read data
#os.chdir('../connmat')
df=pd.read_csv('../connmat/final_matrix_input.csv')
df_roi=pd.read_csv('../reference/_tmp_roi_labels_corrmat.txt', names=['roi_label'])

#convert df_roi to list
roi_list=df_roi.roi_label.values.tolist()

#replace column headers with original labels
df=df.set_axis([roi_list], axis="columns")

#plot correlation heatmap
corrmap(df, 'pearson', 'Group Correlation Matrix')