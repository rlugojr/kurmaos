#!/bin/bash

export BASE_PATH=`pwd`

set -e -x

mkdir rootfs
tar xzf buildroot-base/buildroot.tar.gz -C rootfs --exclude=./dev

# clean out some stuff
mkdir -p rootfs/dev
rm -rf rootfs/etc/ssl
rm -rf rootfs/usr/share/*
echo -n '' > rootfs/etc/hostname
echo -n '' > rootfs/etc/hosts
rm rootfs/etc/resolv.conf

# generate the aci
acbuild begin
for i in $BASE_PATH/rootfs/* ; do
    j=$(basename $i)
    acbuild copy $i $j
done

acbuild label add os linux
acbuild label add version latest

acbuild environment add PATH "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

acbuild set-exec /bin/sh
acbuild set-user 0
acbuild set-group 0
acbuild set-name apcera.com/kurma/buildroot

acbuild write --overwrite buildroot.aci
acbuild end
