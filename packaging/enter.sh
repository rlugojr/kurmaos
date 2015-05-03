#!/bin/sh

SCRIPT_ROOT=$(readlink -f $(dirname "$0"))
. "${SCRIPT_ROOT}/lib/common.sh" || exit 1

setup_chroot

echo "Entering"
sudo chroot ./chroot /bin/bash
