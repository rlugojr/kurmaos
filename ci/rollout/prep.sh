#!/bin/bash

BASE_PATH=`pwd`

set -e -x

version=$(cat version/number)

mv kurma-cli-linux-amd64/kurma-cli-linux-amd64.tar.gz kurma-cli-$version-linux-amd64.tar.gz
mv kurma-cli-darwin-amd64/kurma-cli-darwin-amd64.tar.gz kurma-cli-$version-darwin-amd64.tar.gz
mv kurma-server-linux-amd64/kurma-server-linux-amd64.tar.gz kurma-server-$version-linux-amd64.tar.gz
mv disk-vmware-image/kurmaos-vmware.zip kurmaos-vmware-$version.zip
mv disk-virtualbox-image/kurmaos-virtualbox.zip kurmaos-virtualbox-$version.zip
mv kurma-upgrader-aci-image/kurma-upgrader.aci kurma-upgrader-$version.aci
