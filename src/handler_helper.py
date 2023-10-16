#!/usr/bin/env python3

'''module to compute mean time series across subjects for each ROI'''

#import packages
import os
import pandas as pd
import glob
import fnmatch

os.chdir('../connmat')

#define data reader
def data_reader(fname):
    fh = os.path.join(os.getcwd(), fname)
    return pd.read_csv(fh)

#def calculator
def mean_calc():
    df = data_reader(file)
    df['mean'] = df.mean(axis=1)
    return df

if __name__ == "__main__":
    print("++ running handler_helper.py")
    
    # ------------------ compute average time-series across subjects for each roi --------------------------
    print("++ computing average time-series across subjects for each roi")
    '''find all files'''
    files = glob.glob('_tmp_all_subs_roi_mask_*.csv')
    files.sort()
    print(files)
    print("finding files")
    '''compute the mean for each row of dataframe and replace infile with new file'''
    count=1
    for file in files:
        #index counter for naming
        if count < 10 : count_str=f'00{count}'
        elif count >9 and count < 100 : count_str=f'0{count}'
        else : count_str=f'{count}'
        
        #compute mean for each dataframe
        print("computing mean time-series for", file)
        df = mean_calc()
        df.to_csv(file, index=False)
        
        #subset the mean dataframe and create outfile; change header to indicate the ROI index
        df_mean = pd.DataFrame(df['mean'])
        df_mean=df_mean.rename(columns={"mean": count_str + '_mean'})
        print(df_mean.info())
        outfile='_tmp_mean_roi_mask_'+ count_str +'.csv'
        print('output file is: ', outfile)
        df_mean.to_csv(outfile, index=False)
        count=count+1
        
    # ------------------ concatenate average time-series for each roi --------------------------
    print("++concatenating average time-series for each roi into single file")
    #get list of files to concatenate
    files = glob.glob('_tmp_mean_roi_mask_*.csv')
    files.sort()
    print(files)

    '''create empty dataframe'''
    df_concat=pd.DataFrame()
    '''append each file to single csv'''
    for f in files:
        print('reading csv file',f, 'as dataframe')
        df_tmp = pd.read_csv(f)
        #print(df_tmp.info())
        print('concatenating dataframe to master')
        df_concat=pd.concat([df_concat,df_tmp], axis=1, ignore_index=False)

    #save dataframe as csv
    print('final dataframe created')
    print(df_concat.info(), df_concat)
    fopref='final_matrix_input'
    df_concat.to_csv(fopref + '.csv', index=False)

    print('++ handler_helper.py done')

