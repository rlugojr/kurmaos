#!/bin/bash

export BASE_PATH=`pwd`

set -e -x

emerge-webrsync
emerge eudev

mkdir rootfs
cd rootfs

# copy in the startup script
cp $BASE_PATH/kurmaos-source/aci/eudev/start.sh .
chown 0:0 start.sh
chmod a+x start.sh

# copy in busybox and eudev
mkdir bin
cp /bin/busybox bin/
ln -s busybox bin/sh
cp /sbin/udevd bin/
cp /sbin/udevadm bin/

# setup etc and lib folders
mkdir etc lib run
ln -s lib lib64
echo "127.0.0.1 localhost localhost.localdomain" > etc/hosts

# copy the udev rules
cp -r /lib/udev lib/

# setup some of our own
mkdir -p etc/udev/rules.d
touch etc/udev/rules.d/80-net-name-slot.rules
ln -s /lib/udev/hwdb.d etc/udev/hwdb.d

# copy dynamic libraries
LD_TRACE_LOADED_OBJECTS=1 ./bin/udevd | grep so | grep -v linux-vdso.so.1 \
    | sed -e '/^[^\t]/ d' \
    | sed -e 's/\t//' \
    | sed -e 's/.*=..//' \
    | sed -e 's/ (0.*)//' \
    | xargs -I % cp % lib/
LD_TRACE_LOADED_OBJECTS=1 ./bin/udevadm | grep so | grep -v linux-vdso.so.1 \
    | sed -e '/^[^\t]/ d' \
    | sed -e 's/\t//' \
    | sed -e 's/.*=..//' \
    | sed -e 's/ (0.*)//' \
    | xargs -I % cp % lib/

# generate ld.so.cache
echo "/lib" > etc/ld.so.conf
ldconfig -r . -C etc/ld.so.cache -f etc/ld.so.conf

# create a symlink so the console can access kernel modules from the host
ln -s /host/proc/1/root/lib/modules lib/modules
ln -s /host/proc/1/root/lib/firmware lib/firmware

# generate the aci
cd $BASE_PATH
acbuild begin
for i in $BASE_PATH/rootfs/* ; do
    j=$(basename $i)
    acbuild copy $i $j
done

acbuild label add os linux
acbuild label add version latest

acbuild environment add PATH "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

acbuild set-exec /start.sh
acbuild set-user 0
acbuild set-group 0
acbuild set-name apcera.com/kurma/udev

# add our custom isolators
jq -c -s '.[0] * .[1]' .acbuild/currentaci/manifest kurmaos-source/aci/udev/isolator.json > manifest
mv manifest .acbuild/currentaci/manifest

acbuild write --overwrite udev.aci
acbuild end
