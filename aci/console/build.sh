#!/bin/bash

BASE_PATH=`pwd`
set -e -x

mkdir -p go/src/github.com/apcera
ln -s $BASE_PATH/kurma-source go/src/github.com/apcera/kurma
export GOPATH="$BASE_PATH/go:$BASE_PATH/kurma-source/Godeps/_workspace"
TARGET=$BASE_PATH/go/src/github.com/apcera/kurma

# extract the root
mkdir root
tar -xf buildroot-base/buildroot.tar.gz -C root

# configure and build the spawner
cp kurmaos-source/images/console/spawn.json root/etc/spawn.conf
cp kurmaos-source/images/console/start.sh root/start.sh
chown 0:0 root/etc/spawn.conf root/start.sh
chmod a+x root/start.sh
go build -a -o root/sbin/spawn apcera-util-source/spawn/spawn.go

# get kurma-cli
tar -xf kurma-cli-linux-amd64/kurma-cli-linux-amd64.tar.gz -C kurma-cli-linux-amd64
cp kurma-cli-linux-amd64/kurma-cli root/usr/bin/kurma-cli

# generate the aci
cd $BASE_PATH
acbuild begin
for i in $BASE_PATH/root/* ; do
    j=$(basename $i)
    acbuild copy $i $j
done

acbuild label add os linux
acbuild label add version latest

acbuild environment add PATH "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

acbuild set-exec /start.sh
acbuild set-user 0
acbuild set-group 0
acbuild set-name apcera.com/kurma/console

# add our custom isolators
jq -c -s '.[0] * .[1]' .acbuild/currentaci/manifest kurmaos-source/images/console/isolator.json > manifest
mv manifest .acbuild/currentaci/manifest

acbuild end console.aci
gzip console.aci
mv console.aci.gz console.aci
