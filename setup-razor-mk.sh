#!/bin/sh

#Setup the razor mk service
# this script will execute upon bootmisc

#written by Mick Tarsel

BUILD_DIR=/etc/razor

setup_mk_service() {
  echo ""
  echo "Setting up mk service..."
  echo ""

  cd $BUILD_DIR
  mkdir -p /usr/local/bin
  chmod +x $BUILD_DIR/mk*
  cp  $BUILD_DIR/mk* /usr/local/bin

  if [ ! -f /etc/init.d/mk ]; then
    cp $BUILD_DIR/mk /etc/init.d/
    rc-update add mk default
  fi
}

setup_mk_service;

echo "Starting mk service..."
echo ""
/etc/init.d/mk start