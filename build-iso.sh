#!/bin/sh
#Written by Mick Tarsel
#setup the env to build a ppc64le vanilla iso for razor
# https://wiki.alpinelinux.org/wiki/How_to_make_a_custom_ISO_image_with_mkimage

# where scripts and gems will exist so genapkovl can grab them
BUILD_DIR=/etc/razor-build

#clear it
echo >  /etc/apk/repositories

# add just what we want
echo "http://dl-5.alpinelinux.org/alpine/edge/main/" >> /etc/apk/repositories
echo "http://dl-5.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories
echo "http://dl-cdn.alpinelinux.org/alpine/v3.7/main" >> /etc/apk/repositories
echo "http://dl-cdn.alpinelinux.org/alpine/v3.7/community" >> /etc/apk/repositories

# build dependices from wiki
apk update
apk add ruby alpine-sdk build-base apk-tools alpine-conf busybox fakeroot xorriso git

# needed to build the razor-mk-agent.gem
gem install facter rake bundler --no-document

# according to wiki, need this use to build .iso
adduser build -G abuild
addgroup root abuild
abuild-keygen -i -a

#TODO some stat errors
cp /root/.abuild/root-*.rsa.pub /etc/apk/keys
cp /root/.abuild/root-*.rsa.pub /etc/apk/keys.pub

# build customer razor-mk-agent.gem
bundle install
bundle exec rake build

mkdir -p $BUILD_DIR/my-gems
mkdir -p $BUILD_DIR/my-gems/facter

# local install these gems so genapkovl can grab them
gem install facter --no-document -i $BUILD_DIR/my-gems/facter

# move all gems for .iso in /etc/razor-build/my-gems
cp $BUILD_DIR/my-gems/facter/cache/*.gem $BUILD_DIR/my-gems
rm -rf $BUILD_DIR/my-gems/facter

# location of razor-mk-agent-008.gem
cp ./pkg/*.gem $BUILD_DIR/my-gems

# move shell scripts used by mk OpenRC service 
cp ./bin/mk-register $BUILD_DIR
cp ./bin/mk-update $BUILD_DIR
cp ./bin/mk $BUILD_DIR/mk.rb # eventully this will be renamed to just mk

# repo with build scripts
git clone https://github.com/alpinelinux/aports.git
# copy my custom razor profile
cp genapkovl-razor.sh ./aports/scripts
cp mkimg.razor.sh ./aports/scripts

cd aports/scripts

# where .iso will be once complete
mkdir -p ~/iso

# build the .iso for ppc6l4 using razor profile and output to ~/iso
# the edge repo has the kernel and other special apks so need to use it
sh mkimage.sh --tag main --outdir ~/iso --arch ppc64le --repository http://dl-cdn.alpinelinux.org/alpine/edge/main --profile razor
