#!/bin/bash


## Execute the following on 192.168.40.5 
# mkdir /tmp/blankdb ~/Packages
# cd ~/Packages
# sudo reflector --country US,Canada --completion-percent 90 --sort rate --latest 20 --protocol https --save /etc/pacman.d/mirrorlist
# pacman -Syu
# pacman -Syw --cachedir . --dbpath /tmp/blankdb base linux-zen linux-firmware gdisk refind nano openssh sudo xdg-user-dirs base-devel git archlinux-contrib pacman-contrib rclone wol man-db pigz pbzip2 go wget btrfs-progs nfs-utils ding-libs gssproxy nfsidmap rpcbind
# repo-add ./custom.db.tar.gz ./*[^sig]
# ln -s /var/lib/pacman/sync/*.db ~/Packages/
# python -m http.server -d /home/lance/Packages/

## From the booted install media, enter the following command to copy and launch the script
# ssh-keyscan 192.168.40.5 >> /etc/ssh/ssh_known_hosts && scp lance@192.168.40.5:/home/lance/myscripts/installarch.sh /usr/local/sbin/ && installarch.sh

# Verify booted from install media

# prep system for install
INSTALLSRVIP=192.168.40.5
DRVDEV="/dev/vda"
EFIPART="$DRVDEV"1
ROOTPART="$DRVDEV"2
SYSNAME="archvm"
KERNEL="linux-zen"
sgdisk --zap-all "$DRVDEV"
sgdisk --new=1::+550M --typecode 1:ef00 --new=2::0 --typecode 2:8304 "$DRVDEV"
mkfs.fat -F 32 "$EFIPART"
mkfs.btrfs -L archroot "$ROOTPART"
mount --mkdir "$EFIPART" /mnt/boot/efi
mount --mkdir "$ROOTPART" /mnt
echo "storage prepared"

# install system
sed -i "1i Server = http://$INSTALLSRVIP:8000/" /etc/pacman.d/mirrorlist
pacstrap -K /mnt base $KERNEL linux-firmware gdisk refind nano openssh sudo xdg-user-dirs archlinux-contrib pacman-contrib rclone wol man-db btrfs-progs nfs-utils
echo "base packages installed"

# configure system
genfstab -U /mnt >> /mnt/etc/fstab
echo "base fstab created"

arch-chroot /mnt /bin/bash -c "ln -sf /usr/share/zoneinfo/US/Eastern /etc/localtime"
arch-chroot /mnt /bin/bash -c "hwclock --systohc"
echo "clock set"

printf "%s\n" "en_US.UTF-8 UTF-8" | tee -a /mnt/etc/locale.gen > /dev/null 2>&1
arch-chroot /mnt /bin/bash -c "locale-gen"
printf "%s\n" "LANG=en_US.UTF-8" | tee /mnt/etc/locale.conf > /dev/null 2>&1
echo "locale set"

printf "%s\n" "$SYSNAME" | tee /mnt/etc/hostname > /dev/null 2>&1
echo "hostname set"

printf "%s\t%s\n" \
"\"Boot using default options\"" "\"root=PARTUUID=$(lsblk -rno PARTUUID $ROOTPART) rw add_efi_memmap initrd=boot\\initramfs-%v.img\"" | \
tee -a /mnt/boot/refind_linux.conf > /dev/null 2>&1
arch-chroot /mnt /bin/bash -c "refind-install"
printf "\n%s\n" \
"extra_kernel_version_strings linux-hardened,linux-zen,linux-lts,linux" | \
tee -a /mnt/boot/efi/EFI/refind/refind.conf > /dev/null 2>&1
echo "bootloader installed"

printf "%s\n%s\n\n%s\n%s\n" \
"[Match]" "Name=enp0s4" \
"[Network]" "DHCP=yes" | \
tee /mnt/etc/systemd/network/20-wired.network > /dev/null 2>&1
arch-chroot /mnt /bin/bash -c "systemctl enable systemd-networkd.service"
arch-chroot /mnt /bin/bash -c "systemctl enable systemd-resolved.service"

printf "\n%s\n" \
"PermitRootLogin yes" | \
tee -a /mnt/etc/ssh/sshd_config > /dev/null
ssh-keyscan $INSTALLSRVIP >> /mnt/etc/ssh/ssh_known_hosts
arch-chroot /mnt /bin/bash -c "systemctl enable sshd.service"
echo "remote root login enabled"

printf "\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n" \
"# LJS: Set global environment variables" \
"XDG_CONFIG_DIRS DEFAULT=/etc/xdg" \
"XDG_DATA_DIRS   DEFAULT=/usr/local/share:/usr/share" \
"XDG_CONFIG_HOME DEFAULT=@{HOME}/.config" \
"XDG_CACHE_HOME  DEFAULT=@{HOME}/.cache" \
"XDG_DATA_HOME   DEFAULT=@{HOME}/.local/share" \
"XDG_STATE_HOME  DEFAULT=@{HOME}/.local/state" \
"#DIFFPROG        DEFAULT=meld" \
"EDITOR          DEFAULT=nano" \
"SUDO_EDITOR     DEFAULT=nano" \
"VISUAL          DEFAULT=nano" | \
tee -a /mnt/etc/security/pam_env.conf > /dev/null 2>&1
echo "global environment variables set"

printf "%s\n%s\n%s\n\n%s\n%s\n%s\n%s\n%s\n%s\n\n%s\n%s\n%s\n\n%s\n%s\n" \
"# LJS: Make bash follow the XDG_CONFIG_HOME specification https://hiphish.github.io/blog/2020/12/27/making-bash-xdg-compliant/" \
"_confdir=\${XDG_CONFIG_HOME:-\$HOME/.config}/bash" \
"_datadir=\${XDG_DATA_HOME:-\$HOME/.local/share}/bash" \
"# Source settings file" \
"if [ -d "\$_confdir" ]; then" \
"    for f in bash_profile bashrc; do" \
"        [ -f "\$_confdir/\$f" ] && . "\$_confdir/\$f"" \
"    done" \
"fi" \
"# Change the location of the history file by setting the environment variable" \
"[ ! -d "\$_datadir" ] && mkdir -p "\$_datadir"" \
"HISTFILE="\$_datadir/history"" \
"unset _confdir" \
"unset _datadir" | \
tee /mnt/etc/profile.d/bash_xdg.sh > /dev/null 2>&1
arch-chroot /mnt /bin/bash -c "xdg-user-dirs-update"
echo "xdg compliance added"

mkdir -p /mnt/etc/skel/build/{packages,sources,srcpackages,makepkglogs,makepkg} /mnt/etc/skel/mygdrive /mnt/etc/skel/.config/bash
mv /mnt/etc/skel/.bash_profile /mnt/etc/skel/.config/bash/profile
mv /mnt/etc/skel/.bash_logout /mnt/etc/skel/.config/bash/logout
mv /mnt/etc/skel/.bashrc /mnt/etc/skel/.config/bash/bashrc
echo "user directory skeleton created"

scp lance@$INSTALLSRVIP:/home/lance/myscripts/personalizearch.sh /mnt/usr/local/sbin/
scp lance@$INSTALLSRVIP:/home/lance/myscripts/user-setup.sh /mnt/usr/local/sbin/

arch-chroot /mnt /bin/bash -c "passwd"

#umount -R /mnt # && reboot
