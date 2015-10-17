# KurmaOS

This repository contains the scripts and tools needed to build KurmaOS
images from top to bottom.

### Downloading

The latest release images can be found under [Releases](https://github.com/apcera/kurmaos/releases).

### Build Process

KurmaOS uses Gentoo as the base OS for the build environment. Gentoo has several
advantages, including being up-to-date, vanilla, and bare bones. Gentoo is ideal
for pulling and building on a minimal image.

The Kurma build process leverages a set of Docker images as follows:

* `apcera/kurmaos-stage3` - This is the stock Gentoo stage3 image based on the
  `gentoo/stage3-amd64` Docker image. The upstream image is updated regularly
  and not tagged, so we clone it to our own to ensure consistency over time.
* `apcera/kurmaos-stage4` - This represents a layer on top of the Gentoo system
  which includes all of the necessary tooling for building Kurma and generating
  images.
* `apcera/kurmaos-kernel` - This image represents the current kernel used in
  KurmaOS images.

On top of these base images, there are three other categories of builds:

* ACI images which go into the base images for system services and utilities.
  * `aci/buildroot` - This builds the Buildroot base tarball used by the stock
    console image.
  * `aci/console` - This builds the Buildroot-based console. This is separate
    from building Buildroot so that it is easily repeatable. It bundles in the
    Kurma CLI and generates the ready to use ACI from the existing Buildroot
    rootfs tarball.
  * `aci/kurma-api` - This is an ACI image which includes the kurma-api process
    which acts as a remotely accessible API for launching containers on a
    KurmaOS machine.
  * `aci/ntp` - This is an ACI for the ntp client to keep the time on a host in
    sync.
* Compilation of Kurma components, such as the kurmaos-initrd image, CLI, and
  plain kurma-server binary.
  * `code/kurma-cli` - This build generates the Kurma CLI.
  * `code/kurma-init` - This build compiles the `kurma-init` process and bundles
    it into a tarball with the current kernel bzImage and the boot disk initrd.
  * `code/kurma-server` - This build generates the standalone `kurma-server`
    daemon.
* VM generation for common platforms, such as VMware, Virtualbox, OpenStack, and
  more.
  * `packaging/kurmaos-disk` - This build takes the `kurma-init` asset of a
    bzImage and initrd image and converts it into a raw partitioned disk
    image. This can then be converted and tailored for each VM environment.
  * `packaging/disk-virtualbox` - This build converts the raw disk image into a
    Virtualbox image.
  * `packaging/disk-vmware` - This build converts the raw disk image into a
    VMWare image.

### Getting Started

TBD, document the new Docker based build process.

### Tooling

The following pieces make up the build environment:

* `aci/` contains all of the ACI package build scripts.
* `base/` contains all of the Gentoo build scripts for the pieces in step 1, 2,
  and 4.
* `packer/` contains the packer build templates used in step 5.
* `output/` is where the scripts will look for local build artifacts.
* `vagrant/` provides a way to quickly bring up a virtual machine running
  KurmaOS from a step 5 output. *(not yet finished)*
