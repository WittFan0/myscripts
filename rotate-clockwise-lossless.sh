#!/bin/bash

# Copied from http://www.freesoftwaremagazine.com/articles/jpg_image_rotation_in_nautilus

while [[ -n "$1" ]]; do
    #if a file and not a dir
    if [[ -f "$1" ]]; then
        #by default jpegtran copies only
        # some Exif data; specify "all"
        jpegtran -rotate 90 -copy all -outfile "$1" "$1"
        
        #clear rotation/orientation tag
        # so that some viewers (e.g. Eye
        # of GNOME) won't be fooled
		# **** For some reason, this command causes an image to only be able to be rotated once! ****
        #jhead -ft -norot "$1"
    fi
    shift
done

# for file in %F; do tempfile=$(mktemp); (jpegtran -copy all -rotate 90 $file > $tempfile); mv -f $tempfile $file; rm -f $tempfile; done
