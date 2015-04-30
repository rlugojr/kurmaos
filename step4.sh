#!/bin/sh

set -e -x

(
    OUTPUTPATH=`pwd`/output
    cd $GOPATH/src
    tar --exclude=.git -czf \
        $OUTPUTPATH/code.tar.gz \
        github.com/apcera/kurma
)

apc package build base/init/init-rapid.conf -n kurmaos-init-rapid --batch
apc package download kurmaos-init-rapid -f output/init-rapid.tar.gz
apc package delete kurmaos-init-rapid --batch
