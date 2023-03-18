#!/bin/bash

# Copied from http://www.freesoftwaremagazine.com/articles/jpg_image_rotation_in_nautilus

while [[ -n "$1" ]]; do
    #if a file and not a dir
    if [[ -f "$1" ]]; then
#        jhead -ft -autorot -nf%Y-%m-%d_%Hh%Mm%S "$1"
      #Exiftool is superior to jhead [but need to add rotation command if exiftool has one]
      #Add copyright, credit, and contact information
      #Taken from http://ninedegreesbelow.com/photography/dam-ingest.html
      exiftool -preserve -overwrite_original \
         -d %Y \
         -MWG:Creator='Lance Styles' \
         -OwnerName='Lance Styles' \
         -IPTC:By-lineTitle='Photographer' \
         -XMP-photoshop:AuthorsPosition='Photographer' \
         -XMP-photoshop:Credit='Lance Styles' \
         -IPTC:Contact='email: lstyles@yahoo.com; website: https://www.facebook.com/lance.styles' \
         -XMP-iptcCore:CreatorWorkEmail='lstyles@yahoo.com' \
         -XMP-iptcCore:CreatorWorkURL='https://www.facebook.com/lance.styles' \
         -MWG:Copyright'<Copyright © $DateTimeOriginal Lance Styles, all rights reserved.' \
         "$1"
      #Normalize file name and reset timestamp
      exiftool -overwrite_original \
         -if '$datetimeoriginal' \
         -d "%Y-%m-%d_%Hh%Mm%S%%-c.%%e" \
         '-filemodifydate<DateTimeOriginal' \
         "-FileName<DateTimeOriginal" \
         "$1"
    fi
    shift
done
