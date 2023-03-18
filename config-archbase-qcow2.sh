#!/bin/bash

# sudo scp lance@192.168.40.5:/home/lance/Dropbox/bin/config-arch-image.sh /usr/local/sbin/ && sudo config-arch-image.sh

INSTALLSRVIP=192.168.40.5

sudo sed -i "1i Server = http://$INSTALLSRVIP:8000/" /etc/pacman.d/mirrorlist
sudo pacman -S --needed --noconfirm nano xdg-user-dirs archlinux-contrib pacman-contrib rclone wol man-db go nfs-utils
sudo ln -sf /usr/share/zoneinfo/US/Eastern /etc/localtime
sudo hwclock --systohc
printf "%s\n" "en_US.UTF-8 UTF-8" | sudo tee -a /etc/locale.gen > /dev/null 2>&1
sudo locale-gen
printf "%s\n" "LANG=en_US.UTF-8" | sudo tee /etc/locale.conf > /dev/null 2>&1
printf "\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n" "# LJS: Set global environment variables" "XDG_CONFIG_DIRS DEFAULT=/etc/xdg" "XDG_DATA_DIRS   DEFAULT=/usr/local/share:/usr/share" "XDG_CONFIG_HOME DEFAULT=@{HOME}/.config" "XDG_CACHE_HOME  DEFAULT=@{HOME}/.cache" "XDG_DATA_HOME   DEFAULT=@{HOME}/.local/share" "XDG_STATE_HOME  DEFAULT=@{HOME}/.local/state" "#DIFFPROG        DEFAULT=meld" "EDITOR          DEFAULT=nano" "SUDO_EDITOR     DEFAULT=nano" "VISUAL          DEFAULT=nano" | sudo tee -a /etc/security/pam_env.conf > /dev/null 2>&1
printf "%s\n%s\n%s\n\n%s\n%s\n%s\n%s\n%s\n%s\n\n%s\n%s\n%s\n\n%s\n%s\n" "# LJS: Make bash follow the XDG_CONFIG_HOME specification https://hiphish.github.io/blog/2020/12/27/making-bash-xdg-compliant/" "_confdir=\${XDG_CONFIG_HOME:-\$HOME/.config}/bash" "_datadir=\${XDG_DATA_HOME:-\$HOME/.local/share}/bash" "# Source settings file" "if [ -d "\$_confdir" ]; then" "    for f in bash_profile bashrc; do" "        [ -f "\$_confdir/\$f" ] && . "\$_confdir/\$f"" "    done" "fi" "# Change the location of the history file by setting the environment variable" "[ ! -d "\$_datadir" ] && mkdir -p "\$_datadir"" "HISTFILE="\$_datadir/history"" "unset _confdir" "unset _datadir" | sudo tee /etc/profile.d/bash_xdg.sh > /dev/null 2>&1
sudo xdg-user-dirs-update
sudo mkdir -p /etc/skel/build/{packages,sources,srcpackages,makepkglogs,makepkg} /etc/skel/mygdrive /etc/skel/.config/bash
sudo mv /etc/skel/.bash_profile /etc/skel/.config/bash/profile
sudo mv /etc/skel/.bash_logout /etc/skel/.config/bash/logout
sudo mv /etc/skel/.bashrc /etc/skel/.config/bash/bashrc

sudo scp lance@$INSTALLSRVIP:/home/lance/myscripts/personalizearch.sh /usr/local/sbin/
sudo scp lance@$INSTALLSRVIP:/home/lance/myscripts/user-setup.sh /usr/local/sbin/

sudo personalizearch.sh
#user-setup.sh
