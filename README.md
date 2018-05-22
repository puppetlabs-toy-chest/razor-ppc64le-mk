# alpine-vanilla-ppc64le
Build Alpine Linux iso for ppc64le

# How to Run

This repo contains a shell script which will eventually build an Alpine Vanilla iso. The script will pull other git repos, build gems, and place all the files in the apkovl.tar.gz

## Install Alpine Vanilla on ppc64le

Run the setup-alpine script and ensure network connectivity 

## Setup Environment to Build ISO

```bash
apk add git

git clone https://github.com/mtarsel/alpine-vanilla-ppc64le.git

cd alpine-vanilla-ppc64le

./build-iso.sh
```
Hit Enter when asked about where to store your public key.

Verify a ppc64le iso exists in ~/iso 

## Debug
Read the output from build command and look for build dir in /tmp


More info:

https://wiki.alpinelinux.org/wiki/How_to_make_a_custom_ISO_image_with_mkimage

https://github.com/mtarsel/aports/blob/master/scripts/genapkovl-razor.sh
