#!/bin/sh

set -e -x

(
    OUTPUTPATH=`pwd`/output
    cd $GOPATH/src
    tar czf $OUTPUTPATH/code.tar.gz \
        github.com/apcera/kurma \
        github.com/apcera/gnatsd \
        github.com/apcera/logray \
        github.com/apcera/util \
        github.com/apcera/termtables \
        github.com/creack/termios \
        github.com/appc/spec \
        github.com/kr/pty \
        github.com/vishvananda/netlink \
        github.com/golang/protobuf \
        google.golang.org/grpc \
        github.com/bradfitz/http2 \
        golang.org/x \
        google.golang.org/cloud \
        --exclude=.git
)

apc package build aci/console/console.conf --batch
apc package download console -f output/console.aci
apc package delete console --batch

apc package build aci/ntp/ntp.conf --batch
apc package download ntp -f output/ntp.aci
apc package delete ntp --batch
