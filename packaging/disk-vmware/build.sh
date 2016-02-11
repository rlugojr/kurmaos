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

gunzip -k kurmaos-disk-image/kurmaos-disk.img.gz

# Mount the disk and copy in the OEM grub.cfg
cd kurmaos-source/packaging
./lib/disk_util --disk_layout=base mount $BASE_PATH/kurmaos-disk-image/kurmaos-disk.img /tmp/rootfs
cp $BASE_PATH/kurmaos-source/packaging/disk-vmware/oem-grub.cfg /tmp/rootfs/boot/oem/grub.cfg
./lib/disk_util umount /tmp/rootfs

# Convert the image
cd $BASE_PATH
qemu-img convert -f raw kurmaos-disk-image/kurmaos-disk.img -O vmdk -o adapter_type=lsilogic kurmaos.vmdk

# remove intermediate files to speed up concourse post-build ops
rm kurmaos-disk-image/kurmaos-disk.img

# Package it up
cp kurmaos-source/packaging/disk-vmware/kurmaos.vmx kurmaos.vmx
cp kurmaos-source/LICENSE LICENSE
zip kurmaos.zip LICENSE kurmaos.vmx kurmaos.vmdk
