#!/bin/bash

## Enter the following command to copy and launch the script
# scp lance@192.168.40.5:/home/lance/myscripts/personalizearch.sh /usr/local/sbin/ && personalizearch.sh

# fail on all errors
#set -e

# Verify running as root
if [ $UID -ne 0 ]; then
    echo "Script must be run as a root user. Exiting."
    exit 1
fi

# Verify that perl is installed
if [ ! -f "/usr/bin/perl" ]; then
    echo "Perl missing."
    exit 1
fi

KERNELTYPE="-zen"
PRIMEGROUPS="sys,log,network,floppy,scanner,power,rfkill,users,video,storage,optical,lp,audio,wheel,adm"
KEYTAICHI="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPPjd/u2DRWdXTBSdnCVYBJxql6qKpzgLm0je/SuDWOu lance@office-manjaro-2019-08-08"
KEYPHONE="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID7tVx29wJ33kGSjuVVDHR24VE+E6jDmM/+yIxcFrYm2 A13"
KEYCHROMEBK="ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAHp+EsJ35cr1TaFYpmp5DM/7oI437btNrHMV49IQlPSNQ1rV+Y2i8l4MDV+eVvKwIoQXdIq/X52Jca8k8W9vUJJeQA3KdBRm/Ls7HS1K/tFWiYpzB8drlZWzz823WkE/Ml7xjLdqPJWeHeQiWNelg4qyVfq9YflgFAfwLzujm0CnYRgKA== lance@acer-c720"

read -r -p "Enter username : " username
if grep -E "^$username" /etc/passwd; then
	echo "$username exists!"
    exit 1
fi
read -r -s -p "Enter password : " password

mount_local() {
    mkdir -p \
    /data \
    /mnt/{shared_data,data0,data1} \
    /var/lib/mythtv

    printf "\n\n%s\n%s\n%s\n%s\n%s\n" \
        "UUID=c8d69336-53af-4c1e-bf71-b1f1bc0aa64d  /mnt/data0        ext4  defaults,noatime,noauto  0  2" \
        "UUID=577e7c48-b22a-4960-9498-a868163e40c1  /mnt/data1        ext4  defaults,noatime,noauto  0  2" \
        "UUID=f430b015-df61-41fd-a9ff-cd6a5b096582  /mnt/shared_data  ext4  defaults,noatime,noauto  0  2" \
        "#/mnt/shared_data/mythtv                    /var/lib/mythtv   none  bind                     0  0" \
        "#/mnt/shared_data/media                     /data             none  bind                     0  0" | \
        tee -a /etc/fstab > /dev/null 2>&1

    systemctl daemon-reload
    echo "local drives added to fstab"
}

share_local() {
    mkdir -p /srv/nfs4/{home,lancedropbox,music,photos,home_movies-orig,television,movies}

    printf "\n\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n" \
        "#/home                                           /srv/nfs4/home             none  bind  0  0" \
        "#/home/lance/Dropbox                             /srv/nfs4/lancedropbox     none  bind  0  0" \
        "#/mnt/shared_data/mythtv                         /srv/nfs4/mythtv           none  bind  0  0" \
        "/mnt/shared_data/media/videos/television        /srv/nfs4/television       none  bind  0  0" \
        "/mnt/shared_data/media/videos/movies            /srv/nfs4/movies           none  bind  0  0" \
        "/mnt/shared_data/media/videos/home_movies-orig  /srv/nfs4/homemovies-orig  none  bind  0  0" \
        "/mnt/shared_data/media/music                    /srv/nfs4/music            none  bind  0  0" \
        "/mnt/shared_data/media/photos                   /srv/nfs4/photos           none  bind  0  0" | \
        tee -a /etc/fstab > /dev/null 2>&1

    systemctl daemon-reload

    printf "\n%s\n%s\n%s\n" \
        "/srv/nfs4               *(rw,sync,no_subtree_check,insecure,fsid=0)" \
        "#/srv/nfs4/home          *(rw,sync,no_subtree_check,insecure,nohide)" \
        "/srv/nfs4/lancedropbox  *(rw,sync,no_subtree_check,insecure,nohide)" | \
        tee -a /etc/exports > /dev/null 2>&1

    echo "local shares added to fstab"
}

mount_remote() {
    mkdir -p /remotedata/{music,photos,movies,television,homemovies-orig}

    printf "\n%s\n" "192.168.40.4  mythbox" | tee -a /etc/hosts > /dev/null 2>&1  # DNS isn't handling this. Why?

    printf "\n\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n" \
        "#//router/movies                            /remotedata/movies           cifs  _netdev,credentials=/etc/samba/.tplinkcredentials,uid=1000,gid=497,iocharset=utf8,file_mode=0664,dir_mode=0775,vers=2.0,noauto   0  0" \
        "#//router/television                        /remotedata/television       cifs  _netdev,credentials=/etc/samba/.tplinkcredentials,uid=1000,gid=497,iocharset=utf8,file_mode=0664,dir_mode=0775,vers=2.0,noauto   0  0" \
        "#//router/music                             /remotedata/music            cifs  _netdev,credentials=/etc/samba/.tplinkcredentials,uid=1000,gid=498,iocharset=utf8,file_mode=0664,dir_mode=0775,vers=2.0,noauto   0  0" \
        "#//router/photos                            /remotedata/photos           cifs  _netdev,credentials=/etc/samba/.tplinkcredentials,uid=1000,gid=498,iocharset=utf8,file_mode=0664,dir_mode=0775,vers=2.0,noauto   0  0" \
        "mythbox:/mythtv                            /var/lib/mythtv              nfs   rsize=8192,wsize=8192,timeo=14,noauto" \
        "mythbox:/movies                            /remotedata/movies           nfs   rsize=8192,wsize=8192,timeo=14,noauto" \
        "mythbox:/television                        /remotedata/television       nfs   rsize=8192,wsize=8192,timeo=14,noauto" \
        "mythbox:/home_movies-orig                  /remotedata/homemovies-orig  nfs   rsize=8192,wsize=8192,timeo=14,noauto" \
        "mythbox:/music                             /remotedata/music            nfs   rsize=8192,wsize=8192,timeo=14,noauto" \
        "mythbox:/photos                            /remotedata/photos           nfs   rsize=8192,wsize=8192,timeo=14,noauto" | \
        tee -a /etc/fstab > /dev/null 2>&1

    systemctl daemon-reload

    echo "remote shares added to fstab"
}

create_primeuser() {
    pass=$(perl -e 'print crypt($ARGV[0], "password")' "$password")
    useradd -m -G "$PRIMEGROUPS" -p "$pass" "$username" && echo "$username has been added to system!" || echo "Failed to add user $username!"

    printf "\n%s\n%s\n" \
    "# LJS: Give $username sudo permission" \
    "$username ALL=(ALL:ALL) ALL" | \
    tee -a /etc/sudoers.d/20-primeuser > /dev/null 2>&1 && echo "$username granted sudo privileges" || echo "Failed to grant $username granted sudo privileges!"

    mkdir -p "/home/$username/.ssh" && \
    chmod -R 700 "/home/$username/.ssh"

    printf "%s\n%s\n%s\n" \
    "$KEYTAICHI" \
    "$KEYPHONE" \
    "$KEYCHROMEBK" | \
    tee -a "/home/$username/.ssh/authorized_keys" > /dev/null 2>&1 && echo "Added authorized SSH keys" || echo "Failed to add authorized SSH keys!"

    chmod 600 "/home/$username/.ssh/authorized_keys"
    chown -R "$username:$username" "/home/$username/.ssh"
}

force_pubkey() {
    printf "\n%s\n%s\n%s\n%s\n" \
        "# LJS: force pubkey logins" \
        "PasswordAuthentication no" \
        "AuthenticationMethods publickey" \
        "KbdInteractiveAuthentication no" | \
        tee -a /etc/ssh/sshd_config > /dev/null 2>&1

    systemctl restart sshd.service
    passwd --lock root && echo "ssh password authentication disabled" || echo "Failed to disable password authentication!"
}

add_btrfs_to_mkinitcpio() {
    sed -i -e "s/^BINARIES=.*/BINARIES=(btrfs)/g" /etc/mkinitcpio.conf
    mkinitcpio -p linux"$KERNELTYPE"
}

mount_local
share_local
mount_remote
create_primeuser
force_pubkey
add_btrfs_to_mkinitcpio
