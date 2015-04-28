# KurmaOS

This repository contains the scripts and tools needed to to build KurmaOS
images from top to bottom.

### Build Process

KurmaOS is uses Gentoo as the base for its build environment. Gentoo provides
the advantage of being very up to date, vanilla, and barebones in terms of being
able to pull and build on a minimal image.

Kurma's build process leverages Continuum's package build scripts for handling
all of the processing. The benefit of this is that it provides a means to fully
script out a build. Additionally, it provides a clean way to farm out building
things concurrently (such as on a full Continuum cluster), or to build from a
local virtual machine using one of the Continuum trial images. This allows to
compile everything on a Linux virtual machine even if you're on your Mac or
Windows box.

The steps to go from scratch to ready to boot image are:

1. Take an existing stage3 image and add in what is necessary for our build
   environment. This becomes what we call a stage4 image.
1. Take the stage4 image and generate another image which includes a
   pre-compiled kernel.
1. Generate some of the necessary base ACI images, such as for NTP or the
   console. These are all based on the stage4 image.
1. Upload your local source and the needed base ACI images to be compiled into
   the kurma initrd image.
1. Run packer to generate a virtual machine or vagrant image, ready to go.

After this, you are set.

The artifacts of steps 1-3 can all be managed by the Apcera SRE team and made
available to others, so that during the course of normal development, you
primarily just need steps 4-5. Both of which are able to be done within a few
mins to generate a new image.

Step 4 and 5 do have some distinctions between a development build and a release
build. A development build will output a tarball containing the kernel
(`bzImage`) and the `initrd` image. This is very quick to build. However, the
production release will generate a kernel which has the initrd image embedded in
it. Unfortunately, it appears this involves recompiling the kernel which makes
for a longer iteration time. The benefit of this is that the production release
involves updating only a single file.

### Getting Started

To get started with building Kurma for KurmaOS, you likely want to started using
existing images for build steps 1, 2, 3. You can rebuild these steps if you
really wish, but generally they're updated when it is necessary to for updating
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

When you are building with steps 2 or 3, it is currently necessary to modify the
attributes of the compiler stager on the system. The `emerge-webrsync` call uses
up a lot of storage, and won't fit with the stock disk allocation. For some of
the compilation, I also recommend upping the default memory. However currently,
there is no way with the package build scripts to specify how much memory or
disk the stager should have.

The following commands will update them. It is recommended to only do this with
vagrant or a demo image, rather than on a live cluster.

```
$ apc job update /apcera/stagers::compiler --memory 1gb --disk 10gb
```
