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
mkdir -p rootfs/bin/old_bins
cp /usr/bin/old_bins/cgpt rootfs/bin/old_bins/cgpt

# create a symlink so the console can access kernel modules from the host
ln -s /host/proc/1/rootfs/lib/firmware rootfs/lib/firmware
ln -s /host/proc/1/rootfs/lib/modules rootfs/lib/modules

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
acbuild set-name apcera.com/kurma/console

acbuild dependency add apcera.com/kurma/buildroot --image-id="sha512-$(shasum -a 512 buildroot-aci-image/buildroot.aci | cut -d" " -f1)"

# add our custom isolators
jq -c -s '.[0] * .[1]' .acbuild/currentaci/manifest kurmaos-source/aci/console/isolator.json > manifest
mv manifest .acbuild/currentaci/manifest

acbuild write --overwrite console.aci
acbuild end
