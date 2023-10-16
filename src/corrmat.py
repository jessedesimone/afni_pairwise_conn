#!/usr/bin/env python3

#import packages
import os
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
from handler_helper import data_reader

os.chdir('../connmat')
df=data_reader('final_matrix_input.csv')

#plot heatmap
sns.set_context('paper')
f, ax = plt.subplots(figsize=(20, 15))
cor = df.corr(method='pearson')
plt.title('Group Correlation Matrix', weight='bold', fontsize=16)
ax = sns.heatmap(cor, vmax=1, annot=False, cmap=sns.color_palette("coolwarm", 20))
ax.set_xticklabels(
    ax.get_xticklabels(),
    rotation=45,
    horizontalalignment='right')
# plt.savefig('CorrMat.png')
plt.show()