#!/bin/sh

set -e

SCRIPT_ROOT=$(readlink -f $(dirname "$0"))
. "${SCRIPT_ROOT}/lib/common.sh" || exit 1

SSH_DEST=$1

if [[ -z "${SSH_DEST}" ]]; then
    echo "$0: Must specify the ssh destination"
    exit 1
fi

cp ../output/images/raw.img ami.img
gzip -f ami.img

scp -r ami.img.gz aws/* $SSH_DEST:
rm ami.img.gz

ssh $SSH_DEST <<EOF
export AWS_ACCESS_KEY=$AWS_ACCESS_KEY
export AWS_SECRET_KEY=$AWS_SECRET_KEY
gunzip -f ami.img.gz
./import.sh -B kurmaos-temp-disk-images -p ami.img -Z us-east-1b
EOF
