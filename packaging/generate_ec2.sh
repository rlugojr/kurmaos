#!/bin/sh

set -e -x

SSH_DEST=$1

gzip -1 -c ../output/images/raw.img > raw.img.gz
scp -r raw.img.gz aws/* $SSH_DEST:
rm raw.img.gz

ssh $SSH_DEST <<EOF
export AWS_ACCESS_KEY=$AWS_ACCESS_KEY
export AWS_SECRET_KEY=$AWS_SECRET_KEY
gunzip -c raw.img.gz > raw.img
rm raw.img.gz
./import.sh -B kurmaos-temp-disk-images -p raw.img -Z us-east-1b
EOF
