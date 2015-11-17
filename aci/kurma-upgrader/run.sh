#!/bin/bash

set -e

# Change to the location of the script
cd $(dirname $0)

# Create the output file ahead of time to ensure it is available.
output_filename=kurma-upgrader.aci
touch ../../output/$output_filename

docker run --rm \
       -v `pwd`/../..:/tmp/build/kurmaos-source \
       -v `pwd`/../../../kurma:/tmp/build/kurma-source \
       -v `pwd`/../../output/kurma-init.tar.gz:/tmp/build/kurma-init-build/kurma-init.tar.gz \
       -v `pwd`/../../output/$output_filename:/tmp/build/z$output_filename \
       -w /tmp/build \
       apcera/kurmaos-stage4 \
       bash -c "./kurmaos-source/aci/kurma-upgrader/build.sh && cp $output_filename z$output_filename"

echo "Compiled output available in ../../output/$output_filename"
