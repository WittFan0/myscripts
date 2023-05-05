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
    [ -d "$HOME/myscripts" ] && printf "\n%s\n" "PATH=\"$HOME/myscripts:$PATH\"" | tee -a "$HOME/.config/bash/bashrc"
}

add_aliases () {
    printf "\n%s\n" "[[ -f \"$HOME/.config/bash/aliases\" ]] && . \"$HOME/.config/bash/aliases\"" | \
    tee -a "$HOME/.config/bash/bashrc" > /dev/null 2>&1

    printf "\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n" \
    "alias grep='grep --color=auto'" \
    "alias fgrep='fgrep --color=auto'" \
    "alias egrep='egrep --color=auto'" \
    "alias gc='cd ~/Projects && git clone'" \
    "alias reflect='sudo reflector --country US,Canada --completion-percent 90 --sort rate --latest 20 --protocol https --save /etc/pacman.d/mirrorlist'" \
    "alias ps='ps auxf'" \
    "alias psgrep=\"ps aux | grep -v grep | grep -i -e VSZ -e\"" \
    "alias jctl='journalctl -p 3 -xb'" \
    "alias resource='cls && . ~/.config/bash/bashrc'" \
    "alias ls='ls -h --color'" \
    "alias la='ls -a --color'" \
    "alias ll='ls -l --group-directories-first'" \
    "alias lr='tree -Chpuga --du'" \
    "alias listdisks='lsblk -d -o path,label,model,tran,size,pttype,ptuuid,serial,wwn'" \
    "alias reboot='sudo reboot'" \
    "alias poweroff='sudo poweroff'" \
    "alias shutdown='sudo shutdown'" \
    "alias halt='sudo halt'" \
    "alias chown='sudo chown --preserve-root'" \
    "alias pacman='sudo pacman --color auto'" \
    "alias pacupg='yay -Syu'" \
    "alias pacupd='yay -Syy'" \
    "alias pacrem='yay -R'" \
    "alias pacins='yay -S'" \
    "alias pacinfo='yay -Si'" \
    "alias ubupg='sudo apt-get update && sudo apt-get upgrade'" \
    "alias srven='sudo systemctl enable'" \
    "alias srvdis='sudo systemctl disable'" \
    "alias srvstart='sudo systemctl start'" \
    "alias srvstop='sudo systemctl stop'" \
    "alias srvrest='sudo systemctl restart'" \
    "alias srvrel='sudo systemctl reload'" \
    "alias srvstat='systemctl status'" \
    "alias srvlist='systemctl list-unit-files --type=service'" \
    "alias grubupdarch='sudo grub-mkconfig -o /boot/grub/grub.cfg'" \
    "alias mkinitzen='sudo mkinitcpio -p linux-zen'" \
    "alias mkinit='sudo mkinitcpio -p linux'" \
    "alias ping='ping -c 5'" \
    "alias ln='ln -i'" \
    "alias chmod='chmod --preserve-root'" \
    "alias chgrp='chgrp --preserve-root'" \
    "alias wget='wget -c'" \
    "alias srchhist='history | grep'" \
    "alias startvnc='/usr/bin/x11vnc -auth guess -noxdamage -display :0 -rfbauth /etc/x11vnc.pwd -rfbport 5900'" \
    "alias mntgdrv='rclone mount mygoogledrive: ~/mygdrive --daemon'" \
    "alias sshtaichi='ssh -p 9282 lance@taichi'" \
    "alias sshrpi01='ssh -p 9284 lance@rpi3-01'" \
    "alias waketaichi='wol 70:85:C2:D3:E5:FA'" \
    "alias wakedan='wol 00:1e:37:cc:7e:76'" \
    "alias ssha='eval \$(ssh-agent) && ssh-add'" \
    "alias dehash='grep -Ev \"^#|^;|^\$\"'" \
    "alias df='df -h'" \
    "alias du='du -ch'" | \
    tee "$HOME/.config/bash/aliases" > /dev/null 2>&1 # && \
    # . "$HOME/.config/bash/aliases"  # This appears to only apply to this shell session. It does not persist once this script exits.
}

install_yay() {
    if [ -f "/usr/bin/pacman" ]; then
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
        tee "$HOME/.config/pacman/makepkg.conf" > /dev/null 2>&1
        sudo pacman -S --needed --noconfirm pigz pbzip2 go base-devel git
        cd "$HOME/build/sources" && git clone https://aur.archlinux.org/yay.git && \
        cd yay && \
        makepkg -si --noconfirm
        cd "$HOME" || exit
        echo "yay installed"
    fi
}

## TODO add GnuPG

xdg_move
add_path
# add_aliases  # This is handled by Ansible during setup
install_yay
