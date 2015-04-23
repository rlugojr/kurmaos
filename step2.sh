#!/bin/sh

set -e -x

apc package build base/kernel/kernel.conf -n kurmaos-gentoo-kernel --batch
