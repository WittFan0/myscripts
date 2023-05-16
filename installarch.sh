#!/bin/bash

# fail on all errors
set -e

## Execute the following on $INSTALLSRVIP 
# mkdir /tmp/blankdb ~/Projects/arch_autoinstall/archpackages
# cd ~/Projects/arch_autoinstall/archpackages
# sudo reflector --country US,Canada --completion-percent 90 --sort rate --latest 20 --protocol https --save /etc/pacman.d/mirrorlist
# pacman -Syu
# pacman -Syw --cachedir . --dbpath /tmp/blankdb $(cat ../packages.txt)
# repo-add ./custom.db.tar.gz ./*[^sig]
# ln -s /var/lib/pacman/sync/*.db ~/Projects/arch_autoinstall/archpackages/
# python -m http.server -d ~/Projects/arch_autoinstall/archpackages/

## From the booted install media, enter the following command to copy and launch the script
# ssh-keyscan 192.168.40.5 >> /etc/ssh/ssh_known_hosts && scp lance@192.168.40.5:/home/lance/myscripts/installarch.sh /usr/local/sbin/ && installarch.sh

# Verify booted from install media

# prep system for install
LOCALIP="192.168.40.31"
LANIF="enp0s4"
INSTALLSRVIP="192.168.40.5"
DRVDEV="/dev/vda"
EFIPART="$DRVDEV"1
ROOTPART="$DRVDEV"2
HOMEPART="$DRVDEV"2
SYSNAME="archvm"
KERNEL="linux-zen"
ROOTPASSWD=".,mnbvcx"

sgdisk --zap-all "$DRVDEV"
sgdisk --new=1::+550M --typecode 1:ef00 --new=2::0 --typecode 2:8304 "$DRVDEV"
mkfs.fat -F 32 -n EFI "$EFIPART"
mkfs.btrfs -L ARCHROOT "$ROOTPART"
mount --mkdir "$ROOTPART" /mnt
cd /mnt
btrfs subvolume create @
btrfs subvolume create @cache
btrfs subvolume create @home
btrfs subvolume create @images
btrfs subvolume create @log
btrfs subvolume create @snapshots
cd
umount /mnt
mount -o compress=zstd,noatime,subvol=@ $ROOTPART /mnt
mkdir -p /mnt/{boot/efi,home,.snapshots,var/{cache,log,lib/libvirt/images}}
mount -o compress=zstd,noatime,subvol=@cache $ROOTPART /mnt/var/cache
mount -o compress=zstd,noatime,subvol=@home $HOMEPART /mnt/home
mount -o noatime,subvol=@images $ROOTPART /mnt/var/lib/libvirt/images # Compression is done using the COW mechanism so it’s incompatible with nodatacow.
chattr +C /mnt/var/lib/libvirt/images  # disable copy on write in order to speed up IO performance
mount -o compress=zstd,noatime,subvol=@log $ROOTPART /mnt/var/log
mount -o compress=zstd,noatime,subvol=@snapshots $ROOTPART /mnt/.snapshots
mount "$EFIPART" /mnt/boot/efi
echo "storage prepared"

# install system

# update pacman.conf for multiple downloads

# reflector --country US,Canada --completion-percent 90 --sort rate --latest 20 --protocol https --save /etc/pacman.d/mirrorlist
sed -i "1i Server = http://$INSTALLSRVIP:8000/" /etc/pacman.d/mirrorlist
pacman --noconfirm -Sy archlinux-keyring
pacstrap -K /mnt base $KERNEL linux-firmware nano openssh sudo xdg-user-dirs archlinux-contrib pacman-contrib btrfs-progs man-db git ansible efibootmgr grub grub-btrfs # refind gdisk nfs-utils rclone wol
echo "base packages installed"

# configure system
genfstab -U /mnt >> /mnt/etc/fstab
echo "base fstab created"

# The following should be done by ansible
# arch-chroot /mnt /bin/bash -c "ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime"
# arch-chroot /mnt /bin/bash -c "hwclock --systohc --utc"
# echo "clock set"

printf "%s\n" "en_US.UTF-8 UTF-8" | tee -a /mnt/etc/locale.gen > /dev/null 2>&1
arch-chroot /mnt /bin/bash -c "locale-gen"
printf "%s\n" "LANG=en_US.UTF-8" | tee /mnt/etc/locale.conf > /dev/null 2>&1
echo "locale set"

printf "%s\n" "$SYSNAME" | tee /mnt/etc/hostname > /dev/null 2>&1
echo "hostname set"

# The following should be done by ansible
# printf "%s\n%s\n%s\n" "127.0.0.1     localhost" \
#   "::1     localhost" \
#   "$LOCALIP     $SYSNAME.q.qw $SYSNAME" | \
#   tee -a /mnt/etc/hosts > /dev/null 2>&1
# echo "hosts created"

printf "%s\n%s\n\n%s\n%s\n\n%s\n%s\n%s\n\n%s\n%s\n" \
  "[Match]" "Name=$LANIF" \
  "[Address]" "Address=$LOCALIP/24" \
  "[Route]" "Gateway=192.168.40.1" "GatewayOnLink=true" \
  "[Network]" "DNS=8.8.8.8" | \
  tee /mnt/etc/systemd/network/20-wired-lan.network > /dev/null 2>&1
arch-chroot /mnt /bin/bash -c "systemctl enable systemd-networkd.service"
arch-chroot /mnt /bin/bash -c "systemctl enable systemd-resolved.service"
echo "networking configured"

# Set Root password
# echo "***** ENTER ROOT PASSWORD *****"
echo -e "$ROOTPASSWD\n$ROOTPASSWD" | passwd --root /mnt root
echo "root password created"

printf "\n%s\n" \
  "PermitRootLogin yes" | \
  tee -a /mnt/etc/ssh/sshd_config > /dev/null 2>&1
ssh-keyscan $INSTALLSRVIP >> /mnt/etc/ssh/ssh_known_hosts
arch-chroot /mnt /bin/bash -c "systemctl enable sshd.service"
echo "remote root login enabled"

# The following should be done by ansible
# mkdir -p /mnt/etc/skel/build/{packages,sources,srcpackages,makepkglogs,makepkg} /mnt/etc/skel/mygdrive /mnt/etc/skel/.config/bash
# mv /mnt/etc/skel/.bash_profile /mnt/etc/skel/.config/bash/profile
# mv /mnt/etc/skel/.bash_logout /mnt/etc/skel/.config/bash/logout
# mv /mnt/etc/skel/.bashrc /mnt/etc/skel/.config/bash/bashrc
# echo "user directory skeleton created"

# The following should be done by ansible
# printf "\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n" \
#   "# LJS: Set global environment variables" \
#   "XDG_CONFIG_DIRS DEFAULT=/etc/xdg" \
#   "XDG_DATA_DIRS   DEFAULT=/usr/local/share:/usr/share" \
#   "XDG_CONFIG_HOME DEFAULT=@{HOME}/.config" \
#   "XDG_CACHE_HOME  DEFAULT=@{HOME}/.cache" \
#   "XDG_DATA_HOME   DEFAULT=@{HOME}/.local/share" \
#   "XDG_STATE_HOME  DEFAULT=@{HOME}/.local/state" \
#   "#DIFFPROG        DEFAULT=meld" \
#   "EDITOR          DEFAULT=nano" \
#   "SUDO_EDITOR     DEFAULT=nano" \
#   "VISUAL          DEFAULT=nano" | \
#   tee -a /mnt/etc/security/pam_env.conf > /dev/null 2>&1
# echo "global environment variables set"

# The following should be done by ansible
# printf "%s\n%s\n%s\n\n%s\n%s\n%s\n%s\n%s\n%s\n\n%s\n%s\n%s\n\n%s\n%s\n" \
#   "# LJS: Make bash follow the XDG_CONFIG_HOME specification https://hiphish.github.io/blog/2020/12/27/making-bash-xdg-compliant/" \
#   "_confdir=\${XDG_CONFIG_HOME:-\$HOME/.config}/bash" \
#   "_datadir=\${XDG_DATA_HOME:-\$HOME/.local/share}/bash" \
#   "# Source settings file" \
#   "if [ -d "\$_confdir" ]; then" \
#   "    for f in bash_profile bashrc; do" \
#   "        [ -f "\$_confdir/\$f" ] && . "\$_confdir/\$f"" \
#   "    done" \
#   "fi" \
#   "# Change the location of the history file by setting the environment variable" \
#   "[ ! -d "\$_datadir" ] && mkdir -p "\$_datadir"" \
#   "HISTFILE="\$_datadir/history"" \
#   "unset _confdir" \
#   "unset _datadir" | \
#   tee /mnt/etc/profile.d/bash_xdg.sh > /dev/null 2>&1
# arch-chroot /mnt /bin/bash -c "xdg-user-dirs-update"
# echo "xdg compliance added"

# printf "%s\t%s\n" \
#   "\"Boot using default options\"" "\"root=PARTUUID=$(lsblk -rno PARTUUID $ROOTPART) rw rootflags=subvol=@ add_efi_memmap initrd=@\\boot\\initramfs-%v.img\"" | \
#   tee -a /mnt/boot/refind_linux.conf > /dev/null 2>&1
# arch-chroot /mnt /bin/bash -c "refind-install"
# cp /mnt/usr/share/refind/drivers_x64/btrfs_x64.efi /mnt/boot/efi/EFI/refind/drivers_x64/
# printf "\n%s\n" \
#   "extra_kernel_version_strings linux-hardened,linux-zen,linux-lts,linux" | \
#   tee -a /mnt/boot/efi/EFI/refind/refind.conf > /dev/null 2>&1
arch-chroot /mnt /bin/bash -c "grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB"
arch-chroot /mnt /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg"
echo "bootloader installed"

# The following should be done by ansible
# curl -o /mnt/usr/local/sbin/personalizearch.sh http://$INSTALLSRVIP:8000/scripts/personalizearch.sh
# curl -o /mnt/usr/local/sbin/user-setup.sh http://$INSTALLSRVIP:8000/scripts/user-setup.sh
# chmod -R 755 /mnt/usr/local/sbin/

#umount -R /mnt && reboot
