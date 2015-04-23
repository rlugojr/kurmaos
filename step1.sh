#!/bin/sh

set -e -x

wget -O stage3.tar.bz2 https://s3.amazonaws.com/kurmaos-artifacts/stage3/stage3-amd64-nomultilib-20150416.tar.bz2
apc package from file stage3.tar.bz2 kurmaos-stage3-20150416 -p "os=gentoo-stage3" --batch
rm stage3.tar.bz2
apc package build base/stage4/stage4.conf -n kurmaos-gentoo-stage4 --batch
