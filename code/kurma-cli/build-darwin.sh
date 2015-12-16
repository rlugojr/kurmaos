#!/bin/bash

BASE_PATH=`pwd`
export PATH=/usr/local/go/bin:$PATH

set -e -x

# calculate ldflags for the version number
BUILD_LDFLAGS=""
if [[ -f $BASE_PATH/version/number ]]; then
    BUILD_LDFLAGS="-X github.com/apcera/kurma/stage1/client.version=$(cat $BASE_PATH/version/number)"
fi

mkdir -p go/src/github.com/apcera
ln -s $BASE_PATH/kurma-source go/src/github.com/apcera/kurma
export GOPATH="$BASE_PATH/go:$BASE_PATH/kurma-source/Godeps/_workspace"
TARGET=$BASE_PATH/go/src/github.com/apcera/kurma

go version

go build -ldflags "$BUILD_LDFLAGS" -o kurma-cli $TARGET/kurma-cli.go

cp $TARGET/LICENSE LICENSE
tar -czf kurma-cli-darwin-amd64.tar.gz kurma-cli LICENSE
