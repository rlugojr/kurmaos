#!/bin/bash

export BASE_PATH=`pwd`

set -e -x

mkdir $BASE_PATH/rootfs

mkdir -p go/src/github.com/apcera
ln -s $BASE_PATH/kurma-source go/src/github.com/apcera/kurma
export GOPATH="$BASE_PATH/go:$BASE_PATH/kurma-source/Godeps/_workspace"
go build -a -o $BASE_PATH/rootfs/kurma-api go/src/github.com/apcera/kurma/kurma-api.go

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

acbuild end kurma-api.aci
gzip kurma-api.aci
mv kurma-api.aci.gz kurma-api.aci