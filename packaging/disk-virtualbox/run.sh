#!/bin/bash

set -e

# Change to the location of the script
cd $(dirname $0)

# Create the output file ahead of time to ensure it is available.
output_filename=kurmaos-virtualbox.zip
touch ../../output/$output_filename

docker run --rm \
       -v `pwd`/../../output/kurmaos-disk.img.gz:/tmp/build/kurmaos-disk-image/kurmaos-disk.img.gz \
       -v `pwd`/../..:/tmp/build/kurmaos-source \
       -v `pwd`/../../output/$output_filename:/tmp/build/$output_filename \
       -w /tmp/build \
       apcera/kurmaos-stage4 \
       bash -c "./kurmaos-source/packaging/disk-virtualbox/build.sh && cp kurmaos.zip $output_filename"

echo "Compiled output available in ../../output/$output_filename"
