#!/bin/bash

# Taken from: http://www.linuxquestions.org/questions/linux-newbie-8/how-to-rename-a-file-based-on-it-creation-date-752694/

#########################################################
# This script renames all the MTS files in the current  #
# directory to the date the file was last modified      #
#########################################################

# *nix filesystems don't keep track of the creation date of files.
# You can only get time of last modification, which is what the "%y"
# option of stat gives you in the string below

#for file in *; do NEW_FILENAME=$(stat "$1" --format %y); echo mv "$1" "$NEW_FILENAME"; done

while [[ -n "$1" ]]; do
    #if a file and not a dir
    if [[ -f "$1" ]]; then
        FILEPATH=`dirname "$1"`
        NEW_FILENAME=$(stat $1 --format %y|awk '{print $1"_"$2}'|sed 's/\:/h/'|sed 's/\:/m/'|cut -f1 -d'.')"_"`basename $1`;
		mv "$1" "$FILEPATH/$NEW_FILENAME"
    fi
    shift
done
