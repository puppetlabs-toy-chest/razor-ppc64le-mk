#!/bin/sh
#Written by Mick Tarsel
#setup the env to build a ppc64le vanilla iso for razor
# https://wiki.alpinelinux.org/wiki/How_to_make_a_custom_ISO_image_with_mkimage

# HOW IT WORKS:
# setup repositories, create razor gems, turn gems into .apks, setup razor scripts, 
#	pull aports repo, build razor profile into .iso image.

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
apk add alpine-sdk build-base apk-tools alpine-conf busybox fakeroot xorriso 'ruby<2.5.1' ruby-dev

# needed to build the razor-mk-agent.gem
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
mkdir -p $BUILD_DIR/my-gems/facter

# build custom razor-mk-agent.gem
bundle install
bundle exec rake build

# location of razor-mk-agent-008.gem
cp ./pkg/*.gem $BUILD_DIR/my-gems

# local install facter gem
gem install facter --no-document -i $BUILD_DIR/my-gems/facter

# move all gems for .iso in /etc/razor-build/my-gems
cp $BUILD_DIR/my-gems/facter/cache/*.gem $BUILD_DIR/my-gems
rm -rf $BUILD_DIR/my-gems/facter #remove extra dirs

#pwd: /root/testski/razor-ppc64le-mk

#TODO create .apk from gems in $build_dir/my_gems
# find / | grep apk.rb (line 255)
# #full_record_path = add_paxstring(full_record_path)
./fpm -n factor -a ppc64le -s gem -t apk $BUILD_DIR/my-gems/facter-2.5.1.gem
./fpm -n razor-mk-agent -a ppc64le -s gem -t apk $BUILD_DIR/my-gems/razor-mk-agent-008.gem
#stores apks in current dir
cp ./*.apk $BUILD_DIR/my-gems
#move the apks to a dir where mkimg.base.sh can grab them and put on iso
# custom apks are also stored in /etc/razor on build machine as a backup

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
