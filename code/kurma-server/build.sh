#!/bin/bash

BASE_PATH=`pwd`

set -e -x

mkdir -p go/src/github.com/apcera
ln -s $BASE_PATH/kurma-source go/src/github.com/apcera/kurma
export GOPATH="$BASE_PATH/go:$BASE_PATH/kurma-source/Godeps/_workspace"
TARGET=$BASE_PATH/go/src/github.com/apcera/kurma

go version

go build -o kurma-server $TARGET/kurma-server.go

cp $TARGET/LICENSE LICENSE
tar -czf kurma-server-linux-amd64.tar.gz kurma-server LICENSE