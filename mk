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
	#this should be part of the initrd so facter should always be installed
	apk add facter --allow-untrusted
	apk add razor-mk-agent --allow-untrusted
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
