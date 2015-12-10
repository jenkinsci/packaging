#!/bin/bash
set -e
set -x 

# Helper script to run 3 bash steps locally
# This is needed because docker doesn't really like executing multiple scripts
if [ ! -z "$1" ]; then
    bash "$1"
fi

if [ ! -z "$2" ]; then
    bash "$2"
fi

if [ ! -z "$3" ]; then
    bash "$3"
fi
