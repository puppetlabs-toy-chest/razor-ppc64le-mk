#!/bin/sh
#Written by Mick Tarsel

#Create the environment for razor to copy into a initramfs
#Eventually this will be in a PXE boot-able image for currently running Alpine instace


download_packages() {
  apk del ruby ruby-dev
apk update

# build dependices from wiki and razor
apk add alpine-sdk build-base apk-tools alpine-conf busybox fakeroot xorriso 'ruby<2.5.1' ruby-dev

# needed to build the razor-mk-agent.gem and convert gems to .apks
gem install etc fpm facter rake bundler --no-document
}

create_apks_from_gems() {
  # setup dir for building gems
  mkdir -p $GEM_DIR/

  # build custom razor-mk-agent.gem
  bundle install
  bundle exec rake build

  # location of razor-mk-agent-008.gem
  cp $BUILD_DIR/pkg/*.gem $GEM_DIR/

  # local install facter gem
  gem install facter --no-document -i $GEM_DIR/

  # move all gems into one location
  cp $GEM_DIR/cache/*.gem $GEM_DIR/

  #need to comment out a line to get working apk
  fpm_file=$(find /usr/lib/ruby | grep apk.rb)
  #line 255 #full_record_path = add_paxstring(full_record_path)
  cp -f $BUILD_DIR/apk.rb $fpm_file

  #build 2 apks from 2 gems
  mkdir -p $APK_DIR/
  cd $APK_DIR #where we will build apks
  fpm -n facter -a ppc64le -s gem -t apk $GEM_DIR/facter-2.5.1.gem
  fpm -n razor-mk-agent -a ppc64le -s gem -t apk $GEM_DIR/razor-mk-agent-008.gem

  #sign the apks
 abuild-sign $APK_DIR/*.apk

}

install_custom_apks() {
  apk add $APK_DIR/facter*.apk --allow-untrusted
	apk add $APK_DIR/razor-mk-agent*.apk --allow-untrusted
}

setup_mk_service() {
  #TODO Is this all the files we need for mk? what about ./lib/
  # move shell scripts used by mk OpenRC service
  cd $BUILD_DIR
  mkdir -p /usr/local/bin
  chmod +x $BUILD_DIR/bin/mk*
	cp -R $BUILD_DIR/bin /usr/local/bin
	chmod +x $BUILD_DIR/bin/mk*

  cp $BUILD_DIR/mk /etc/init.d/
}

start_mk_service() {
  rc-service add mk default
  /etc/init.d/mk start
}

setup_pxe_boot() {
  echo "/usr/share/udhcpc/default.script" > /etc/mkinitfs/features.d/dhcp.files
   echo "kernel/net/packet/af_packet.ko" > /etc/mkinitfs/features.d/dhcp.modules
   echo "kernel/fs/nfs/*" > /etc/mkinitfs/features.d/nfs.modules
   echo 'features="ata base bootchart cdrom cramfs ext2 ext3 ext4 xfs floppy keymap kms raid scsi usb virtio squashfs network dhcp nfs"' > /etc/mkinitfs/mkinitfs.conf

}

generate_pxe_initramfs() {
  pxe_dir=/root
  mkinitfs -o $pxe_dir/pxe-initramfs
  echo "initramfs in $pxe_dir"
}

check_kernel() {
  supported_kernel="4.14.48-0-vanilla"
  if [ $(uname -r) != $supported_kernel ];then
    echo "Please update kernel to at least $supported_kernel"
    exit 1
  fi
}

build_iso() {
  # repo with build scripts
  git clone https://github.com/alpinelinux/aports.git

  # copy my custom razor profile
  cp genapkovl-razor.sh ./aports/scripts
  cp mkimg.razor.sh ./aports/scripts
  cp mkimg.base.sh ./aports/scripts

  cd aports/scripts

  # where .iso will be once complete
  mkdir -p ~/iso

  # build the .iso for ppc64le using razor profile and output to ~/iso
  # the edge repo has the kernel and other special apks so need to use it
  sh mkimage.sh --tag main --outdir ~/iso --arch ppc64le --repository http://dl-cdn.alpinelinux.org/alpine/edge/main --profile razor
  #mkimage -> mkimg.razor.sh -> genapkovl-razor.sh -> mkimg.base.sh
}

#TODO vmlinuz and pxe-initramfs in one place
tar_microkernel(){
  cp /boot/vmlinuz ./
}

#BEGIN EXECUTION
BUILD_DIR=$pwd
# where gems and apks will exist for use by mk service
GEM_DIR=$BUILD_DIR/gems
APK_DIR=$BUILD_DIR/apks

check_kernel
download_packages #setup repositories to install needed packages to build
create_apks_from_gems #turn facter.gem and razor-mk-agent.gem into apks to use by Alpine
install_custom_apks #install facter.apk and razor-mk-agent.apk
setup_mk_service #move around executables used by mk service
start_mk_service
setup_pxe_boot #edit /etc/mkinitfs
#generate_pxe_initramfs
#tar_microkernel #take vmlinuz and new pxe-initramfs and put in a tarball
#build_iso #TODO is this needed or use build-iso.sh?
