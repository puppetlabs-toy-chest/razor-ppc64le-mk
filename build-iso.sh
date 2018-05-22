#!/bin/sh
#Written by Mick Tarsel
#setup the env to build a ppc64le vanilla iso for razor

#clear it
echo >  /etc/apk/repositories

# add just what we want
echo "http://dl-5.alpinelinux.org/alpine/edge/main/" >> /etc/apk/repositories
echo "http://dl-5.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories
echo "http://dl-cdn.alpinelinux.org/alpine/v3.7/main" >> /etc/apk/repositories
echo "http://dl-cdn.alpinelinux.org/alpine/v3.7/community" >> /etc/apk/repositories

apk update

apk add ruby alpine-sdk build-base apk-tools alpine-conf busybox fakeroot xorriso git

gem install facter rake bundler --no-document

adduser build -G abuild
addgroup root abuild
abuild-keygen -i -a

#TODO some stat errors
cp /root/.abuild/root-*.rsa.pub /etc/apk/keys
cp /root/.abuild/root-*.rsa.pub /etc/apk/keys.pub
apk update

bundle install
bundle exec rake build

#TODO rename to razr-build
#all files included in apkovl will be in /etc/apker on build machine
mkdir -p /etc/apker/my-gems
mkdir -p /etc/apker/my-gems/facter

gem install facter --no-document -i /etc/apker/my-gems/facter

#all gems for .iso in /etc/apker/my-gems
cp /etc/apker/my-gems/facter/cache/*.gem /etc/apker/my-gems
rm -rf /etc/apker/my-gems/facter

cp ./pkg/*.gem /etc/apker/my-gems
cp ./etc/mk /etc/apker #created from genapkovl, this is just a backup
cp ./bin/mk-register /etc/apker
cp ./bin/mk-update /etc/apker
cp ./bin/mk /etc/apker/mk.rb

cd ../

git clone https://github.com/alpinelinux/aports.git
cp genapkovl-razor.sh ./aports/scripts
cp mkimg.razor.sh ./aports/scripts

cd aports/scripts

mkdir -p ~/iso

sh mkimage.sh --tag main --outdir ~/iso --arch ppc64le --repository http://dl-cdn.alpinelinux.org/alpine/edge/main --profile razor
