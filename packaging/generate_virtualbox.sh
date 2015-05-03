#!/bin/sh

SCRIPT_ROOT=$(readlink -f $(dirname "$0"))
. "${SCRIPT_ROOT}/lib/common.sh" || exit 1

setup_chroot

mkdir -p ../output/images/virtualbox
touch ../output/images/virtualbox/virtualbox.vmdk
touch ../output/images/virtualbox/kurmaos.ovf

echo "Generating"
sudo chroot ./chroot /bin/bash <<EOF
source /etc/profile
cd kurmaos/packaging

qemu-img convert -f raw ../output/images/raw.img -O vmdk -o adapter_type=ide ../output/images/virtualbox/virtualbox.vmdk

./lib/virtualbox_ovf.sh \
  --vm_name KurmaOS \
  --disk_vmdk ../output/images/virtualbox/virtualbox.vmdk \
  --memory_size 1024 \
  --output_ovf ../output/images/virtualbox/kurmaos.ovf
EOF
