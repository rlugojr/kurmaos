#!/bin/bash

BASE_PATH=`pwd`

set -e -x

# calculate ldflags for the version number
version="$(git --git-dir=$BASE_PATH/kurma-source/.git describe --tags | cut -d'-' -f1)+git"
if [[ -f $BASE_PATH/version/number ]]; then
    version=$(cat $BASE_PATH/version/number)
fi
BUILD_LDFLAGS="-X github.com/apcera/kurma/stage1/client.version=$version"

mkdir -p go/src/github.com/apcera
ln -s $BASE_PATH/kurma-source go/src/github.com/apcera/kurma
export GOPATH="$BASE_PATH/go"
TARGET=$BASE_PATH/go/src/github.com/apcera/kurma

go version

go build -ldflags "$BUILD_LDFLAGS" -o kurma-server $TARGET/kurma-server.go

cp $TARGET/LICENSE LICENSE
tar -czf kurma-server-linux-amd64.tar.gz kurma-server LICENSE
