#!/bin/sh
mkdir /newroot
mount -t tmpfs none /newroot
cp -r /* /newroot/
exec /sbin/switch_root /newroot /kurma
