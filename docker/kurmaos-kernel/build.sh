#!/bin/bash

set -e -x

source /etc/profile

# update portage
emerge-webrsync
emerge --sync

# allow the proper kernel version
echo '=sys-kernel/vanilla-sources-4.2.5 ~amd64' >> /etc/portage/package.accept_keywords
emerge =sys-kernel/vanilla-sources-4.2.5
mv /tmp/kernel.config /usr/src/linux/.config

# compile it
cd /usr/src/linux
make olddefconfig
make -j3
make INSTALL_MOD_STRIP="--strip-unneeded" modules_install
cp arch/x86/boot/bzImage /boot/bzImage

# cleanup
rm -rf /usr/portage
rm -rf /var/tmp
