# Razor Microkernel for ppc64le
Build Alpine Linux 3.7.0 ppc64le tarball to use as the Razor microkernel.

x86 info: https://github.com/puppetlabs/razor-el-mk/blob/master/README.md

# How to Run
Setup an Alpine ppc64le machine with a 4.14.48-0-vanilla. Either download newer kernel from an Edge repo or follow instructions below to build kernel from source.

Run scripts:

```bash
./setup-razor-env.sh
```
To reset the install and run it again (will delete everything built)

```bash
./cleanup.sh
```

## Installing Correct Kernel Version
Update the repositories to v3.8 repo, and upgrade packages.

```bash
echo "http://dl-cdn.alpinelinux.org/alpine/v3.8/main/" >> /etc/apk/repositories 
apk update
apk upgrade --available --update-cache
reboot
```

## Installing Kernel from Source
Create a user account abuild. More info: https://wiki.alpinelinux.org/wiki/How_to_make_a_custom_ISO_image_with_mkimage

Follow instructions here:
https://wiki.alpinelinux.org/wiki/Custom_Kernel

If the kernel version is newer than 4.14.48-0-vanilla, change check_kernel()

# Developer Notes
Some helpful tidbits of why something is implemented a certain way. Helpful for other devs.

## Installing Razor files
We have 2 gems which need to be included for razor, facter and razor-mk-agent. In summary, we convert these gems into apks - Alpine's package format. Facter is locally installed as a gem. razor-mk-agent is built from the code in this repo. Once both gems exist, we will convert the gems to apks using fpm. Look at create_apks_from_gems()

## initramfs and PXE
This script will setup the razor environment on the currently running Alpine instance a.k.a. the build machine. Once everything is in place, we generate a PXE bootable initramfs using mkinitfs. We are not sure if this exact environment will be replicated in the pxe-initramfs. In order to make sure this outputs the correct initramfs with all the razor files, verify_pxe_initramfs() will extract initramfs and shove in all the apks (packages) and scripts used by razor into the pxe-initramfs, and then 'zip' it back up. The mk service will utilize /etc/razor dir if needed.

## Viewing initramfs

To view the extracted pxe-initramfs, after running setup-razor-env.sh
```bash
ls ./PXE/extracted
```

## Example pxelinux file

```
default microkernel

label microkernel
   kernel vmlinuz
   initrd pxerd
   append modules=loop,squashfs,sd-mod,usb-storage,ibmvscsi console=hvc0 powersave=off ip=client-ip:server-ip:gw-ip:netmask:hostname:device:-:8.8.8.8:8.8.4.4 alpine_repo=http://dl-cdn.alpinelinux.org/alpine/v3.8/main/ modloop=http://dl-master.alpinelinux.org/alpine/v3.8/releases/ppc64le/netboot-3.8.0_rc5/modloop-vanilla


```
More info:

https://wiki.alpinelinux.org/wiki/Upgrading_Alpine#Upgrading_to_latest_release

https://wiki.alpinelinux.org/wiki/Custom_Kernel

https://wiki.alpinelinux.org/wiki/Ppc64le
