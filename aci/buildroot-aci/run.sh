#!/bin/bash

set -e

# Change to the location of the script
cd $(dirname $0)

# Create the output file ahead of time to ensure it is available.
output_filename=buildroot.aci
touch ../../output/$output_filename

docker run --rm \
       -v `pwd`/../../output/buildroot.tar.gz:/tmp/build/buildroot-base/buildroot.tar.gz \
       -v `pwd`/../..:/tmp/build/kurmaos-source \
       -v `pwd`/../../output/$output_filename:/tmp/build/z$output_filename \
       -w /tmp/build \
       apcera/kurmaos-stage4 \
       bash -c "./kurmaos-source/aci/buildroot-aci/build.sh && cp $output_filename z$output_filename"

echo "Compiled output available in output/$output_filename"
