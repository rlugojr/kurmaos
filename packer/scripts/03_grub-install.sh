#!/bin/sh

set -e -x

# grub install
grub2-install --boot-directory=/mnt/vm/boot /dev/sda

cat >/mnt/vm/boot/grub/grub.cfg <<EOF
set default="0"
set timeout="1"

menuentry "KurmaOS" {
  set root=(hd0,1)
  linux /boot/bzImage
  initrd /boot/initrd
}
EOF
