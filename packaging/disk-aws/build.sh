#!/bin/bash

BASE_PATH=`pwd`

set -e -x

# calculate ldflags for the version number
version="$(git --git-dir=$BASE_PATH/kurma-source/.git describe --tags | cut -d'-' -f1)+git"
if [[ -f $BASE_PATH/version/number ]]; then
    version=$(cat $BASE_PATH/version/number)
fi

# Import the image into AWS
cd kurmaos-source/packaging/disk-aws
./import.sh -B kurmaos-temp-disk-images \
            -p $BASE_PATH/kurmaos-disk-image/kurmaos-disk.img \
            -V $version \
            -Z us-west-2a | tee $BASE_PATH/instances.txt

# remove intermediate files to speed up concourse post-build ops
rm $BASE_PATH/kurmaos-disk-image/kurmaos-disk.img
