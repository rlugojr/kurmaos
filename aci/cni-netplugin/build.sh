#!/bin/bash

export BASE_PATH=`pwd`

set -e -x

# compile the cni binaries
cd appc-cni-source
version=$(git describe --tags)
./build

mkdir $BASE_PATH/rootfs
cd $BASE_PATH/rootfs

# copy in cni binaries
mkdir -p usr/bin
cp $BASE_PATH/appc-cni-source/bin/* usr/bin/
# except cnitool
rm usr/bin/cnitool

# copy in the networking script
mkdir -p opt/network
cp $BASE_PATH/kurmaos-source/aci/cni-netplugin/setup.sh opt/network/setup
cp $BASE_PATH/kurmaos-source/aci/cni-netplugin/add.sh opt/network/add
cp $BASE_PATH/kurmaos-source/aci/cni-netplugin/del.sh opt/network/del
chown 0:0 opt/network/*
chmod a+x opt/network/*

# generate the aci
cd $BASE_PATH
acbuild --no-history begin
for i in $BASE_PATH/rootfs/* ; do
    j=$(basename $i)
    acbuild --no-history copy $i $j
done

acbuild --no-history label add os linux
acbuild --no-history label add arch amd64
acbuild --no-history label add version $version

acbuild --no-history set-name apcera.com/kurma/cni-netplugin

depversion=$(go run kurmaos-source/aci/vergetter.go busybox-aci-image/busybox.aci)
dephash=$(shasum -a 512 busybox-aci-image/busybox.aci | cut -d" " -f1)
acbuild --no-history dependency add apcera.com/kurma/busybox --label version=$depversion --image-id="sha512-$dephash"

acbuild --no-history write --overwrite cni-netplugin.aci
acbuild --no-history end
