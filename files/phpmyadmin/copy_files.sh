#!/bin/bash

data_folder=`basename $1`

# make sure that destination folder exists and is empty
if [ ! -d "$1" ]; then
    echo "$1 doesn't exist"
    exit 1
fi

if [ ls "$1" | grep . ]; then
   echo "$1 is not empty"
   exit 1
fi

find /var/lib/mysql/ -mindepth 1 -maxdepth 1 -not -name "lost+found" -not -name "$data_folder" -exec mv {} $1 \;
