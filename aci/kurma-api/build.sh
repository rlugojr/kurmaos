#!/bin/bash

BASE_PATH=`pwd`

set -e -x

# calculate ldflags for the version number
version="$(git --git-dir=$BASE_PATH/kurma-source/.git describe --tags | cut -d'-' -f1)+git"
if [[ -f $BASE_PATH/version/number ]]; then
    version=$(cat $BASE_PATH/version/number)
fi
BUILD_LDFLAGS="-X github.com/apcera/kurma/stage1/client.version=$version"

mkdir $BASE_PATH/rootfs

mkdir -p go/src/github.com/apcera
ln -s $BASE_PATH/kurma-source go/src/github.com/apcera/kurma
export GOPATH="$BASE_PATH/go:$BASE_PATH/kurma-source/Godeps/_workspace"
go build -ldflags "$BUILD_LDFLAGS" -a -o $BASE_PATH/rootfs/kurma-api go/src/github.com/apcera/kurma/kurma-api.go

cd $BASE_PATH/rootfs

# setup lib
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
acbuild --no-history begin
for i in $BASE_PATH/rootfs/* ; do
    j=$(basename $i)
    acbuild --no-history copy $i $j
done

acbuild --no-history label add os linux
acbuild --no-history label add arch amd64
acbuild --no-history label add version v$version

acbuild --no-history set-exec /kurma-api
acbuild --no-history set-user 1000
acbuild --no-history set-group 1000
acbuild --no-history set-name apcera.com/kurma/api

# add our custom isolators
acbuild --no-history isolator add host/api-access kurmaos-source/aci/kurma-api/isolator-true.json
acbuild --no-history isolator add os/linux/namespaces kurmaos-source/aci/kurma-api/isolator-namespaces.json

acbuild --no-history write --overwrite kurma-api.aci
acbuild --no-history end
