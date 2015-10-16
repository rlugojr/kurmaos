#!/bin/bash

BASE_PATH=`pwd`

set -e -x

gunzip kurmaos-disk-image/kurmaos-disk.img.gz
qemu-img convert -f raw kurmaos-disk-image/kurmaos-disk.img -O vmdk -o adapter_type=ide kurmaos.vmdk

kurmaos-source/packaging/lib/virtualbox_ovf.sh \
    --vm_name KurmaOS \
    --disk_vmdk kurmaos.vmdk \
    --memory_size 1024 \
    --output_ovf kurmaos.ovf

zip kurmaos.zip kurmaos.ovf kurmaos.vmdk
