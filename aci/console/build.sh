#!/bin/bash

BASE_PATH=`pwd`

set -e -x

# setup for building go
mkdir -p go/src/github.com/apcera
ln -s $BASE_PATH/kurma-source go/src/github.com/apcera/kurma
export GOPATH="$BASE_PATH/go:$BASE_PATH/kurma-source/Godeps/_workspace"
TARGET=$BASE_PATH/go/src/github.com/apcera/kurma

# create the rootfs
mkdir rootfs
mkdir -p rootfs/bin rootfs/etc rootfs/lib rootfs/sbin rootfs/usr/bin

# configure and build the spawner
cp kurmaos-source/aci/console/spawn.json rootfs/etc/spawn.conf
cp kurmaos-source/aci/console/start.sh rootfs/start.sh
chown 0:0 rootfs/etc/spawn.conf rootfs/start.sh
chmod a+x rootfs/start.sh
go build -a -o rootfs/sbin/spawn apcera-util-source/spawn/spawn.go

# get kurma-cli
tar -xf kurma-cli-linux-amd64/kurma-cli-linux-amd64.tar.gz -C kurma-cli-linux-amd64
cp kurma-cli-linux-amd64/kurma-cli rootfs/usr/bin/kurma-cli

# create the halt/poweroff/reboot command handler for the container
gcc kurma-source/util/power/power.c -o rootfs/sbin/poweroff
ln -s poweroff rootfs/sbin/halt
ln -s poweroff rootfs/sbin/reboot

# copy cgpt
cp /usr/bin/cgpt rootfs/bin/cgpt

# create a symlink so the console can access kernel modules from the host
ln -s /host/proc/1/root/lib/firmware rootfs/lib/firmware
ln -s /host/proc/1/root/lib/modules rootfs/lib/modules

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
acbuild --no-history set-name apcera.com/kurma/console

depversion=$(go run kurmaos-source/aci/vergetter.go busybox-aci-image/busybox.aci)
dephash=$(shasum -a 512 busybox-aci-image/busybox.aci | cut -d" " -f1)
acbuild --no-history dependency add apcera.com/kurma/busybox --label version=$depversion --image-id="sha512-$dephash"

# add our custom isolators
acbuild --no-history isolator add host/privileged kurmaos-source/aci/console/isolator-true.json
acbuild --no-history isolator add host/api-access kurmaos-source/aci/console/isolator-true.json
acbuild --no-history isolator add os/linux/namespaces kurmaos-source/aci/console/isolator-namespaces.json

acbuild --no-history write --overwrite console.aci
acbuild --no-history end
