#!/bin/sh

SCRIPT_ROOT=$(readlink -f $(dirname "$0"))
. "${SCRIPT_ROOT}/common.sh" || exit 1

function umount() {
    echo "Cleaning up"
    mount | grep "`pwd`/chroot" | awk '{print $3}' | sort -r | xargs -n1 sudo umount
}

if [ ! -d ./chroot ]; then
    echo "Setting up the chroot"
    mkdir chroot
    unzip -p ../output/kurmaos-stage3.cntmp PACKAGE_RESOURCE_0001.tar.gz | sudo tar xj -C chroot
    unzip -p ../output/kurmaos-gentoo-stage4.cntmp PACKAGE_RESOURCE_0001.tar.gz | sudo tar xz -C chroot
fi


echo "Bind mounting..."
sudo mkdir -p ./chroot/kurmaos ./chroot/proc ./chroot/sys ./chroot/dev
sudo mount -t proc proc ./chroot/proc
sudo mount --rbind /sys ./chroot/sys
sudo mount --make-rslave ./chroot/sys
sudo mount --rbind /dev ./chroot/dev
sudo mount --make-rslave ./chroot/dev
sudo mount --bind ../ ./chroot/kurmaos
sudo mount -t tmpfs none ./chroot/tmp
fix_mtab "./chroot"

trap umount EXIT

touch raw.img

echo "Building"
sudo chroot ./chroot /bin/bash <<EOF
source /etc/profile

cd kurmaos/packaging

./disk_util --disk_layout=base format raw.img
./disk_util --disk_layout=base mount raw.img /tmp/rootfs

tar xzf ../output/init-rapid.tar.gz -C /tmp/rootfs/boot

./disk_util umount /tmp/rootfs

for target in i386-pc x86_64-efi x86_64-xen; do
    ./grub_install.sh --target=\$target --disk_image=raw.img
done
EOF
