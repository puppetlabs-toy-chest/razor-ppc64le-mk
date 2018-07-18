#!/bin/sh
#Written by Mick Tarsel

#setup razor microkernel and generate a PXE boot-able image from currently
   #running Alpine instance

#go to bottom for start of execution

BUILD_DIR=$(pwd)
GEM_DIR=$BUILD_DIR/gems
APK_DIR=$BUILD_DIR/apks
PXE_DIR=$BUILD_DIR/PXE

download_packages() {
  echo ""
  echo "Downloading packages..."
  echo ""
  apk del ruby ruby-dev
apk update

# build dependices from wiki and razor
apk add alpine-sdk build-base apk-tools alpine-conf busybox fakeroot xorriso ruby ruby-dev mkinitfs
#NOTE: verify gemfile ruby version!

abuild-keygen -a

# needed to build the razor-mk-agent.gem and convert gems to .apks
gem install etc fpm rake bundler --no-document
#TODO why install facter?
}

create_apks_from_gems() {
  echo ""
  echo "Creating apks from gems..."
  echo ""
  # setup dir for building gems
  mkdir -p $GEM_DIR/

  cd $BUILD_DIR
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
  fpm_file=$(find /usr/lib/ruby/gems/2.5.0/gems/fpm* | grep apk.rb)
  #line 255 #full_record_path = add_paxstring(full_record_path)
  sudo cp -f $BUILD_DIR/apk.rb $fpm_file

  #build 2 apks from 2 gems
  mkdir -p $APK_DIR/
  cd $APK_DIR #where we will build apks
  /usr/bin/fpm -n facter -a ppc64le -s gem -t apk $GEM_DIR/facter-2.5.1.gem
  /usr/bin/fpm -n razor-mk-agent -a ppc64le -s gem -t apk $GEM_DIR/razor-mk-agent-008.gem

  #sign the apks
 abuild-sign $APK_DIR/*.apk
}

setup_mk_service() {
  echo ""
  echo "Setting up mk service..."
  echo ""
  # move shell scripts used by mk OpenRC service
  cd $BUILD_DIR
  mkdir -p /usr/local/bin
  chmod +x $BUILD_DIR/bin/mk*
  cp  $BUILD_DIR/bin/* /usr/local/bin

  chmod +x $BUILD_DIR/mk

  if [ ! -f /etc/init.d/mk ]; then
    cp $BUILD_DIR/mk /etc/init.d/
    rc-update add mk default
  fi
}

start_mk_service() {
  echo ""
  echo "Starting mk service..."
  echo ""
  /etc/init.d/mk start
}

setup_pxe_boot() {
  echo ""
  echo "Setting up pxe boot..."
  echo ""

  echo "/usr/share/udhcpc/default.script" > /etc/mkinitfs/features.d/dhcp.files
   echo "kernel/net/packet/af_packet.ko" > /etc/mkinitfs/features.d/dhcp.modules
   echo "kernel/fs/nfs/*" > /etc/mkinitfs/features.d/nfs.modules
   echo 'features="ata base bootchart cdrom cramfs ext2 ext3 ext4 xfs floppy keymap kms raid scsi usb virtio squashfs network dhcp nfs"' > /etc/mkinitfs/mkinitfs.conf

   mkdir -p $PXE_DIR
}

generate_pxe_initramfs() {
  echo ""
  echo "Generating pxe-initramfs..."
  echo ""

  #TODO dont need to generate this every time. if it exsits, extract it
  #packages are not included in this by default. will have to
    #extract and add.
  mkinitfs -o $PXE_DIR/pxe-initramfs
}

verify_pxe_initramfs() {
  echo ""
  echo "Validating pxe-initramfs..."
  echo ""

  mkdir -p $PXE_DIR/extracted
  cd $PXE_DIR/extracted
  gunzip -c $PXE_DIR/pxe-initramfs | cpio -idmv #extract to ./PXE/extracted

  #make sure all files are available for mk service.

  #cp apks for mk service start_pre()
  mkdir -p ./etc/razor/apks
  cp $APK_DIR/* ./etc/razor/apks/

  #cp scripts for mk service start_pre()
  mkdir -p ./usr/local/bin
  chmod +x $BUILD_DIR/bin/mk*
  cp  $BUILD_DIR/bin/* ./etc/razor

  #zip it back up
  find . | cpio -H newrc -o | gzip -9 > $PXE_DIR/pxe-initramfs
}

tar_microkernel(){
  echo ""
  echo "Downloading & tarring up vmlinuz and initramfs..."
  echo ""
  cd $BUILD_DIR
  mkdir -p $BUILD_DIR/microkernel-ppc64le
  cd $BUILD_DIR/microkernel-ppc64le
  
  #get official 3.8 vmlinuz file
  wget http://dl-cdn.alpinelinux.org/alpine/v3.8/releases/ppc64le/netboot/vmlinuz-vanilla
  
  #get official 3.8 initramfs-vanilla
  wget http://dl-cdn.alpinelinux.org/alpine/v3.8/releases/ppc64le/netboot/initramfs-vanilla

  #TODO include the modules file used in extra boot commands?
  #wget http://dl-cdn.alpinelinux.org/alpine/v3.8/releases/ppc64le/netboot/modloop-vanilla

  cd $BUILD_DIR #tar: Removing leading `/' from member names.
  #a security feature of tar to not use absolute paths.
  tar -cf ./microkernel-ppc64le.tar ./microkernel-ppc64le
  #TODO sign it?
  echo "Succuessfully created microkernel-ppc64le.tar ....."
}

build_apkovl_tar(){
  echo ""
  echo "Building apkovl.tar.gz..."
  echo ""

  mkdir -p /etc/razor/
  mkdir -p /etc/razor/bin
  mkdir -p /etc/razor/apks

  cd $BUILD_DIR
  mkdir -p apkovl/
  chmod +x $BUILD_DIR/setup-razor-mk.sh
 
 #TODO this script assumes /etc/razor contains a bin/ dir and mk service file 
  cp $BUILD_DIR/setup-razor-mk.sh /etc/profile.d/
  cp $BUILD_DIR/mk /etc/razor #service file
  cp $BUILD_DIR/bin/* /etc/razor/bin
  cp $BUILD_DIR/apks/* /etc/razor/apks

  #contains apks and Ruby files
  lbu include /etc/razor/

  #contains script to start everything
  lbu include /etc/profile.d/
  
  #setup DNS 
  echo > /etc/resolv.conf
  echo "nameserver 8.8.8.8" >> /etc/resolv.conf
  echo "nameserver 8.8.4.4" >> /etc/resolv.conf
  lbu include /etc/resolv.conf

  #double check nothing is installed
  if grep "facter" /etc/apk/world; then
	  echo "Removing facter and razor-mk-agent..."
	  apk del facter
	  apk del razor-mk-agent
  fi

  cd ./apkovl/
  lbu package
}

####################################
####################################
#BEGIN EXECUTION

#setup repositories to install needed packages to build
download_packages;

#turn facter.gem and razor-mk-agent.gem into apks to use by Alpine
create_apks_from_gems;

#move around executables used by mk service
setup_mk_service;

#specified in ./mk
start_mk_service;

#edit /etc/mkinitfs to includ NICs and enable network/dhcp
setup_pxe_boot;

#create a pxe-initrams in ./PXE
#generate_pxe_initramfs;

#make sure all files are on pxe-initramfs. make a dir
  #called /etc/razor where mk service can grab files
  #everything _should_ be included in pxe-initrams but this func will extract it

  #and add what we want so service can use it.
#verify_pxe_initramfs;

#take vmlinuz and new pxe-initramfs and put in a tarball just like x86
tar_microkernel;

#create an apkovl.tar.gz which contains:
# ssh priv key, mk service, related razor files,
#  and startup script in /etc/profile.d/ to start mk
#TODO: add facter binary
#TODO: make sure /etc/network/interfaces has dhcp for some interface
build_apkovl_tar;

echo ""
echo "done."
