# Razor Microkernel for ppc64le
Build Alpine Linux 3.7.0 ppc64le tarball to use as the Razor microkernel.

x86 info: https://github.com/puppetlabs/razor-el-mk/blob/master/README.md

# How to Run
Setup an Alpine ppc64le machine. We recommend Alpine 3.8 but its not necessary. 

Clone this repo an run the setup script:

```bash
./setup-razor-env.sh
```
To reset the install and run it again (will delete everything built)

```bash
./cleanup.sh
```

# Example pxelinux file (kernel commands)

Please edit the append lines with your settings. The below file is an example.

Ensure the apkovl is accessible. 

```
default microkernel

label microkernel
   kernel http://dl-master.alpinelinux.org/alpine/v3.8/releases/ppc64le/netboot-3.8.0/vmlinuz-vanilla
   initrd http://dl-master.alpinelinux.org/alpine/v3.8/releases/ppc64le/netboot-3.8.0/initramfs-vanilla
   append apkovl=http://your-apkovl-location ip=client-ip:server-ip:gw-ip:netmask:hostname:device:-:8.8.8.8:8.8.4.4 modloop=http://dl-cdn.alpinelinux.org/alpine/v3.8/releases/ppc64le/netboot/modloop-vanilla modules=loop,squashfs,sd-mod,usb-storage,ibmvscsi powersave=off alpine_repo=http://dl-cdn.alpinelinux.org/alpine/v3.8/main/
```

# Developer Notes
Some helpful tidbits of why something is implemented a certain way. Helpful for other devs.

## Installing Razor files for microkernel
We have 2 gems which need to be included for Razor: facter and razor-mk-agent. In summary, we convert these gems into apks - Alpine's package format. Facter is locally installed as a gem. razor-mk-agent is built from the code in this repo. Once both gems exist, we will convert the gems to apks using fpm. Look at ```create_apks_from_gems()``` 

**These custom built apks should not be installed on the build machine.** This script will double check these are not installed and remove Facter or razor-mk-agent if they are installed. The reason these cannot be installed is because the apkovl will not contain these installed apks files, such as /usr/bin executables, however the /etc/apk/world file says those package are installed and thers a problem.

Please note we use a modified version of fpm. Our 'local fork' replaces source code.


## apkovl and the root filesystem
In this version, we are using an apkovl as a kernel command. The apkovl.tar.gz is just a normal tarball. The ```setup-razor-env.sh``` will create an apkovl automatically which will contain the following:
* ```/etc/profile.d/setup-razor-mk.sh```: this will install the apks and start the ```mk``` service. Basically setup the microkernel environment once the kernel is booted.
* ```/etc/razor/```: contains the ```mk```service, facter and razor-mk-agent apks, and other Ruby files needed for Razor.

After running ```setup-razor-env.sh```, look in the *apkovl/* directory and place the apkovl.tar.gz in a location which can be accessed by the ppc64le we are going to provision with Razor.


# Links
More info:

https://wiki.alpinelinux.org/wiki/Upgrading_Alpine#Upgrading_to_latest_release

https://wiki.alpinelinux.org/wiki/Custom_Kernel

https://wiki.alpinelinux.org/wiki/Alpine_local_backup

https://wiki.alpinelinux.org/wiki/Ppc64le
