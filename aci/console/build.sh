#!/bin/sh

set -e
set -x

BASEPATH=`pwd`

sudo rm -rf tmp
mkdir -p tmp

# download
(
    cd $BASEPATH/tmp
    wget http://buildroot.uclibc.org/downloads/buildroot-2015.02.tar.gz
    tar xzf buildroot-2015.02.tar.gz
)

# compile buildroot
(
    cd $BASEPATH/tmp/buildroot-2015.02
    cp $BASEPATH/configs/buildroot.config .config
    cp $BASEPATH/configs/busybox.config busybox.config
    cp $BASEPATH/configs/kernel.config kernel.config
    cp $BASEPATH/configs/isolinux.cfg isolinux.cfg
    time make
)

# copy out the kernel and cpio image
sudo rm -rf output ; mkdir -p output
cp $BASEPATH/tmp/buildroot-2015.02/output/images/rootfs.cpio* output/
cp $BASEPATH/tmp/buildroot-2015.02/output/images/rootfs.iso9660 output/
cp $BASEPATH/tmp/buildroot-2015.02/output/images/bzImage output/

# split out the kernel modules from the rootfs
(
    cd $BASEPATH/tmp
    sudo mkdir root
    sudo tar xzf buildroot-2015.02/output/images/rootfs.tar.gz -C root
    cd root
    sudo tar czf $BASEPATH/output/modules.tar.gz lib/modules lib/firmware
    sudo rm -rf lib/modules lib/firmware
    sudo tar czf $BASEPATH/output/rootfs.tar.gz .
)

# process the devfs
(
    mkdir $BASEPATH/tmp/host
    cd $BASEPATH/tmp/host
    sudo rsync -a $BASEPATH/tmp/buildroot-2015.02/output/host/* .
    sudo chown -R root:root .
    sudo ln -s x86_64-buildroot-linux-gnu-gcc usr/bin/gcc
    # grub-mkimage needs lzma, but it isnt in buildroot, it uses the host
    sudo cp /usr/lib/liblzma.so.5 usr/lib/
    sudo cp /usr/lib/libstdc++.so.6 usr/lib/
    sudo tar czf $BASEPATH/output/devfs.tar.gz *
)



#sudo rm -rf tmp
