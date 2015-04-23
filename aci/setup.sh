#!/bin/sh

BUILDPATH=$(pwd)
INSTALLPATH=$(mktemp -d)

sudo tar xzf ../output/rootfs.tar.gz -C $INSTALLPATH
sudo cp /usr/lib/liblzma.so.5 $INSTALLPATH/usr/lib
sudo chmod 666 $INSTALLPATH/etc/sudoers
echo "ALL ALL=(ALL:ALL) NOPASSWD: ALL" >> $INSTALLPATH/etc/sudoers
sudo chmod 440 $INSTALLPATH/etc/sudoers

echo Compressing
(
    cd $INSTALLPATH
    sudo tar czf $BUILDPATH/cntm-buildroot.tar.gz .
)

echo Uploading
apc package delete /apcera::buildroot-2015.02 --batch
apc package from file $BUILDPATH/cntm-buildroot.tar.gz /apcera::buildroot-2015.02 -p "os=buildroot-2015.02" -e "PATH=\$PATH:/bin:/sbin:/usr/bin:/usr/sbin" --batch
apc package update /apcera::buildroot-2015.02 -pa "os=ubuntu" --batch
apc package update /apcera::buildroot-2015.02 -pa "os=linux" --batch

apc package delete /apcera::buildroot-2015.02-build-essential --batch
apc package from file ../output/devfs.tar.gz "/apcera::buildroot-2015.02-build-essential" -p "package=buildroot-2015.02-build-essential" --batch
apc package update /apcera::buildroot-2015.02-build-essential -pa "package=build-essential" --batch




apc package delete /apcera::gentoo-stage3-20150409 --batch
apc package from file ~/Downloads/stage3-amd64-nomultilib-20150409.tar.bz2 /apcera::gentoo-stage3-20150409 -p "os=gentoo-stage3-20150409,os=gentoo" -e "PATH=\$PATH:/bin:/sbin:/usr/bin:/usr/sbin" --batch
