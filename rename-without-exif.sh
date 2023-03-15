#!/bin/bash

##########################################
# This script REPLACES characters in the #
# 5 and 8 positions with dashes, the     #
# 11 position with an underscore, the    #
# 14 position with an "h" and the        #
# 17 position with an "m" to achieve the # 
# standard YYYY-MM-DD_HHhMMmSS format    #
##########################################

SAVEIFS=$IFS
IFS="$(printf '\n\t')"            # Remove 'space', so filenames with spaces work well.

while [[ -n "$1" ]]; do

#  if [[ -f "$1" ]]; then          # if a file and not a dir
#  if [ -e "$1" ] ; then           # Make sure it isn't an empty match
   FILENAME=`basename "$1"`
   if $( echo $FILENAME | grep -v --quiet "^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]_[0-9][0-9]h[0-9][0-9]m[0-9][0-9]" ) ; then          # if the filename isn't already properly formatted
      if $( echo $FILENAME | grep --quiet "^[0-9][0-9][0-9][0-9].[0-9][0-9].[0-9][0-9].[0-9][0-9].[0-9][0-9].[0-9][0-9]" ) ; then
         FILEPATH=`dirname "$1"`
         NEWFILE=`basename "$1" \
            | sed 's/./-/5' \
            | sed 's/./-/8' \
            | sed 's/./_/11' \
            | sed 's/./h/14' \
            | sed 's/./m/17'`
         echo "Renaming $1" to "$FILEPATH/$NEWFILE"
         mv "$1" "$FILEPATH/$NEWFILE"
      elif $( echo $FILENAME | grep --quiet "^[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]_[0-9][0-9][0-9][0-9][0-9][0-9]" ) ; then
         FILEPATH=`dirname "$1"`
         NEWFILE=`basename "$1" \
            | sed 's/^\(.\{4\}\)/\1-/' \
            | sed 's/^\(.\{7\}\)/\1-/' \
            | sed 's/^\(.\{13\}\)/\1h/' \
            | sed 's/^\(.\{16\}\)/\1m/'`
         echo "Renaming $1" to "$FILEPATH/$NEWFILE"
         mv "$1" "$FILEPATH/$NEWFILE"
      elif $( echo $FILENAME | grep --quiet "^[A-Z][A-Z][A-Z]_[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]_[0-9][0-9][0-9][0-9][0-9][0-9]" ) ; then
         FILEPATH=`dirname "$1"`
         NEWFILE=`basename "$1" \
            | cut -c5- \
            | sed 's/^\(.\{4\}\)/\1-/' \
            | sed 's/^\(.\{7\}\)/\1-/' \
            | sed 's/^\(.\{13\}\)/\1h/' \
            | sed 's/^\(.\{16\}\)/\1m/'`
         echo "Renaming $1" to "$FILEPATH/$NEWFILE"
         mv "$1" "$FILEPATH/$NEWFILE"         
      else
        echo "$1 is not in a renamable format. Skipping." 
      fi
   else
      echo "$1 is already in the correct format. Skipping."
   fi
#   echo "$1 is not a file" 
   shift
done
# restore original $IFS value
IFS=$SAVEIFS
