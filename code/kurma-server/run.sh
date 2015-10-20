#!/bin/bash

set -e

# Change to the location of the script
cd $(dirname $0)

# Create the output file ahead of time to ensure it is available.
output_filename=kurma-server-linux-amd64.tar.gz
touch ../../output/$output_filename

docker run --rm \
       -v `pwd`/../..:/tmp/build/kurmaos-source \
       -v `pwd`/../../../kurma:/tmp/build/kurma-source \
       -v `pwd`/../../output/$output_filename:/tmp/build/$output_filename \
       -w /tmp/build \
       apcera/kurmaos-stage4 \
       ./kurmaos-source/code/kurma-server/build.sh

echo "Compiled output available in ../../output/$output_filename"
