#!/bin/bash

BASE_PATH=`pwd`

set -e -x

# calculate ldflags for the version number
version="$(git --git-dir=$BASE_PATH/kurma-source/.git describe --tags | cut -d'-' -f1)+git"
if [[ -f $BASE_PATH/version/number ]]; then
    version=$(cat $BASE_PATH/version/number)
fi
BUILD_LDFLAGS="-X github.com/apcera/kurma/stage1/client.version=$version"

# setup the gopath
if [[ ! -f go/src/github.com/apcera/kurma ]]; then
    mkdir -p go/src/github.com/apcera
    ln -s $BASE_PATH/kurma-source go/src/github.com/apcera/kurma
fi
export GOPATH="$BASE_PATH/go"
TARGET=$BASE_PATH/go/src/github.com/apcera/kurma

# setup the root filesystem
mkdir root
cd root

# build kurma-init
go version
go build -ldflags "$BUILD_LDFLAGS" -o kurma $TARGET/kurma-init.go

# copy in the acis
mkdir acis
cp $BASE_PATH/busybox-aci-image/busybox.aci acis/busybox.aci
cp $BASE_PATH/console-aci-image/console.aci acis/console.aci
cp $BASE_PATH/ntp-aci-image/ntp.aci acis/ntp.aci
cp $BASE_PATH/udev-aci-image/udev.aci acis/udev.aci
cp $BASE_PATH/kurma-api-aci-image/kurma-api.aci acis/kurma-api.aci
cp $BASE_PATH/lo-netplugin-aci-image/lo-netplugin.aci acis/lo-netplugin.aci
cp $BASE_PATH/cni-netplugin-aci-image/cni-netplugin.aci acis/cni-netplugin.aci

# configure the init script
ln -s kurma init

# copy the kernel modules
rsync -a /lib/modules lib/

# create bin directories
mkdir -p bin sbin
cp $BASE_PATH/kurmaos-source/code/kurma-init/resizefs.sh bin/resizefs
chmod a+x bin/resizefs

# copy busybox and setup necessary links
cp /bin/busybox bin/busybox
ln -s busybox bin/blockdev
ln -s busybox bin/cat
ln -s busybox bin/grep
ln -s busybox bin/mktemp
ln -s busybox bin/modprobe
ln -s busybox bin/ps
ln -s busybox bin/rm
ln -s busybox bin/sh
ln -s busybox bin/udhcpc

ln -s ../bin/busybox sbin/ifconfig
ln -s ../bin/busybox sbin/route

# udhcpc script
mkdir -p usr/share/udhcpc
cp /usr/share/udhcpc/default.script usr/share/udhcpc/default.script

# formatting tools
cp /sbin/mke2fs bin/mke2fs
ln -s mke2fs bin/mkfs.ext2
ln -s mke2fs bin/mkfs.ext3
ln -s mke2fs bin/mkfs.ext4
ln -s mke2fs bin/mkfs.ext4dev
cp /sbin/resize2fs bin/resize2fs
cp /usr/bin/cgpt bin/cgpt

# setup etc
mkdir -p etc/ssl/certs
cp $BASE_PATH/kurmaos-source/code/kurma-init/kurma.json etc/kurma.json
chown 0:0 etc/kurma.json
touch etc/mtab
touch etc/resolv.conf
echo "LSB_VERSION=1.4" > etc/lsb-release
echo "DISTRIB_ID=KurmaOS" >> etc/lsb-release
echo "DISTRIB_RELEASE=rolling" >> etc/lsb-release
echo "DISTRIB_DESCRIPTION=KurmaOS" >> etc/lsb-release
echo "NAME=KurmaOS" > etc/os-release
echo "VERSION=$version" >> etc/os-release
echo "ID=kurmaos" >> etc/os-release
echo "PRETTY_NAME=KurmaOS v$version" >> etc/os-release

# copy kurma and needed dynamic libraries
mkdir -p lib
ln -s lib lib64
LD_TRACE_LOADED_OBJECTS=1 ./kurma | grep so | grep -v linux-vdso.so.1 \
    | sed -e '/^[^\t]/ d' \
    | sed -e 's/\t//' \
    | sed -e 's/.*=..//' \
    | sed -e 's/ (0.*)//' \
    | xargs -I % cp % lib/
LD_TRACE_LOADED_OBJECTS=1 ./bin/resize2fs | grep so | grep -v linux-vdso.so.1 \
    | sed -e '/^[^\t]/ d' \
    | sed -e 's/\t//' \
    | sed -e 's/.*=..//' \
    | sed -e 's/ (0.*)//' \
    | xargs -I % cp % lib/

# copy libnss so it can do dns
cp /etc/nsswitch.conf etc/
cp /lib/libc.so.6 lib/
cp /lib/ld-linux-x86-64.so.2 lib/
cp /lib/libnss_dns-*.so lib/
cp /lib/libnss_files-*.so lib/
cp /lib/libresolv-*.so lib/

# generate ld.so.cache
echo "/lib" > etc/ld.so.conf
ldconfig -r . -C etc/ld.so.cache -f etc/ld.so.conf

# Figure the compresison command
: "${INITRD_COMPRESSION:=gzip}"
compressCommand=""
if [ "$INITRD_COMPRESSION" == "gzip" ]; then
  compressCommand="gzip"
elif [ "$INITRD_COMPRESSION" == "lzma" ]; then
  compressCommand="lzma"
else
  echo "Unrecognized compression setting!"
  exit 1
fi

# package it up
find . | cpio --quiet -o -H newc | $compressCommand > $BASE_PATH/initrd
cd $BASE_PATH
cp /boot/bzImage .
tar -czf kurma-init.tar.gz bzImage initrd
