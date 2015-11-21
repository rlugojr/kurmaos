#!/bin/bash

set -e

# Change to the location of the script
cd $(dirname $0)

docker run --rm \
       --privileged \
       -v `pwd`/../..:/tmp/build/kurmaos-source \
       -v `pwd`/../../../kurma:/tmp/build/kurma-source \
       -w /tmp/build \
       apcera/kurmaos-stage4 \
       ./kurmaos-source/ci/test/test.sh
