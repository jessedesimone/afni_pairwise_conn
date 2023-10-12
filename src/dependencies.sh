#!/bin/bash
set -e

: 'module to check dependencies'

echo "++ checking dependencies" 2>&1 | tee -a $log_file
if command -v afni >/dev/null 2>&1; then
    echo "afni is installed" 2>&1 | tee -a $log_file
else
    echo >&2 "afni is not installed | aborting " 2>&1 | tee -a $log_file
    exit 1
fi