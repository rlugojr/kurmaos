#!/bin/bash

BASE_PATH=`pwd`

set -e -x

gunzip kurmaos-disk-image/kurmaos-disk.img.gz
qemu-img convert -f raw kurmaos-disk-image/kurmaos-disk.img -O vmdk -o adapter_type=lsilogic kurmaos.vmdk

cp kurmaos-source/packaging/disk-vmware/kurmaos.vmx kurmaos.vmx
zip kurmaos.zip kurmaos.vmx kurmaos.vmdk
