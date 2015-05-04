#!/bin/sh

set -e

function download() {
    local hash=$1
    local file=$2
    local url=$3

    if [ -f "$file" ]; then
        local currenthash=$(shasum -a 256 "$file" | awk '{print $1}')
        if [ "$currenthash" = "$hash" ]; then
            echo "Skipping $file"
            return 0
        fi
    fi

    echo "Downloading $url"
    curl -o "$file" "$url"
    local currenthash=$(shasum -a 256 "$file" | awk '{print $1}')
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
download 02d8d93a5e302283a86976dd9c95ebd59bee42f81726560a9361e55aa39e334c \
         "output/kurmaos-gentoo-stage4.cntmp" \
         "https://s3.amazonaws.com/kurmaos-artifacts/stage4/kurmaos-gentoo-stage4-20150429.cntmp"
download 1be4114c38c92986df2f30156056869713864b35d7b24e5e9ccc477e197ef83f \
         "output/kurmaos-gentoo-kernel.cntmp" \
         "https://s3.amazonaws.com/kurmaos-artifacts/kernel/kurmaos-gentoo-kernel-4.0.1.cntmp"
apc import -s -o \
    output/kurmaos-stage3.cntmp \
    output/kurmaos-gentoo-stage4.cntmp \
    output/kurmaos-gentoo-kernel.cntmp

# Download the base system ACIs
download 5a167a5bf684d8be25706aa62854f4dff42efc9896a36a2b8a82ea0be0ff41bb \
         "output/api.aci" \
         "https://s3.amazonaws.com/kurmaos-artifacts/aci/api-20150503.aci"
download 021c2c3a5d1d3a5101a3af23314fc9d7f3f1950fc67caaf3b7f7abfb3f0fc613 \
         "output/console.aci" \
         "https://s3.amazonaws.com/kurmaos-artifacts/aci/console-20150503.aci"
download 91eefda229f30810b75b2cf0178e4e4665181c98cd5daac01ac2542939fadf8e \
         "output/ntp.aci" \
         "https://s3.amazonaws.com/kurmaos-artifacts/aci/ntp-20150429.aci"
