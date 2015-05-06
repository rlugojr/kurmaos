#!/bin/sh

SCRIPT_ROOT=$(readlink -f $(dirname "$0"))
. "${SCRIPT_ROOT}/lib/common.sh" || exit 1

setup_chroot

mkdir -p ../output/images/openstack
touch ../output/images/openstack/kurmaos.img

echo "Generating"
sudo chroot ./chroot /bin/bash <<EOF
source /etc/profile
cd kurmaos/packaging
qemu-img convert -f raw ../output/images/raw.img -O qcow2 -o compat=0.10 ../output/images/openstack/kurmaos.img
EOF
