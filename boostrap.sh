#!/bin/sh

set -e

function download() {
    local hash=$1
    local file=$2
    local url=$3

    if [ -f "$file" ]; then
        local currenthash=$(sha256sum "$file" | awk '{print $1}')
        if [ "$currenthash" = "$hash" ]; then
            echo "Skipping $file"
            return 0
        fi
    fi

    echo "Downloading $url"
    curl -o "$file" "$url"
    local currenthash=$(sha256sum "$file" | awk '{print $1}')
    if [ ! "$currenthash" = "$hash" ]; then
        echo "Validation of $url failed!"
        echo "Expected hash $hash"
        echo "     Got hash $currenthash"
        return 1
    fi
    return 0
}

# Continuum import files
download 04724c41cf9625c3e2fe3d615ea64d775905c2a304c1e5d3244e693bdfe47e43 \
         "output/kurmaos-stage3.cntmp" \
         "https://s3.amazonaws.com/kurmaos-artifacts/stage3/kurmaos-stage3-20150416.cntmp"
download 16dfa2f6c2cf268f96cae01c66e849b32dcf3030e2f269e6cf96c64401df7b18 \
         "output/kurmaos-gentoo-stage4.cntmp" \
         "https://s3.amazonaws.com/kurmaos-artifacts/stage4/kurmaos-gentoo-stage4-20150421.cntmp"
download 6b6e06d1d39974b571df6f99d7972a50088529d97d5f1f974df956443120c253 \
         "output/kurmaos-gentoo-kernel.cntmp" \
         "https://s3.amazonaws.com/kurmaos-artifacts/kernel/kurmaos-gentoo-kernel-3.19.5.cntmp"
apc import -s -o \
    output/kurmaos-stage3.cntmp \
    output/kurmaos-gentoo-stage4.cntmp \
    output/kurmaos-gentoo-kernel.cntmp

# Download the base system ACIs
download 473c86ca61391136975723efa764f85577366bb5474b0ae343f0d878e1493792 \
         "output/console.aci" \
         "https://s3.amazonaws.com/kurmaos-artifacts/aci/console-20150422.aci"
download 523d832821b4a7f503187703f105dc9c9f9e7e7d66b4f6a69cacc71411d16076 \
         "output/ntp.aci" \
         "https://s3.amazonaws.com/kurmaos-artifacts/aci/ntp-20150422.aci"
