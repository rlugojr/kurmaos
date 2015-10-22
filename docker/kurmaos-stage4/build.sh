#!/bin/bash

set -e -x

source /etc/profile

echo 'GRUB_PLATFORMS="efi-64 pc xen"' >> /etc/portage/make.conf
# Disable sandboxing. This was causing issues building python modules pulled
# in by xen being in GRUB_PLATFORMS. The modules were throwing access
# violations for the sandbox only when being installed within a container, not
# when in a normal chroot.
echo 'FEATURES="-sandbox -usersandbox"' >> /etc/portage/make.conf

# update portage
emerge-webrsync

# install layman
emerge app-portage/layman

# Add in the Apcera overlay. This contains specific ebuilds which we'll want
# to reference.
layman -o https://raw.githubusercontent.com/apcera/kurmaos-overlay/master/overlay.xml -f -a kurmaos-overlay
echo 'source /var/lib/layman/make.conf' >> /etc/portage/make.conf
echo 'kurmaos-base' >> /etc/portage/categories
echo "=app-emulation/open-vm-tools-9.10.0" >> /etc/portage/package.unmask
echo "=kurmaos-base/vboot_reference-1.0-r887" >> /etc/portage/package.unmask
echo "=dev-libs/libdnet-1.12" >> /etc/portage/package.unmask
echo "=dev-libs/libmspack-0.4_alpha" >> /etc/portage/package.unmask
echo "=sys-boot/grub-2.02_beta2_p20150727-r1" >> /etc/portage/package.unmask
echo "=sys-boot/syslinux-4.07-r1" >> /etc/portage/package.unmask
emerge \
    =kurmaos-base/vboot_reference-1.0-r887 \
    =app-emulation/open-vm-tools-9.10.0 \
    =sys-boot/grub-2.02_beta2_p20150727-r1 \
    =sys-boot/syslinux-4.07-r1

emerge \
    app-arch/cpio \
    app-arch/zip \
    dev-lang/go \
    sys-apps/busybox \
    sys-apps/kexec-tools \
    sys-fs/e2fsprogs \
    sys-fs/dosfstools \
    app-emulation/qemu \
    app-misc/jq \
    dev-vcs/mercurial \
    sys-devel/bc

# install acbuild, for creating aci images
cd /tmp
git clone https://github.com/appc/acbuild.git
cd acbuild
./build
cp bin/acbuild /usr/bin/acbuild

# cleanup
rm -rf /usr/portage
rm -rf /var/tmp
