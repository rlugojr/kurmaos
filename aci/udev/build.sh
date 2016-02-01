#!/bin/bash

export BASE_PATH=`pwd`

set -e -x

mkdir rootfs
cd rootfs

# copy in the startup script
cp $BASE_PATH/kurmaos-source/aci/udev/start.sh .
chown 0:0 start.sh
chmod a+x start.sh

# copy in busybox and udev
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

# create a symlink so the udev can access kernel modules from the host
ln -s /host/proc/1/root/lib/modules lib/modules
ln -s /host/proc/1/root/lib/firmware lib/firmware

# update the hardware db
udevadm hwdb --update --root=`pwd`

# generate the aci
cd $BASE_PATH
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

acbuild --no-history set-exec /start.sh
acbuild --no-history set-user 0
acbuild --no-history set-group 0
acbuild --no-history set-name apcera.com/kurma/udev

# add our custom isolators
acbuild --no-history isolator add host/privileged kurmaos-source/aci/udev/isolator-true.json
acbuild --no-history isolator add os/linux/namespaces kurmaos-source/aci/udev/isolator-namespaces.json

acbuild --no-history write --overwrite udev.aci
acbuild --no-history end
