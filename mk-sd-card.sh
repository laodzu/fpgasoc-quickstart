#!/bin/bash
#
# Setup SD card for SoCrates EBV training
#
# See ChangeLog for changes
# 
# (C) 2013-2015 by Detlev Zundel, <detlev.zundel@ebv.com> EBV Elektronik GmbH & Co KG

MNT=/tmp/sd-card-$$

usage() {
    echo "usage: $0 [device]" >&2
    echo "       device - block device file of sd-card" >&2
    echo "                (e.g. /dev/sdb or /dev/mmcblk0)" >&2
}

part_size() {
    filename=`basename $1`
    set -- `cat /proc/partitions | grep $filename\$`
    echo $3
}

ensure_unmounted() {
    if mount | grep -q $1 ; then
	if ! umount $1 ; then
	    echo "Failed to unmount $1 - exiting" 1>&2
	    exit 2
	fi
    fi
}

if [ $# -lt 1 ]; then
    usage
    exit 1
fi

DEV=$1
DEV_SIZE=`part_size $DEV`

if [ -z `part_size $DEV` ]; then
    echo "$0: device $DEV does not exist - exiting"
    exit 1
fi

if [ `id -u` = 0 ]; then
    SUDO=""
else
    SUDO="sudo"
fi

echo "Using $DEV with $(( $DEV_SIZE / 1024 )) MiB"

if [ $DEV_SIZE -gt $(( 8 * 1024 * 1024 )) ]; then
    echo "Warning - device is larger than 8 GiB - really make sure it is the right device!"
fi

if [ "${DEV:0:7}" = "/dev/sd" ]; then
    PART1=${DEV}1
    PART2=${DEV}2
elif [ "${DEV:0:11}" = "/dev/mmcblk" ]; then
    PART1=${DEV}p1
    PART2=${DEV}p2
else
    echo "Unknown device naming scheme"
    exit 1
fi

ensure_unmounted $PART1
ensure_unmounted $PART2

echo "Warning, we are going to overwrite ${DEV}!"
echo -n "Are you really sure (y/n)? "

read ANS

if [ "$ANS" != "y" ] ; then
    exit 1
fi

if [ ! -d $MNT ]; then
    echo "Mountpoint \"$MNT\" does not exist - creating it"
    ${SUDO} mkdir $MNT
fi

# Setup partition scheme
echo "Creating partition table with two partitions"
echo " $PART1 - Preloader / U-Boot"
echo " $PART2 - ext3 root filesystem"

sudo sfdisk ${DEV} <<EOF
,1M,a2
,,L
EOF
sync

echo "Writing environment variables"
${SUDO} dd if=u-boot-env.img of=${DEV} bs=1 seek=512

echo "Writing preloader copies"
${SUDO} dd if=preloader-mkpimage.bin of=${PART1}

echo "Writing U-Boot"
${SUDO} dd if=u-boot.img of=${PART1} bs=64k seek=4

echo "Creating filesystems on ${PART2}"
${SUDO} mkfs.ext3 -F ${PART2}

echo "Unpacking rootfs-socrates to ${PART2}"
${SUDO} mount ${PART2} $MNT
OPWD=`pwd`
cd $MNT
${SUDO} tar xf $OPWD/rootfs-socrates.tar.gz

echo "Copying kernel to ${PART2}"
[ ! -d boot ] && ${SUDO} mkdir boot
cd boot
${SUDO} cp $OPWD/uImage .
${SUDO} cp $OPWD/vmlinux .
${SUDO} cp $OPWD/*.dtb .
${SUDO} cp $OPWD/*.rbf .
${SUDO} cp $OPWD/adjust-env.scr .
# Remove udev association of mac address to interface name
${SUDO} rm -f etc/udev/rules.d/70-persistent-net.rules
cd $OPWD
${SUDO} umount $MNT
