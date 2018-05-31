#!/bin/sh -e

HOSTNAME="$1"
if [ -z "$HOSTNAME" ]; then
	echo "usage: $0 hostname"
	exit 1
fi

cleanup() {
	rm -rf "$tmp"
}

makefile() {
	OWNER="$1"
	PERMS="$2"
	FILENAME="$3"
	cat > "$FILENAME"
	chown "$OWNER" "$FILENAME"
	chmod "$PERMS" "$FILENAME"
}

rc_add() {
	mkdir -p "$tmp"/etc/runlevels/"$2"
	ln -sf /etc/init.d/"$1" "$tmp"/etc/runlevels/"$2"/"$1"
}

tmp="$(mktemp -d)"
trap cleanup EXIT

mkdir -p "$tmp"/etc
makefile root:root 0644 "$tmp"/etc/hostname <<EOF
$HOSTNAME
EOF

mkdir -p "$tmp"/etc/network
makefile root:root 0644 "$tmp"/etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF

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
mkinitfs
EOF


mkdir -p "$tmp"/etc/apk
makefile root:root 0644 "$tmp"/etc/motd <<EOF
Welcome to the Razor Microkernel!

To generate a PXE bootable image execute the following:
  echo "/usr/share/udhcpc/default.script" > /etc/mkinitfs/features.d/dhcp.files
  echo "kernel/net/packet/af_packet.ko" > etc/mkinitfs/features.d/dhcp.modules
  echo "kernel/fs/nfs/*" > /etc/mkinitfs/features.d/nfs.modules
  echo 'features="ata base bootchart cdrom cramfs ext2 ext3 ext4 xfs floppy keymap kms raid scsi usb virtio squashfs network dhcp nfs"' > /etc/mkinitfs/mkinitfs.conf

  mkinitfs -o /root/pxerd

  View these commands in /etc/motd
EOF


BUILD_DIR=/etc/razor-build
#/etc/razor-build exists on machine creating .iso (build machine)

#TODO only need the 3 scripts? 
#scripts used by mk service
mkdir -p "$tmp"/etc/razor
cp $BUILD_DIR/mk* "$tmp"/etc/razor

#just a backup to make sure apks are somewhere on iso
cp $BUILD_DIR/my-gems/*.apk "$tmp"/etc/razor

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
    if [ ! -f /usr/bin/facter ]; then
	apk add /media/cdrom/apks/ppc64le/facter*.apk --force-non-repository --allow-untrusted
	apk add /media/cdrom/apks/ppc64le/razor-mk-agent*.apk --force-non-repository --allow-untrusted
   	mkdir -p /usr/local/bin 
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

# add our custom razor service to default run level
rc_add mk default

rc_add mount-ro shutdown
rc_add killprocs shutdown
rc_add savecache shutdown

tar -c -C "$tmp" etc | gzip -9n > $HOSTNAME.apkovl.tar.gz
