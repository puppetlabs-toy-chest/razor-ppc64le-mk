# Razor Microkernel for ppc64le
Build Alpine Linux iso for ppc64le in order to setup a Razor mircokernel.

More info: https://github.com/puppetlabs/razor-el-mk/blob/master/README.md

# How to Run

This repo contains a shell script which will eventually build an Alpine Vanilla iso. The script will pull other git repos, build gems, and place all the files in the apkovl.tar.gz

## Install Alpine Vanilla on ppc64le

This Alpine instance will serve as the build machine. The script will setup a /etc/razor-build dir where all the gems and files to be installed into the .iso will exist.

After booting your official Alpine-Vanilla.iso, run the setup-alpine script and ensure network connectivity in order to pull repos.

## Setup Environment to Build ISO

```bash
apk add git

git clone https://github.com/puppetlabs/razor-ppc64le-mk/

cd razor-ppc64le-mk/

./build-iso.sh
```
Hit Enter when asked about where to store your public key.

Verify a ppc64le iso exists in ~/iso 

## Debug
Read the output from build command and look for build dir in /tmp


More info:

https://wiki.alpinelinux.org/wiki/How_to_make_a_custom_ISO_image_with_mkimage

Generating the PXE bootable image: https://wiki.alpinelinux.org/wiki/Talk:PXE_boot
