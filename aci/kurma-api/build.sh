#!/bin/bash

BASE_PATH=`pwd`

set -e -x

# calculate ldflags for the version number
BUILD_LDFLAGS=""
if [[ -f $BASE_PATH/version/number ]]; then
    BUILD_LDFLAGS="-X github.com/apcera/kurma/stage1/client.version=$(cat $BASE_PATH/version/number)"
fi

mkdir $BASE_PATH/rootfs

mkdir -p go/src/github.com/apcera
ln -s $BASE_PATH/kurma-source go/src/github.com/apcera/kurma
export GOPATH="$BASE_PATH/go:$BASE_PATH/kurma-source/Godeps/_workspace"
go build -ldflags "$BUILD_LDFLAGS" -a -o $BASE_PATH/rootfs/kurma-api go/src/github.com/apcera/kurma/kurma-api.go

cd $BASE_PATH/rootfs

# setup etc and lib folders
mkdir lib
ln -s lib lib64

# copy needed dynamic libraries
LD_TRACE_LOADED_OBJECTS=1 ./kurma-api | grep so | grep -v linux-vdso.so.1 \
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

acbuild set-exec /kurma-api
acbuild set-user 1000
acbuild set-group 1000
acbuild set-name apcera.com/kurma/api

# add our custom isolators
jq -c -s '.[0] * .[1]' .acbuild/currentaci/manifest kurmaos-source/aci/kurma-api/isolator.json > manifest
mv manifest .acbuild/currentaci/manifest

acbuild write --overwrite kurma-api.aci
acbuild end
