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

apc package build base/init/init-rapid.conf -n kurmaos-init-rapid --batch
apc package download kurmaos-init-rapid -f output/init-rapid.tar.gz
apc package delete kurmaos-init-rapid --batch
