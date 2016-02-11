#!/bin/bash

export BASE_PATH=`pwd`

set -e -x

mkdir rootfs
tar xzf buildroot-base/buildroot.tar.gz -C rootfs --exclude=./dev

# clean out some stuff
mkdir -p rootfs/dev
echo -n '' > rootfs/etc/hostname
echo -n '' > rootfs/etc/hosts
rm rootfs/etc/resolv.conf

# generate the aci
acbuild --no-history begin
for i in $BASE_PATH/rootfs/* ; do
    j=$(basename $i)
    acbuild --no-history copy $i $j
done

version=$(date +%Y.%m.%d-`cd kurmaos-source && git rev-parse HEAD | cut -c1-8`)
acbuild --no-history label add os linux
acbuild --no-history label add arch amd64
acbuild --no-history label add version v$version

acbuild --no-history environment add PATH "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

acbuild --no-history set-exec /bin/sh
acbuild --no-history set-user 0
acbuild --no-history set-group 0
acbuild --no-history set-name apcera.com/kurma/busybox

acbuild --no-history write --overwrite busybox.aci
acbuild --no-history end
