#!/bin/sh
#
exiftool -overwrite_original -if '$datetimeoriginal' -filemodifydate<DateTimeOriginal -orientation#=6 $1