#!/bin/bash

BASE_PATH=`pwd`

set -e -x

function containers_gone_wild() {
  mkdir /tmp/devices-cgroup
  mount -t cgroup -o devices none /tmp/devices-cgroup

  echo 'a' > /tmp/devices-cgroup/instance-$(hostname)/devices.allow

  # create loopback devices
  for i in $(seq 64 67); do
    mknod -m 0660 /dev/loop$i b 7 $i
  done
}

function salt_earth() {
  for i in $(seq 64 67); do
    losetup -d /dev/loop$i > /dev/null 2>&1 || true
  done
}

if ! ls -1 /dev/loop* ; then
    containers_gone_wild
    trap salt_earth EXIT
fi

# calculate ldflags for the version number
version="$(git --git-dir=$BASE_PATH/kurma-source/.git describe --tags | cut -d'-' -f1)+git"
if [[ -f $BASE_PATH/version/number ]]; then
    version=$(cat $BASE_PATH/version/number)
fi

gunzip -k kurmaos-disk-image/kurmaos-disk.img.gz

# Mount the disk and copy in the OEM grub.cfg
cd kurmaos-source/packaging
./lib/disk_util --disk_layout=base mount $BASE_PATH/kurmaos-disk-image/kurmaos-disk.img /tmp/rootfs
cp $BASE_PATH/kurmaos-source/packaging/disk-aws/oem-grub.cfg /tmp/rootfs/boot/oem/grub.cfg
./lib/disk_util umount /tmp/rootfs

# Import the image into AWS
cd $BASE_PATH/kurmaos-source/packaging/disk-aws
./import.sh -B kurmaos-temp-disk-images \
            -p $BASE_PATH/kurmaos-disk-image/kurmaos-disk.img \
            -V $version \
            -Z us-west-2a | tee $BASE_PATH/instances.txt

# remove intermediate files to speed up concourse post-build ops
rm $BASE_PATH/kurmaos-disk-image/kurmaos-disk.img
