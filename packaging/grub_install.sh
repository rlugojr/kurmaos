#!/bin/bash

# Copyright (c) 2014 The CoreOS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Replacement script for 'grub-install' which does not detect drives
# properly when partitions are mounted via individual loopback devices.

SCRIPT_ROOT=$(readlink -f $(dirname "$0"))
. "${SCRIPT_ROOT}/common.sh" || exit 1
. "${SCRIPT_ROOT}/shflags" || exit 1

# Flags.
DEFINE_string target "" \
  "The GRUB target to install such as i386-pc or x86_64-efi"
DEFINE_string esp_dir "" \
  "Path to EFI System partition mount point."
DEFINE_string disk_image "" \
  "The disk image containing the EFI System partition."

# Parse flags
FLAGS "$@" || exit 1
eval set -- "${FLAGS_ARGV}"
switch_to_strict_mode

# Our GRUB lives under kurmaos/grub so new pygrub versions cannot find grub.cfg
GRUB_DIR="kurmaos/grub/${FLAGS_target}"

# Modules required to find and read everything else from ESP
CORE_MODULES=( fat part_gpt search_fs_uuid gzio )

# Name of the core image, depends on target
CORE_NAME=

case "${FLAGS_target}" in
    i386-pc)
        CORE_MODULES+=( biosdisk )
        CORE_NAME="core.img"
        ;;
    x86_64-efi)
        CORE_NAME="core.efi"
        ;;
    x86_64-xen)
        CORE_NAME="core.elf"
        ;;
    *)
        die_notrace "Unknown GRUB target ${FLAGS_target}"
        ;;
esac

# In order for grub-setup-bios to properly detect the layout of the disk
# image it expects a normal partitioned block device. For most of the build
# disk_util maps individual loop devices to each partition in the image so
# the kernel can automatically detach the loop devices on unmount. When
# using a single loop device with partitions there is no such cleanup.
# That's the story of why this script has all this goo for loop and mount.
ESP_DIR=
LOOP_DEV=

cleanup() {
    if [[ -d "${ESP_DIR}" ]]; then
        if mountpoint -q "${ESP_DIR}"; then
            umount "${ESP_DIR}"
        fi
        rm -rf "${ESP_DIR}"
    fi
    if [[ -b "${LOOP_DEV}" ]]; then
        losetup --detach "${LOOP_DEV}"
    fi
}
trap cleanup EXIT

info "Installing GRUB ${FLAGS_target} in ${FLAGS_disk_image##*/}"
LOOP_DEV=$(losetup --find --show --partscan "${FLAGS_disk_image}")
ESP_DIR=$(mktemp --directory)

# work around slow/buggy udev, make sure the node is there before mounting
if [[ ! -b "${LOOP_DEV}p1" ]]; then
    # sleep a little just in case udev is ok but just not finished yet
    warn "loopback device node ${LOOP_DEV}p1 missing, waiting on udev..."
    sleep 0.5
    for (( i=0; i<5; i++ )); do
        if [[ -b "${LOOP_DEV}p1" ]]; then
            break
        fi
        warn "looback device node still ${LOOP_DEV}p1 missing, reprobing..."
        blockdev --rereadpt ${LOOP_DEV}
        sleep 0.5
    done
    if [[ ! -b "${LOOP_DEV}p1" ]]; then
        failboat "${LOOP_DEV}p1 where art thou? udev has forsaken us!"
    fi
fi

mount -t vfat "${LOOP_DEV}p1" "${ESP_DIR}"
sleep 1
mkdir -p "${ESP_DIR}/${GRUB_DIR}"

info "Compressing modules in ${GRUB_DIR}"
for file in "/usr/lib/grub/${FLAGS_target}"/*{.lst,.mod}; do
    out="${ESP_DIR}/${GRUB_DIR}/${file##*/}"
    gzip --best --stdout "${file}" | sudo_clobber "${out}"
done

info "Generating ${GRUB_DIR}/load.cfg"
# Include a small initial config in the core image to search for the ESP
# by filesystem ID in case the platform doesn't provide the boot disk.
# The existing $root value is given as a hint so it is searched first.
ESP_FSID=$(grub2-probe -t fs_uuid -d "${LOOP_DEV}p1")
sudo_clobber "${ESP_DIR}/${GRUB_DIR}/load.cfg" <<EOF
search.fs_uuid ${ESP_FSID} root \$root
set prefix=(\$root)/kurmaos/grub
set
EOF

info "Generating ${GRUB_DIR}/${CORE_NAME}"
grub2-mkimage \
    --compression=auto \
    --format "${FLAGS_target}" \
    --prefix "(,gpt1)/kurmaos/grub" \
    --config "${ESP_DIR}/${GRUB_DIR}/load.cfg" \
    --output "${ESP_DIR}/${GRUB_DIR}/${CORE_NAME}" \
    "${CORE_MODULES[@]}"

# This script will get called a few times, no need to re-copy grub.cfg
if [[ ! -f "${ESP_DIR}/kurmaos/grub/grub.cfg" ]]; then
    info "Installing grub.cfg"
    cp "${SCRIPT_ROOT}/grub.cfg" "${ESP_DIR}/kurmaos/grub/grub.cfg"
fi

# Now target specific steps to make the system bootable
case "${FLAGS_target}" in
    i386-pc)
        info "Installing MBR and the BIOS Boot partition."
        cp "/usr/lib/grub/i386-pc/boot.img" "${ESP_DIR}/${GRUB_DIR}"
        grub2-bios-setup --device-map=/dev/null \
            --directory="${ESP_DIR}/${GRUB_DIR}" "${LOOP_DEV}"
        ;;
    x86_64-efi)
        info "Installing default x86_64 UEFI bootloader."
        mkdir -p "${ESP_DIR}/EFI/boot"
        cp "${ESP_DIR}/${GRUB_DIR}/${CORE_NAME}" \
                "${ESP_DIR}/EFI/boot/bootx64.efi"
        ;;
    x86_64-xen)
        info "Installing default x86_64 Xen bootloader."
        mkdir -p "${ESP_DIR}/xen" "${ESP_DIR}/boot/grub"
        cp "${ESP_DIR}/${GRUB_DIR}/${CORE_NAME}" \
            "${ESP_DIR}/xen/pvboot-x86_64.elf"
        cp "${SCRIPT_ROOT}/menu.lst" \
            "${ESP_DIR}/boot/grub/menu.lst"
        ;;
esac

cleanup
trap - EXIT
