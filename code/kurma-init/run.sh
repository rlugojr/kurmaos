#!/bin/bash

set -e

# Change to the location of the script
cd $(dirname $0)

# Create the output file ahead of time to ensure it is available.
output_filename=kurma-init.tar.gz
touch ../../output/$output_filename

docker run --rm \
       -v `pwd`/../..:/tmp/build/kurmaos-source \
       -v `pwd`/../../../kurma:/tmp/build/kurma-source \
       -v `pwd`/../../output/buildroot.aci:/tmp/build/buildroot-aci-image/buildroot.aci \
       -v `pwd`/../../output/console.aci:/tmp/build/console-aci-image/console.aci \
       -v `pwd`/../../output/ntp.aci:/tmp/build/ntp-aci-image/ntp.aci \
       -v `pwd`/../../output/udev.aci:/tmp/build/udev-aci-image/udev.aci \
       -v `pwd`/../../output/kurma-api.aci:/tmp/build/kurma-api-aci-image/kurma-api.aci \
       -v `pwd`/../../output/$output_filename:/tmp/build/$output_filename \
       -w /tmp/build \
       apcera/kurmaos-kernel \
       ./kurmaos-source/code/kurma-init/build.sh

echo "Compiled output available in ../../output/$output_filename"
