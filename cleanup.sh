#!/bin/sh

echo ""
echo "Cleaning up..."
echo ""
BUILD_DIR=$(pwd)

#Will not remove pxe bootable configs or apk.rb for fpm
apk del ruby ruby-dev facter razor-mk-agent
rm -rf $BUILD_DIR/apkovl
rm -rf $BUILD_DIR/pkg
rm -rf $BUILD_DIR/gems
rm -rf $BUILD_DIR/apks
rm -rf $BUILD_DIR/PXE
rm -rf $BUILD_DIR/microkernel-ppc64le
rm /usr/local/bin/mk*
rm -rf /root/pxe-initramfs
/etc/init.d/mk stop
rm /etc/init.d/mk
