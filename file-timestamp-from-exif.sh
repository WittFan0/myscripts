#!/bin/bash

while [[ -n "$1" ]]; do
    #if a file and not a dir
    if [[ -f "$1" ]]; then
      #Normalize file name and reset timestamp
      exiftool -overwrite_original \
         -if '$datetimeoriginal' \
         '-filemodifydate<DateTimeOriginal' \
         "$1"
    fi
    shift
done
