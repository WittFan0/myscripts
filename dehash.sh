#!/bin/bash        
if [ -z "$1" ]; then 
    echo Please provide a file name to filter
    exit
fi
FILE=$1
sed -e '/^#/d' -e '/^$/d' $FILE | more