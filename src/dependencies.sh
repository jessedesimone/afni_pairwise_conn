#!/bin/bash
set -e

: 'module to check dependencies'

echo "++ checking dependencies" 2>&1 | tee -a $log_file
if command -v afni >/dev/null 2>&1; then
    echo "afni is installed" 2>&1 | tee -a $log_file
else
    echo >&2 "afni is not installed | aborting " 2>&1 | tee -a $log_file
    echo "install AFNI"; exit 1
fi
if pip show matplotlib >/dev/null 2>&1; then
    echo "matplotlib is installed"
else 
    echo >&2 "matplotlib is not installed | Aborting "
    echo "use pip to install matplotlib"; exit 1
fi
if pip show pandas >/dev/null 2>&1; then
    echo "pandas is installed"
else 
    echo >&2 "pandas is not installed | Aborting "
    echo "use pip to install pandas"; exit 1
fi