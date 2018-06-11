#!/sbin/openrc-run
name="mk"
description="Interact with Razor server"
depend() {
    need net
    use dns logger
}
start_pre() {
		#make sure packages are already installed.
		apk add /etc/razor/apks/* --allow-untrusted
		#command will fail on build, but service will start ok

		#dir and files specified in verify_pxe_initramfs() in setup-razor-env.sh
		if [ ! -f /usr/local/bin/mk-register ]; then
			chmod +x /etc/razor/mk*
			cp /etc/razor/mk* /usr/local/bin
		fi

    sleep 30
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
