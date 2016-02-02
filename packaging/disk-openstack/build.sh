#!/bin/bash

BASE_PATH=`pwd`

set -e -x

gunzip -k kurmaos-disk-image/kurmaos-disk.img.gz
qemu-img convert -f raw kurmaos-disk-image/kurmaos-disk.img -O qcow2 -o compat=0.10 kurmaos.img

# remove intermediate files to speed up concourse post-build ops
rm kurmaos-disk-image/kurmaos-disk.img

cp kurmaos-source/LICENSE .
zip kurmaos.zip LICENSE kurmaos.img
