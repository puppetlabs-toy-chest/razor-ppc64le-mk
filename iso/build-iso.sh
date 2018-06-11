#!/bin/sh
#Written by Mick Tarsel
#setup the env to build a ppc64le vanilla iso for razor
# https://wiki.alpinelinux.org/wiki/How_to_make_a_custom_ISO_image_with_mkimage

# HOW IT WORKS:
# setup repositories, build razor gems, convert gems into .apks, 
  #setup razor scripts, pull aports repo, build razor profile into .iso image.

# where scripts and gems will exist so genapkovl can grab them
BUILD_DIR=/etc/razor-build

#clear it
echo >  /etc/apk/repositories

# add just what we want
echo "http://dl-5.alpinelinux.org/alpine/edge/main/" >> /etc/apk/repositories
echo "http://dl-5.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories
echo "http://dl-cdn.alpinelinux.org/alpine/v3.7/main" >> /etc/apk/repositories
echo "http://dl-cdn.alpinelinux.org/alpine/v3.7/community" >> /etc/apk/repositories

apk del ruby ruby-dev
apk update

# build dependices from wiki and razor 
apk add alpine-sdk build-base apk-tools alpine-conf busybox fakeroot xorriso ruby ruby-dev

# needed to build the razor-mk-agent.gem and convert gems to .apks
gem install etc fpm facter rake bundler --no-document

# according to wiki, need this use to build .iso
adduser build -G abuild
addgroup root abuild
abuild-keygen -i -a

#TODO some stat errors
cp /root/.abuild/root-*.rsa.pub /etc/apk/keys
cp /root/.abuild/root-*.rsa.pub /etc/apk/keys.pub

# setup dir for building gems and apks
mkdir -p $BUILD_DIR/my-gems

# build custom razor-mk-agent.gem
bundle install
bundle exec rake build

# location of razor-mk-agent-008.gem
cp ./pkg/*.gem $BUILD_DIR/my-gems

# local install facter gem
mkdir -p $BUILD_DIR/my-gems/facter
gem install facter --no-document -i $BUILD_DIR/my-gems/facter

# move all gems for .iso in /etc/razor-build/my-gems
cp $BUILD_DIR/my-gems/facter/cache/*.gem $BUILD_DIR/my-gems
rm -rf $BUILD_DIR/my-gems/facter #remove extra build dirs

#need to comment out a line to get working apk
fpm_file=$(find /usr/lib/ruby | grep apk.rb) 
#line 255 #full_record_path = add_paxstring(full_record_path)
cp -f ./apk.rb $fpm_file

#build 2 apks from 2 gems
fpm -n facter -a ppc64le -s gem -t apk $BUILD_DIR/my-gems/facter-2.5.1.gem
fpm -n razor-mk-agent -a ppc64le -s gem -t apk $BUILD_DIR/my-gems/razor-mk-agent-008.gem

#copy apks in current dir to build folder so mkimg.base can copy them into iso
cp ./*.apk $BUILD_DIR/my-gems
# custom apks are also stored in /etc/razor on build machine as a backup

#sign the apks
abuild-sign $BUILD_DIR/my-gems/*.apk

#TODO Is this all the files we need for mk? what about ./lib/
# move shell scripts used by mk OpenRC service 
cp ./bin/mk-register $BUILD_DIR
cp ./bin/mk-update $BUILD_DIR
cp ./bin/mk $BUILD_DIR/mk.rb # eventully this will be renamed to just mk

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
