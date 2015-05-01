# KurmaOS

This repository contains the scripts and tools needed to to build KurmaOS
images from top to bottom.

### Build Process

KurmaOS uses Linux Gentoo as the base OS for the build environment. Gentoo has several
advantages, including being up-to-date, vanilla, and barebones. Gentoo is ideal for pulling
and building on a minimal image.

The Kurma build process leverages the [Apcera package build scripts](https://github.com/apcera/continuum-package-scripts).
This provides you with a way to script the building of Kurma and an efficient machanism for building 
containers concurrently (such as on a full cluster). The Kurma build process also allows you to build Apcera Continuum from a
local virtual machine using one of the [trial images](https://www.apcera.com/getstarted/). This allows you to
compile everything on a Linux virtual machine even if you're on a Mac or Windows host.

The steps to build a base Kurma image are as follows:

1. Take an existing stage3 image and add in what is necessary for your build
   environment. This becomes what we call a stage4 image.
1. Take the stage4 image and generate another image which includes a
   pre-compiled kernel.
1. Generate some of the necessary base ACI images, such as for NTP or the
   console. These are all based on the stage4 image.
1. Upload your local source and the needed base ACI images to be compiled into
   the kurma initrd image.
1. Run packer to generate a virtual machine or vagrant image, ready to go.

After this, you are all set.

The artifacts of steps 1-3 can all be managed by Apcera, so that during 
the course of normal development, you just need to complete steps 4-5. 
For more information on steps 1-3, refer to the [Kurma repository readme](https://github.com/apcera/kurma).

Steps 4 and 5 have some distinctions between a development build and a release
build. A development build is very quick and will output a tarball containing the kernel
(`bzImage`) and the `initrd` image. A production release will generate a kernel which has 
the `initrd` image embedded in it. However, this involves recompiling the kernel which makes
for a longer iteration time. The benefit of this is that the production release
involves updating only a single file.

### Getting Started

To get started with building Kurma for KurmaOS, you likely want to start by using
existing images for build steps 1, 2, 3. You can do these steps if you
want, but generally they're updated when it is necessary to for updating
library dependencies, the base build environment, or kernel versions.

To get started with the latest official images for steps 1, 2, and 3, use the
included `bootstrap.sh` script.

The bootstrap script will download the latest assets and load them into your
Continuum cluster. It will also download the latest system ACI images and put
them in our `output/` folder.

### Tooling

The following pieces make up the build environment:

* `aci/` contains all of the ACI package build scripts.
* `base/` contains all of the Gentoo build scripts for the pieces in step 1, 2,
  and 4.
* `packer/` contains the packer build templates used in step 5.
* `output/` is where the scripts will look for local build artifacts.
* `vagrant/` provides a way to quickly bring up a virtual machine running
  KurmaOS from a step 5 output. *(not yet finished)*

### NOTE WHEN BUILDING PRE-STEP 4

If you are building steps 2 or 3, it is necessary to modify the
attributes of the compiler stager on the system. The `emerge-webrsync` call uses
up a lot of storage, and won't fit with the stock disk allocation. For some of
the compilation, we recommend upping the default memory. Currently,
there is no way to specify how much memory or disk the stager should have 
using the package build scripts. 

The following commands will update the resources settings. It is recommended to only do this with
vagrant or a demo image, rather than on a live cluster.

```
$ apc job update /apcera/stagers::compiler --memory 1gb --disk 10gb
```
