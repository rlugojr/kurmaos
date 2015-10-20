#!/bin/bash

set -e

# Change to the location of the script
cd $(dirname $0)

# Create the output file ahead of time to ensure it is available.
output_filename=kurmaos-disk.img.gz
touch ../../output/$output_filename

docker run --privileged --rm \
       -v `pwd`/../../output/kurma-init.tar.gz:/tmp/build/kurma-init-build/kurma-init.tar.gz \
       -v `pwd`/../..:/tmp/build/kurmaos-source \
       -v `pwd`/../../output/$output_filename:/tmp/build/$output_filename \
       -w /tmp/build \
       apcera/kurmaos-stage4 \
       bash -c "./kurmaos-source/packaging/kurmaos-disk/build.sh && cp raw.img.gz $output_filename"

echo "Compiled output available in ../../output/$output_filename"
