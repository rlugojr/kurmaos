#!/bin/bash

export BASE_PATH=`pwd`

set -e -x

# calculate ldflags for the version number
version="$(git --git-dir=$BASE_PATH/kurma-source/.git describe --tags | cut -d'-' -f1)+git"
if [[ -f $BASE_PATH/version/number ]]; then
    version=$(cat $BASE_PATH/version/number)
fi
BUILD_LDFLAGS="-X github.com/apcera/kurma/stage1/client.version=$version"

# setup the gopath
mkdir -p go/src/github.com/apcera
ln -s $BASE_PATH/kurma-source go/src/github.com/apcera/kurma
export GOPATH="$BASE_PATH/go:$BASE_PATH/kurma-source/Godeps/_workspace"

mkdir rootfs
cd rootfs

# copy in the networking script
go build -a -o lo-plugin $BASE_PATH/go/src/github.com/apcera/kurma/networking/drivers/lo/main.go
mkdir -p opt/network
ln -s ../../lo-plugin opt/network/setup
ln -s ../../lo-plugin opt/network/add
ln -s ../../lo-plugin opt/network/del

# setup lib
mkdir lib
ln -s lib lib64

# copy needed dynamic libraries
LD_TRACE_LOADED_OBJECTS=1 ./lo-plugin | grep so | grep -v linux-vdso.so.1 \
    | sed -e '/^[^\t]/ d' \
    | sed -e 's/\t//' \
    | sed -e 's/.*=..//' \
    | sed -e 's/ (0.*)//' \
    | xargs -I % cp % lib/

# generate the aci
cd $BASE_PATH
acbuild --no-history begin
for i in $BASE_PATH/rootfs/* ; do
    j=$(basename $i)
    acbuild --no-history copy $i $j
done

acbuild --no-history label add os linux
acbuild --no-history label add arch amd64
acbuild --no-history label add version v$version

acbuild --no-history set-exec /opt/network/setup
acbuild --no-history set-user 0
acbuild --no-history set-group 0
acbuild --no-history set-name apcera.com/kurma/lo-netplugin

acbuild --no-history write --overwrite lo-netplugin.aci
acbuild --no-history end
