#!/bin/sh

set -e

SCRIPT_ROOT=$(readlink -f $(dirname "$0"))
. "${SCRIPT_ROOT}/lib/common.sh" || exit 1

setup_chroot

mkdir -p ../output/images
touch ../output/images/raw.img

echo "Building"
sudo chroot ./chroot /bin/bash <<EOF
source /etc/profile

cd kurmaos/packaging

./lib/disk_util --disk_layout=base format ../output/images/raw.img
./lib/disk_util --disk_layout=base mount ../output/images/raw.img /tmp/rootfs

tar xzf ../output/init-rapid.tar.gz -C /tmp/rootfs/boot

./lib/disk_util umount /tmp/rootfs

for target in i386-pc x86_64-efi x86_64-xen; do
    ./lib/grub_install.sh --target=\$target --disk_image=../output/images/raw.img
done
EOF
