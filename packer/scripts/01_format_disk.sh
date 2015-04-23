#!/bin/sh

set -e -x

# load the disk device driver
/sbin/modprobe mptspi

# make a partition on the disk
fdisk /dev/sda <<EOF
n
p
1


w
EOF

# format and mount
mkfs.ext4 /dev/sda1
mkdir -p /mnt/vm
mount /dev/sda1 /mnt/vm
