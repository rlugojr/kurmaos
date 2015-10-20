#!/bin/bash

BASE_PATH=`pwd`

set -e -x

# wire up virtualbox capabilities
function containers_gone_wild() {
  # disabled while we've switched to garden-systemd
  # # permit usage of vboxdrv node by tacking it into our own cgroup
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

cd kurmaos-source/packaging

# Create and mount the disk
./lib/disk_util --disk_layout=base format $BASE_PATH/raw.img
./lib/disk_util --disk_layout=base mount $BASE_PATH/raw.img /tmp/rootfs

tar -xf $BASE_PATH/kurma-init-build/kurma-init.tar.gz -C /tmp/rootfs/boot

./lib/disk_util umount /tmp/rootfs

for target in i386-pc x86_64-efi x86_64-xen; do
    ./lib/grub_install.sh --target=$target --disk_image=$BASE_PATH/raw.img
done

cd $BASE_PATH
gzip raw.img
