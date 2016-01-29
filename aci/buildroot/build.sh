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

# build
cd buildroot-2015.11.1
make oldconfig
make --quiet

# compress
cp output/images/rootfs.tar.gz $BASE_PATH/buildroot.tar.gz
