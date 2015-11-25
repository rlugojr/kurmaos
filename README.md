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
* `apcera/docker-aws-tools` - This image contains the ec2-api-tools package on
  Debian and is used for build the AMIs for KurmaOS. Using this package on
  Debian proved to be simpler than on Gentoo, as the package on Gentoo wanted to
  pull in 120 other packages from the Java dependency.

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

For local development, each of the previous mentioned directories for individual
pieces in the build process includes a `run.sh` script. This script can be
executed locally to trigger that step to be built locally using Docker. It will
map in the necessary inputs and outputs as volumes, so the build will happen
within Docker using your local code and output the results input the `output`
directory.

To get set up locally, you'll need to pull down two images from the Docker
public registry. Please note, you may occassionally need to re-retrieve them as
the base docker images change, such as with kernel and tooling updates.

```
$ docker pull apcera/kurmaos-stage4
$ docker pull apcera/kurmaos-kernel
```

It is also recommended to grab some of the build artifacts that you aren't
likely to be changing locally very often. Thie will save some time from
generating them yourself.

```
$ wget -O output/buildroot.tar.gz https://s3-us-west-2.amazonaws.com/kurmaos-artifacts/aci/buildroot.tar.gz
$ wget -O output/ntp.aci https://s3-us-west-2.amazonaws.com/kurmaos-artifacts/aci/ntp.aci
$ wget -O output/udev.aci https://s3-us-west-2.amazonaws.com/kurmaos-artifacts/aci/udev.aci
```

You may also be able to retrieve some of the following ones, if you are not
modifying anything with the CLI or API. Note: the CLI is bundled with the
console, so often when changing the CLI, it is recommended to generate the
console.

```
$ wget -O output/kurma-cli-linux-amd64.tar.gz https://s3-us-west-2.amazonaws.com/kurmaos-artifacts/cli/kurma-cli-linux-amd64.tar.gz
$ wget -O output/kurma-api.aci https://s3-us-west-2.amazonaws.com/kurmaos-artifacts/aci/kurma-api.aci
$ wget -O output/console.aci https://s3-us-west-2.amazonaws.com/kurmaos-artifacts/aci/console.aci
```

With those retrieved, it is now fairly easy to generate a new VM image to test
locally.

For instance, if you're working on the daemon and need to generate a new
Virtualbox VM, can run the followed chained commands:

```
$ ./code/kurma-init/run.sh && ./packaging/kurmaos-disk/run.sh && ./packaging/disk-virtualbox/run.sh
```

This will compile the `kurma-init` process and generate a new kernel/initrd
image, then run the step to build a new base disk layout, and then have that
disk image configured for virtualbox. At the end, you'll have a zip file at
`output/kurmaos-virtualbox.zip` with an OVF file ready to load into
Virtualbox. This step takes about 60-65 seconds locally on my laptop, which is
pretty decent considering it is generating an entire VM image.

*Note:* the build steps often have inputs from other steps, so using different
pieces of them requires some familiarity with the build process. It may be
useful to glance at some of the `run.sh` scripts to see what volumes are being
mounted in if you have any confusion.

*Note 2:* the build scripts assume the `kurmaos` repository is checked out
 within the `GOPATH`. When mapping in the Kurma code, it will expect the `kurma`
 repository to be up one level from the `kurmos` repository.
