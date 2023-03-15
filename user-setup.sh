#!/bin/bash

## Enter the following command to copy and launch the script
# scp lance@192.168.40.5:/home/lance/myscripts/user-setup.sh /usr/local/sbin/ && user-setup.sh

# Verify not running as root
if [ $UID -eq 0 ]; then
    echo "Script must be run as a regular user. Exiting."
    exit 1
fi

xdg_move () {
    [ -d "$HOME/.config/bash" ] || mkdir -p "$HOME/.config/bash"
    [ -f "$HOME/.bashrc" ] && mv "$HOME/.bashrc" "$HOME/.config/bash/bashrc"
    [ -f "$HOME/.bash_aliases" ] && mv "$HOME/.bash_aliases" "$HOME/.config/bash/aliases"
    [ -f "$HOME/.bash_logout" ] && mv "$HOME/.bash_logout" "$HOME/.config/bash/logout"
    [ -f "$HOME/.bash_profile" ] && mv "$HOME/.bash_profile" "$HOME/.config/bash/profile"
    [ -d "$HOME/.local/share/bash" ] || mkdir -p "$HOME/.local/share/bash"
    [ -f "$HOME/.bash_history" ] && mv "$HOME/.bash_history" "$HOME/.local/share/bash/history"
}

add_path () {
    [ -d "$HOME/.local/bin" ] && printf "\n%s\n" "PATH=\"$HOME/.local/bin:$PATH\"" | tee -a "$HOME/.config/bash/bashrc"
    [ -d "$HOME/Dropbox/bin" ] && printf "\n%s\n" "PATH=\"$HOME/Dropbox/bin:$PATH\"" | tee -a "$HOME/.config/bash/bashrc"
    [ -d "$HOME/Dropbox/bin/myscripts" ] && printf "\n%s\n" "PATH=\"$HOME/Dropbox/bin/myscripts:$PATH\"" | tee -a "$HOME/.config/bash/bashrc"
}

add_aliases () {
    printf "\n%s\n" "[[ -f \"$HOME/.config/bash/aliases\" ]] && . \"$HOME/.config/bash/aliases\"" | \
    tee -a "$HOME/.config/bash/bashrc" > /dev/null

    printf "\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n" \
    "alias reboot='sudo reboot'" \
    "alias poweroff='sudo poweroff'" \
    "alias shutdown='sudo shutdown'" \
    "alias halt='sudo halt'" \
    "alias chown='sudo chown --preserve-root'" \
    "alias pacupg='yay -Syu'" \
    "alias ubupg='sudo apt-get update && sudo apt-get upgrade'" \
    "alias srven='sudo systemctl enable'" \
    "alias srvdis='sudo systemctl disable'" \
    "alias srvstart='sudo systemctl start'" \
    "alias srvstop='sudo systemctl stop'" \
    "alias srvrest='sudo systemctl restart'" \
    "alias grubupdarch='sudo grub-mkconfig -o /boot/grub/grub.cfg'" \
    "alias mkinit='sudo mkinitcpio -p linux'" \
    "alias ping='ping -c 5'" \
    "alias ln='ln -i'" \
    "alias chmod='chmod --preserve-root'" \
    "alias chgrp='chgrp --preserve-root'" \
    "alias wget='wget -c'" \
    "alias srchhist='history | grep'" \
    "alias srvstat='systemctl status'" \
    "alias srvlist='systemctl list-unit-files --type=service'" \
    "alias startvncsrv='/usr/bin/x11vnc -auth guess -noxdamage -display :0 -rfbauth /etc/x11vnc.pwd -rfbport 5900'" \
    "alias mntgdrv='rclone mount mygoogledrive: ~/mygdrive'" \
    "alias sshtaichi='ssh -p 9282 lance@taichi'" \
    "alias sshrpi01='ssh -p 9284 lance@rpi3-01'" \
    "alias waketaichi='wol 70:85:C2:D3:E5:FA'" \
    "alias wakedan='wol 00:1e:37:cc:7e:76'" \
    "alias df='df -H'" \
    "alias du='du -ch'" | \
    tee -a "$HOME/.config/bash/aliases" > /dev/null && \
    . "$HOME/.config/bash/aliases"
}

## TODO check whether we are on Arch 
install_yay() {
    mkdir -p "$HOME/.config/pacman"
    printf "%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n" \
    "PKGDEST=$HOME/build/packages" \
    "SRCDEST=$HOME/build/sources" \
    "SRCPKGDEST=$HOME/build/srcpackages" \
    "LOGDEST=$HOME/build/makepkglogs" \
    "PACKAGER=\"Lance Styles <lstyles@yahoo.com>\"" \
    "GPGKEY=\"2BCEB89C8F157627\"" \
    "MAKEFLAGS=\"-j\$(nproc)\"" \
    "BUILDDIR=$HOME/build/makepkg" \
    "COMPRESSZST=(zstd -c -z -q --threads=0 -)" \
    "COMPRESSXZ=(xz -c -z --threads=0 -)" \
    "COMPRESSGZ=(pigz -c -f -n)" \
    "COMPRESSBZ2=(pbzip2 -c -f)" | \
    tee "$HOME/.config/pacman/makepkg.conf" > /dev/null
    sudo pacman -S --needed --noconfirm pigz pbzip2 go base-devel git
    cd "$HOME/build/sources" && git clone https://aur.archlinux.org/yay.git && \
    cd yay && \
    makepkg -si --noconfirm
    cd "$HOME" || exit
    echo "yay installed"
}

xdg_move
add_path
add_aliases
#install_yay
