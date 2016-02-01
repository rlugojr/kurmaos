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
cp /lib/libnss_dns-*.so lib/
cp /lib/libnss_files-*.so lib/
cp /lib/libresolv-*.so lib/

# generate ld.so.cache
echo "/lib" > etc/ld.so.conf
ldconfig -r . -C etc/ld.so.cache -f etc/ld.so.conf

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

acbuild --no-history set-exec /start.sh
acbuild --no-history set-user 0
acbuild --no-history set-group 0
acbuild --no-history set-name apcera.com/kurma/ntp

# add our custom isolators
acbuild --no-history isolator add host/privileged kurmaos-source/aci/ntp/isolator-true.json
acbuild --no-history isolator add os/linux/namespaces kurmaos-source/aci/ntp/isolator-namespaces.json

acbuild --no-history write --overwrite ntp.aci
acbuild --no-history end
