#!/bin/sh

set -e -x

# create VM
(
    cd packer
    rm -rf output-vmware-iso/ kurmaos-vagrant-*.box
    packer build template.json
)
