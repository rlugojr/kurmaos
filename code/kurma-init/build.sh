#!/bin/bash

BASE_PATH=`pwd`

set -e -x

# setup the gopath
mkdir -p go/src/github.com/apcera
ln -s $BASE_PATH/kurma-source go/src/github.com/apcera/kurma
export GOPATH="$BASE_PATH/go:$BASE_PATH/kurma-source/Godeps/_workspace"
TARGET=$BASE_PATH/go/src/github.com/apcera/kurma

# setup the root filesystem
mkdir root
cd root

# build kurma-init
go version
go build -o kurma $TARGET/kurma-init.go

# copy in the acis
cp $BASE_PATH/ntp-aci-image/ntp.aci ntp.aci
cp $BASE_PATH/udev-aci-image/udev.aci udev.aci
cp $BASE_PATH/console-aci-image/console.aci console.aci
cp $BASE_PATH/kurma-api-aci-image/kurma-api.aci kurma-api.aci

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

# cgpt has this weird hard coded path for a child cgpt
mkdir -p bin/old_bins
cp /usr/bin/old_bins/cgpt bin/old_bins/cgpt

# setup etc
mkdir -p etc/ssl/certs
cp $BASE_PATH/kurmaos-source/code/kurma-init/kurma.json etc/kurma.json
chown 0:0 etc/kurma.json
touch etc/resolv.conf
echo 'LSB_VERSION=1.4' > etc/lsb-release
echo 'DISTRIB_ID=KurmaOS' > etc/lsb-release
echo 'DISTRIB_RELEASE=rolling' > etc/lsb-release
echo 'DISTRIB_DESCRIPTION=KurmaOS' > etc/lsb-release

# copy kurma and needed dynamic libraries
mkdir -p lib
ln -s lib lib64
LD_TRACE_LOADED_OBJECTS=1 ./kurma | grep so | grep -v linux-vdso.so.1 \
    | sed -e '/^[^\t]/ d' \
    | sed -e 's/\t//' \
    | sed -e 's/.*=..//' \
    | sed -e 's/ (0.*)//' \
    | xargs -I % cp % lib/
LD_TRACE_LOADED_OBJECTS=1 ./bin/old_bins/cgpt | grep so | grep -v linux-vdso.so.1 \
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
cp /lib/libnss_dns-2.20.so lib/
cp /lib/libnss_files-2.20.so lib/
cp /lib/libresolv-2.20.so lib/
ln -s libnss_dns-2.20.so lib/libnss_dns.so.2
ln -s libnss_files-2.20.so lib/libnss_files.so.2
ln -s libresolv-2.20.so lib/libresolv.so.2

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
