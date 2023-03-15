#! /usr/bin/bash

function print_usage() {
    echo "usage: $0 <VM name>"
    echo "Current VM names are: arch archbase endeavoros gaming mint mythboxtest popos work"
}

# do not run as root
if [[ $EUID -eq 0 ]]; then
    echo "This script is not supposed to be run as root." >&2
    exit 1
fi

# parse command line arguments
if [[ -z $1 ]]; then
    print_usage
    exit 1
else
    VM_NAME="$1"
fi

# declare variables
BRIDGE="br0"
VDISKDIR="/mnt/data0/vdisks"
ISODIR="/mnt/data0/iso"
VARSDIR="$HOME/ovmf_vars"
WEBCAM='-device usb-host,vendorid=0x0c45,productid=0x6536'
SMARTCARD='-device usb-host,vendorid=0x04e6,productid=0xe001'
VIRTIOISO="-drive file=$ISODIR/virtio-win-0.1.225.iso,index=2,media=cdrom,readonly=on"
NETBOOTISO="file=$ISODIR/netboot.xyz.iso,index=1,media=cdrom,readonly=on"
UBUNTUSRVISO="file=$ISODIR/jammy-live-server-amd64.iso,index=1,media=cdrom,readonly=on"
AUTOINSTALLISO="file=$ISODIR/jammy-autoinstall.iso,index=1,media=cdrom,readonly=on"
ARCHISO="file=$ISODIR/archlinux-2022.12.01-x86_64.iso,index=1,media=cdrom,readonly=on"
RESCUEISO="file=$ISODIR/rescuezilla-2.3.1-64bit.impish.iso,index=1,media=cdrom,readonly=on"
NIC2="-netdev bridge,br=br1,id=hn1 -device virtio-net-pci,netdev=hn1,id=nic1,mac=02:00:00:00:00:01"

case "$VM_NAME" in
    arch)
        MACADDR="02:00:00:00:01:09"
        MEM="8G"
        DRV1="file=$VDISKDIR/$VM_NAME.qcow2,format=qcow2,index=0,media=disk,if=virtio,cache=none"
        ISO1="$ARCHISO"
        EXTRAS=""
    ;;
    archbase)
        MACADDR="02:00:00:00:01:09"
        MEM="8G"
        DRV1="file=$VDISKDIR/$VM_NAME.qcow2,format=qcow2,index=0,media=disk,if=virtio,cache=none"
        ISO1="$ARCHISO"
        EXTRAS=""
    ;;
    autoinstall)
        MACADDR="02:00:00:00:00:00"
        MEM="8G"
        DRV1="file=$VDISKDIR/$VM_NAME.qcow2,format=qcow2,index=0,media=disk,if=virtio,cache=none"
        ISO1="$AUTOINSTALLISO"
        EXTRAS=""
    ;;
    endeavoros)
        MACADDR="02:00:00:00:01:10"
        MEM="8G"
        DRV1="file=$VDISKDIR/$VM_NAME.qcow2,format=qcow2,index=0,media=disk,if=virtio,cache=none"
        ISO1="$NETBOOTISO"
        EXTRAS=
    ;;
    mint)
        MACADDR="02:00:00:00:01:02"
        MEM="8G"
        DRV1="file=$VDISKDIR/$VM_NAME.img,format=raw,index=0,media=disk,if=virtio,cache=none"
        ISO1="file=$ISODIR/linuxmint.iso,index=1,media=cdrom,readonly=on"
        EXTRAS=""
    ;;
    mythbox)
        MACADDR="02:00:00:00:00:00"
        MEM="8G"
        DRV1="file=$VDISKDIR/$VM_NAME.qcow2,format=qcow2,index=0,media=disk,if=virtio,cache=none"
        ISO1="$UBUNTUSRVISO"
        EXTRAS="-snapshot"
    ;;
    popos)
        MACADDR="02:00:00:00:01:01"
        MEM="8G"
        DRV1="file=$VDISKDIR/$VM_NAME.qcow2,format=qcow2,index=0,media=disk,if=virtio,cache=none"
        ISO1="file=$ISODIR/pop-os_22.04_amd64_intel_12.iso,index=1,media=cdrom,readonly=on"
        EXTRAS=""
    ;;
    work)
        MACADDR="02:00:00:00:01:03"
        MEM="8G"
        DRV1="file=$VDISKDIR/$VM_NAME.img,format=raw,index=0,media=disk,if=virtio,cache=none"
        ISO1="file=$ISODIR/Win10_1909_English_x64.iso,index=1,media=cdrom,readonly=on"
        EXTRAS="$SMARTCARD $WEBCAM $VIRTIOISO"
    ;;
    gaming)
        MACADDR="02:00:00:00:01:03"
        MEM="8G"
        DRV1="file=/dev/disk/by-id/ata-PNY_CS900_240GB_SSD_PNY22202005260101CBB,format=raw,media=disk"
        ISO1="file=$ISODIR/Win10_1909_English_x64.iso,index=1,media=cdrom,readonly=on"
        EXTRAS="$VIRTIOISO"
    ;;
    *)
        echo "Unknown VM name specified: $VM_NAME" >&2
        exit 1
    ;;
esac

# create bridge if it doesn't already exist
if [ -z "$(ip link show | grep $BRIDGE)" ] ; then
    echo "Creating bridge"
    ROUTER="192.168.40.1"
    SUBNET="192.168.40."
    NIC=$(ip link show | grep eno | grep 'state UP' | head -n 1 | cut -d":" -f 2 | xargs)
    echo "on $NIC"
    IPADDR=$(ip addr show | grep -o "inet $SUBNET\([0-9]*\)" | cut -d ' ' -f2)
    echo "at address $IPADDR"
    sudo ip addr del "$IPADDR"/24 dev "$NIC"
    echo "Deleted IP address $IPADDR from $NIC"
    sudo ip link add name $BRIDGE type bridge &> /dev/null
    echo "Created bridge $BRIDGE"
    sudo ip link set $BRIDGE up
    echo "Started bridge $BRIDGE"
    sudo ip link set "$NIC" master $BRIDGE
    echo "$NIC attached to $BRIDGE"
    sudo ip addr add "$IPADDR"/24 brd + dev $BRIDGE
    echo "IP address $IPADDR assigned to $BRIDGE"
    sudo ip route add default via $ROUTER dev $BRIDGE
    echo "Traffic routed through bridge by default"
    if [ -z "$(ip link show | grep $BRIDGE)" ] ; then
        echo "Unable to create $BRIDGE. Exiting." >&2
        exit 1
    fi
fi

echo "Starting $VM_NAME virtual machine at $MACADDR"
qemu-system-x86_64 \
    -name "$VM_NAME" \
    -drive if=pflash,format=raw,unit=1,file="$VARSDIR"/"$VM_NAME"_VARS.fd \
    -cpu host,hv_relaxed,hv_spinlocks=0x1fff,hv_vapic,hv_time \
    -smp "$(nproc)" \
    -machine type=q35,accel=kvm \
    -drive if=pflash,format=raw,unit=0,readonly=on,file=/usr/share/ovmf/x64/OVMF_CODE.fd \
    -usb \
    -device usb-tablet \
    -device qemu-xhci,id=xhci \
    -device intel-hda -device hda-duplex,audiodev=pa \
    -audiodev id=pa,driver=pa,timer-period=10101,in.frequency=48000,in.buffer-length=85333,out.frequency=48000,out.buffer-length=85333,server="$(pactl info | grep 'Server String' | awk '{print $3}')" \
    -device virtio-vga \
    -netdev tap,id=hn0,br=br0,helper=/usr/lib/qemu/qemu-bridge-helper -device virtio-net-pci,netdev=hn0,id=nic0,mac=$MACADDR \
    -m $MEM \
    -drive "$DRV1" \
    -drive "$ISO1" \
    $EXTRAS


# -no-reboot -smbios type=1,serial=ds=nocloud-net;s=http://192.168.40.5:3003/
