# Razor Microkernel for ppc64le
Build Alpine Linux 3.7.0 tarball for ppc64le for the Razor mircokernel.

x86 info: https://github.com/puppetlabs/razor-el-mk/blob/master/README.md

# How to Run
Setup an Alpine ppc64le machine. This will be your build machine where the install scripts are ran.

```bash
./setup-razor-env.sh
```
To reset the install and run it again (will delete everything built)

```bash
./cleanup.sh
```
# Developer Notes

This script will setup the razor environment on the currently running Alpine instance, the build machine. We are not sure if this exact environment will be replicated in the pxe-initramfs. In order to make sure this outputs the correct initramfs with all the razor files, verify_pxe_initramfs() will extract inintramfs and shove in all the apks (packages) and scripts used by razor. The mk service will utilize this special dir if needed.

## Debugging

To view the extracted pxe-initramfs
```bash
ls ./PXE/extracted
```


More info:
https://wiki.alpinelinux.org/wiki/Ppc64le
