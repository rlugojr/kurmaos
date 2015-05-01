#!/bin/sh

set -e -x

(
    OUTPUTPATH=`pwd`/output
    cd $GOPATH/src
    tar --exclude=.git -czf \
        $OUTPUTPATH/code.tar.gz \
        github.com/apcera/kurma
)

apc package build aci/console/console.conf --batch
apc package download console -f output/console.aci
apc package delete console --batch

apc package build aci/ntp/ntp.conf --batch
apc package download ntp -f output/ntp.aci
apc package delete ntp --batch

apc package build aci/api/api.conf --batch
apc package download api -f output/api.aci
apc package delete api --batch
