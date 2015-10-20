#!/bin/bash

BASE_PATH=`pwd`

set -e -x

gunzip -k kurmaos-disk-image/kurmaos-disk.img.gz
qemu-img convert -f raw kurmaos-disk-image/kurmaos-disk.img -O vmdk -o adapter_type=lsilogic kurmaos.vmdk

cp kurmaos-source/packaging/disk-vmware/kurmaos.vmx kurmaos.vmx
cp kurmaos-source/LICENSE LICENSE
zip kurmaos.zip LICENSE kurmaos.vmx kurmaos.vmdk
