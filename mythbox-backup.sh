#!/bin/bash

# The "runuser" commands below must be run as root
if [ $UID -ne 0 ]; then
    echo "Script must be run as a root user. Exiting."
    exit 1
fi

## TODO make sure this script is running on the server to be backed up

SSHUSER="lance"
BACKUPSRVNAME="taichi"
LOCALDIR="/mnt/shared_data/backup"
REMOTEDIR="/mnt/data0/backup"

nextcloud () {
    NCOWNER="www-data"
    NCSERVER="localhost"  # Specifying "mythbox" here does not work
    NCDATADIR="/var/www/nextcloud"
    NCDBUSER="nextcloud"
    NCDBPASS=""
    NCDBNAME="nextcloud"
    NCLOCALDIR="$LOCALDIR/nextcloud"
    NCDBBAKFILE="$NCLOCALDIR/nextcloud.sql"
    NCBAKFILE="$NCLOCALDIR/nextcloud-files.tar"

    runuser -u $NCOWNER -- /usr/bin/php $NCDATADIR/occ maintenance:mode --on && \
    echo "Enter database password." && \
    runuser -u $NCOWNER -- mysqldump --single-transaction --no-tablespaces --default-character-set=utf8mb4 -h $NCSERVER -u $NCDBUSER -p"$NCDBPASS" $NCDBNAME > $NCDBBAKFILE && \
    runuser -u $NCOWNER -- tar --create --file $NCBAKFILE $NCDATADIR/ && \
    runuser -u $SSHUSER -- rsync -av -e ssh $NCLOCALDIR $SSHUSER@$BACKUPSRVNAME:$REMOTEDIR/
    rm -f $NCBAKFILE $NCDBBAKFILE

    runuser -u $NCOWNER -- /usr/bin/php $NCDATADIR/occ maintenance:mode --off
}

plex () {
    PLEXOWNER="plex"
    PLEXDATADIR='/var/lib/plexmediaserver/Library/Application Support/Plex Media Server'
    PLEXCACHE="$PLEXDATADIR/Cache"
    PLEXLOCALDIR="$LOCALDIR/plex"
    PLEXBAKFILE="$PLEXLOCALDIR/plex-database.tar"

    systemctl stop plexmediaserver.service && \
    runuser -u $PLEXOWNER -- tar --create --exclude="$PLEXCACHE" --file $PLEXBAKFILE --verbose "$PLEXDATADIR"/ && \
    runuser -u $SSHUSER -- rsync -av -e ssh $PLEXLOCALDIR $SSHUSER@$BACKUPSRVNAME:$REMOTEDIR/
    rm -f $PLEXBAKFILE

    systemctl start plexmediaserver.service
}

## not enough space on backup drive to also include movies and television
homemedia () {
    rsync -av -e ssh \
    /mnt/shared_data/media/videos/home_movies-orig \
    /mnt/shared_data/media/photos \
    /mnt/shared_data/media/music \
    $SSHUSER@$BACKUPSRVNAME:$REMOTEDIR/
}

nextcloud
plex
homemedia
