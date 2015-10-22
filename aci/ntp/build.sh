#!/bin/bash

export BASE_PATH=`pwd`

set -e -x

mkdir rootfs
cd rootfs

# copy in the startup script
cp $BASE_PATH/kurmaos-source/aci/ntp/start.sh .
chown 0:0 start.sh
chmod a+x start.sh

# copy in busybox
cp /bin/busybox .
ln -s busybox sh
ln -s busybox ntpd

# setup etc and lib folders
mkdir etc lib
ln -s lib lib64
echo "127.0.0.1 localhost localhost.localdomain" > etc/hosts

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

# generate the aci
cd $BASE_PATH
acbuild begin
for i in $BASE_PATH/rootfs/* ; do
    j=$(basename $i)
    acbuild copy $i $j
done

acbuild label add os linux
acbuild label add version latest

acbuild set-exec /start.sh
acbuild set-user 0
acbuild set-group 0
acbuild set-name apcera.com/kurma/ntp

# add our custom isolators
jq -c -s '.[0] * .[1]' .acbuild/currentaci/manifest kurmaos-source/aci/ntp/isolator.json > manifest
mv manifest .acbuild/currentaci/manifest

acbuild write --overwrite ntp.aci
acbuild end
