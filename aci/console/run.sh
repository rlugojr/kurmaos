#!/bin/bash

set -e

# Change to the location of the script
cd $(dirname $0)

# Create the output file ahead of time to ensure it is available.
output_filename=console.aci
touch ../../output/$output_filename

docker run --rm \
       -v `pwd`/../../output/buildroot.tar.gz:/tmp/build/buildroot-base/buildroot.tar.gz \
       -v `pwd`/../../output/kurma-cli-linux-amd64.tar.gz:/tmp/build/kurma-cli-linux-amd64/kurma-cli-linux-amd64.tar.gz \
       -v `pwd`/../..:/tmp/build/kurmaos-source \
       -v `pwd`/../../../kurma:/tmp/build/kurma-source \
       -v `pwd`/../../../util:/tmp/build/apcera-util-source \
       -v `pwd`/../../output/$output_filename:/tmp/build/z$output_filename \
       -w /tmp/build \
       apcera/kurmaos-stage4 \
       bash -c "./kurmaos-source/aci/console/build.sh && cp $output_filename z$output_filename"

echo "Compiled output available in ../../output/$output_filename"
