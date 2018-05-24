#!/bin/sh -e

HOSTNAME="$1"
if [ -z "$HOSTNAME" ]; then
	echo "usage: $0 hostname"
	exit 1
fi

cleanup() {
	rm -rf "$tmp"
}

# make a file with permissions and owners
makefile() {
	OWNER="$1"
	PERMS="$2"
	FILENAME="$3"
	cat > "$FILENAME"
	chown "$OWNER" "$FILENAME"
	chmod "$PERMS" "$FILENAME"
}

# add a service to the run level and setup system links
rc_add() {
	mkdir -p "$tmp"/etc/runlevels/"$2"
	ln -sf /etc/init.d/"$1" "$tmp"/etc/runlevels/"$2"/"$1"
}

# if that dir aint made, exit
tmp="$(mktemp -d)"
trap cleanup EXIT

# hostname is set at boot so initialize hostname here
mkdir -p "$tmp"/etc
makefile root:root 0644 "$tmp"/etc/hostname <<EOF
$HOSTNAME
EOF

#setup interface files since networking is in boot runlevel(started at boot)
mkdir -p "$tmp"/etc/network
makefile root:root 0644 "$tmp"/etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF

# packages we will pull off of the loop mounted iso
mkdir -p "$tmp"/etc/apk
makefile root:root 0644 "$tmp"/etc/apk/world <<EOF
alpine-base
bkeymaps
alpine-base
alpine-mirrors
network-extras
openssl
openssh
chrony
tzdata
ruby
ruby-rake
ruby-bundler
net-tools
EOF

#/etc/razor-build exists on build machine
BUILD_DIR=/etc/razor-build

#/etc/gems and /etc/razor will be on machine we want to get info for
mkdir -p "$tmp"/etc/gems
cp $BUILD_DIR/my-gems/*.gem "$tmp"/etc/gems

#/etc/razor contains scripts utilized by our service
mkdir -p "$tmp"/etc/razor
cp $BUILD_DIR/mk* "$tmp"/etc/razor

# below writes the OpenRC service script. responsible for executing 
  # other sh scripts and ruby scripts to send data back to razor server
mkdir -p "$tmp"/etc/init.d/
makefile root:root 0755 "$tmp"/etc/init.d/mk <<EOF
#!/sbin/openrc-run

name="mk"
description="Interact with Razor server"

depend() {
    need net
    use dns logger
}

start_pre() {
    sleep 30
    if [ ! -f /usr/local/bin/mk ]; then
	mkdir -p /usr/local/bin
	/usr/bin/gem install --local /etc/gems/*.gem --no-document -n /usr/local/bin
	mv /etc/razor/mk-* /usr/local/bin
	chmod +x /usr/local/bin/mk*
    fi
}

start() {
    ebegin "Starting mk"
    start-stop-daemon \
    --background --start \
    --exec /usr/local/bin/mk-register \
    --make-pidfile --pidfile /var/run/mk.pid
    eend $?
}

stop() {
    ebegin "Stoping mk"
    start-stop-daemon --stop \
    --exec /usr/local/bin/mk-register \
    --pidfile /var/run/mk.pid
    eend $?
}

EOF

rc_add devfs sysinit
rc_add dmesg sysinit
rc_add mdev sysinit
rc_add hwdrivers sysinit
rc_add modloop sysinit

rc_add hwclock boot
rc_add modules boot
rc_add sysctl boot
rc_add hostname boot
rc_add bootmisc boot
rc_add syslog boot
rc_add networking boot

# add out new service to default runlevel
rc_add mk default

rc_add mount-ro shutdown
rc_add killprocs shutdown
rc_add savecache shutdown

tar -c -C "$tmp" etc | gzip -9n > $HOSTNAME.apkovl.tar.gz
