#!/bin/bash

export BASE_PATH=`pwd`

set -e -x

mount -t tmpfs none /sys/fs/cgroup
mkdir /sys/fs/cgroup/blkio \
      /sys/fs/cgroup/cpu \
      /sys/fs/cgroup/cpuacct \
      /sys/fs/cgroup/devices \
      /sys/fs/cgroup/memory
mount -t cgroup none /sys/fs/cgroup/blkio -o blkio
mount -t cgroup none /sys/fs/cgroup/cpu -o cpu
mount -t cgroup none /sys/fs/cgroup/cpuacct -o cpuacct
mount -t cgroup none /sys/fs/cgroup/devices -o devices
mount -t cgroup none /sys/fs/cgroup/memory -o memory

mkdir -p go/src/github.com/apcera
ln -s $BASE_PATH/kurma-source go/src/github.com/apcera/kurma
export GOPATH="$BASE_PATH/go:$BASE_PATH/kurma-source/Godeps/_workspace"

cd go/src/github.com/apcera/kurma
go test -i ./...
go test -v ./...
