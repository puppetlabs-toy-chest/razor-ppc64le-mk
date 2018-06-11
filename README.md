# Razor Microkernel for ppc64le
Build Alpine Linux 3.7.0 ppc64le tarball to use as the Razor microkernel.

x86 info: https://github.com/puppetlabs/razor-el-mk/blob/master/README.md

# How to Run
Setup an Alpine ppc64le machine with a 4.14.48-0-vanilla. Either download newer kernel from an Edge repo or follow instructions below.

Run scripts:

```bash
./setup-razor-env.sh
```
To reset the install and run it again (will delete everything built)

```bash
./cleanup.sh
```

## Installing My Kernel
```bash
wget https://github.com/puppetlabs/razor-ppc64le-mk/raw/master/kernel/linux-vanilla-4.14.48-r0.apk
apk add ./linux-vanilla-4.14.48-r0.apk --allow-untrusted
```

Due to https://bugs.alpinelinux.org/issues/8966 you will have to run the following:

```bash
mv /boot/vmlinuz-vanilla /boot/vmlinuz
```

## Installing Kernel from Source
Create a user account abuild. More info: https://wiki.alpinelinux.org/wiki/How_to_make_a_custom_ISO_image_with_mkimage

Follow instructions here:
https://wiki.alpinelinux.org/wiki/Custom_Kernel

If the kernel version is newer than 4.14.48-0-vanilla, change check_kernel()

# Developer Notes

This script will setup the razor environment on the currently running Alpine instance a.k.a. the build machine. We are not sure if this exact environment will be replicated in the pxe-initramfs. In order to make sure this outputs the correct initramfs with all the razor files, verify_pxe_initramfs() will extract inintramfs and shove in all the apks (packages) and scripts used by razor into the pxe-initramfs, and then 'zip' it back up. The mk service will utilize /etc/razor dir if needed.

## Debugging

To view the extracted pxe-initramfs
```bash
ls ./PXE/extracted
```

More info:

https://wiki.alpinelinux.org/wiki/Custom_Kernel

https://wiki.alpinelinux.org/wiki/Ppc64le
