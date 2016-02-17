#!/bin/bash

BASE_PATH=`pwd`
INSTALLPATH=$BASE_PATH/rootfs
set -e -x

# download buildroot
wget https://buildroot.org/downloads/buildroot-2015.11.1.tar.gz
tar -xf buildroot-2015.11.1.tar.gz

# setup config files
cp kurmaos-source/aci/buildroot/buildroot.config buildroot-2015.11.1/.config
cp kurmaos-source/aci/buildroot/busybox.config buildroot-2015.11.1/busybox.config

# copy in glibc patches
mkdir -p buildroot-2015.11.1/package/glibc/2.21
cp kurmaos-source/aci/buildroot/patches/glibc/*.patch buildroot-2015.11.1/package/glibc/2.21/

# build
cd buildroot-2015.11.1
make oldconfig
make --quiet

# compress
cp output/images/rootfs.tar.gz $BASE_PATH/buildroot.tar.gz
