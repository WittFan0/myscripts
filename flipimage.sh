#!/bin/sh
#
exiftool -overwrite_original -if '$datetimeoriginal' -filemodifydate<DateTimeOriginal -orientation#=3 $1