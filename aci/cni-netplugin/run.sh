#!/bin/bash

set -e

# Change to the location of the script
cd $(dirname $0)

# Create the output file ahead of time to ensure it is available.
output_filename=cni-netplugin.aci
touch ../../output/$output_filename

docker run --rm \
       -v `pwd`/../../output/busybox.aci:/tmp/build/busybox-aci-image/busybox.aci \
       -v `pwd`/../..:/tmp/build/kurmaos-source \
       -v $GOPATH/src/github.com/appc/cni:/tmp/build/appc-cni-source \
       -v `pwd`/../../output/$output_filename:/tmp/build/z$output_filename \
       -w /tmp/build \
       apcera/kurmaos-stage4 \
       bash -c "./kurmaos-source/aci/cni-netplugin/build.sh && cp $output_filename z$output_filename"

echo "Compiled output available in output/$output_filename"
