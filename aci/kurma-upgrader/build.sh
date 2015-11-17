#!/bin/bash

export BASE_PATH=`pwd`

set -e -x

mkdir $BASE_PATH/rootfs

mkdir -p go/src/github.com/apcera
ln -s $BASE_PATH/kurma-source go/src/github.com/apcera/kurma
export GOPATH="$BASE_PATH/go:$BASE_PATH/kurma-source/Godeps/_workspace"
go build -a -o $BASE_PATH/rootfs/kurma-upgrader go/src/github.com/apcera/kurma/util/installer/installer.go

cd $BASE_PATH/rootfs

# extract new kernel
tar -xf $BASE_PATH/kurma-init-build/kurma-init.tar.gz

# copy bins
cp /usr/bin/cgpt .
mkdir -p old_bins
cp /usr/bin/old_bins/cgpt old_bins/cgpt
cp /usr/sbin/kexec .

# setup etc and lib folders
mkdir lib
ln -s lib lib64

# copy needed dynamic libraries
LD_TRACE_LOADED_OBJECTS=1 ./kurma-upgrader | grep so | grep -v linux-vdso.so.1 \
    | sed -e '/^[^\t]/ d' \
    | sed -e 's/\t//' \
    | sed -e 's/.*=..//' \
    | sed -e 's/ (0.*)//' \
    | xargs -I % cp % lib/
LD_TRACE_LOADED_OBJECTS=1 ./kexec | grep so | grep -v linux-vdso.so.1 \
    | sed -e '/^[^\t]/ d' \
    | sed -e 's/\t//' \
    | sed -e 's/.*=..//' \
    | sed -e 's/ (0.*)//' \
    | xargs -I % cp % lib/

# generate the aci
cd $BASE_PATH
acbuild begin
for i in $BASE_PATH/rootfs/* ; do
    j=$(basename $i)
    acbuild copy $i $j
done

acbuild label add os linux
acbuild label add version latest

acbuild set-exec /kurma-upgrader
acbuild set-user 0
acbuild set-group 0
acbuild set-name apcera.com/kurma/upgrader

# add our custom isolators
jq -c -s '.[0] * .[1]' .acbuild/currentaci/manifest kurmaos-source/aci/kurma-upgrader/isolator.json > manifest
mv manifest .acbuild/currentaci/manifest

acbuild write --overwrite kurma-upgrader.aci
acbuild end
