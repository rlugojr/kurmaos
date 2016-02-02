#!/bin/bash

BASE_PATH=`pwd`

set -e -x

gunzip -k kurmaos-disk-image/kurmaos-disk.img.gz
qemu-img convert -f raw kurmaos-disk-image/kurmaos-disk.img -O vmdk -o adapter_type=ide kurmaos.vmdk

# remove intermediate files to speed up concourse post-build ops
rm kurmaos-disk-image/kurmaos-disk.img

kurmaos-source/packaging/lib/virtualbox_ovf.sh \
    --vm_name KurmaOS \
    --disk_vmdk kurmaos.vmdk \
    --memory_size 1024 \
    --output_ovf kurmaos.ovf

cp kurmaos-source/LICENSE .
zip kurmaos.zip LICENSE kurmaos.ovf kurmaos.vmdk
