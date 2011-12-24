Linux Containers (LXC)
======================

<i>This article was written by Ken Barber (http://bob.sh/).</i>

Introduction
-------------

Linux Containers (abbreviated as _LXC_) provide a kind of virtual machine that
operates within an operating system. For clarity and to keep the semantical
pedants happy, this kind of virtualisation is often dubbed "Operating
system-level virtualisation." This provides an alternative (or arguably a
subset) to what is known as "platform virtualisation" solutions such as KVM,
Xen or Vmware.

In the past, we have often used chroot jails to achieve this kind of effect,
and products like LXC are simply a modern evolution of this old idea by
including isolation and resource management through extensions to the kernel.

This is by no means a new idea. Other examples of technologies like this
already include:

 * Solaris Zones
 * BSD Jails
 * OpenVZ
 * Linux vserver
 * FreeVPS

What makes LXC the topic of discussion, here, is that its development has
recently made it into the Linux kernel as an official mechanism for providing
containers. While these features are always improving, LXC is reaching a
stage where it can be considered for production (depending on your level of
conservatism, of course), and I feel that it deserves some well earned
attention.

Platform vs. OS-level virtualisation
-------------------------------------

LXC, as mentioned, provides operating system-level virtualisation. For better
or worse this means programs still run in the main OS, so only one kernel is
ever in operation. This may be an advantage or a disadvantage depending on what
you are trying to achieve. Having said that, it provides a level of isolation
that is similar to other virtualisation techniques.

For example, if you wish to run a large number of Apache instances while
ensuring they are isolated from each other, then LXC is a good fit. Doing
this same job using platform virtualisation can add resource overhead thereby
not providing the same level of scalability.

I often found that using full virtualisation was wasteful in cases where the
instance was created for isolation purposes (which can be handy) but the usage
itself was very low. Small mysql databases often need isolation due to
differing cache and tuning requirements (and my desire to not have an
application kill a shared database platform) but having extra copies of
net-snmp and ssh and other system and support tools was wasteful.

On the other hand, if you want to provide complete environments to different
groups or customers including SSH, specific OS distributions and kernel
revisions then platform virtualisation might be a better fit.

Its all about common sense and finding the right fit. Sometimes the best fit
is often a hybrid one. The good news is that libvirt supports LXC now, which
means provisioning LXC and KVM (for example) can be managed with the same tool.
Also, you can run LXC containers inside a platform virtualised environment.
This means you can have LXC containers inside KVM for example, allowing you to
create quite interesting mixes of the technologies.

The Technology
-------------------------------------

LXC works to provide instance isolation and resource control by using several
techniques:

 * chroot
 * namespace
 * cgroups

A *chroot* is an old technique for providing application security through file
access isolation. It provides a way to "re-root" a program so that it is not
able to access files above that directory. For example if you chroot'd an
application to /srv/foo, the application would see / (which is really /srv/foo
on the host) only and not be able to access /srv/bar.

The *namespace* feature was developed as part of LXC. It allows you to isolate
resources from each other. These resources can be process IDs, networking
information (routes, iptables, interfaces etc.), ipc, and mounts.  Much like a
chroot works for files, namespace control allows you to isolate process lists
so container A cannot see container B's processes.

*cgroups* was also developed as part of LXC. It allows you to logically bundle
together resources and apply resource management, accounting, isolation and
other policies to them. This feature provides you with proper control of your
container, not just by hiding information but by providing constraints around
it.

Together, the complete effect is that a virtual environment created with LXC
can be created that in effect looks like a real machine (or perhaps a full
virtual machine) but really the processes and functions within it run within
the host os's kernel.

Installation
-------------------------------------

This installation guide here is based around Ubuntu or Debian. A lot of the
concepts are the same however on other distributions, and the user space tools
for LXC should be roughly identical.

To begin with, we'll need some tools. You will need to install the following
packages:

    apt-get install lxc bridge-utils debootstrap

Now, for networking its best to place your primary interface inside a bridge.
You can achieve this by modifying /etc/network/interfaces as such:

    # The primary network interface
    #allow-hotplug eth0
    #iface eth0 inet dhcp

    auto br0
    iface br0 inet dhcp
           bridge_ports eth0
           bridge_fd 0
           bridge_maxwait 0

To configure cgroups, you need a special mount (its much like the proc or sys
filesystem). Create a new entry in /etc/fstab like so:

    cgroup          /cgroup         cgroup  defaults        0       0

Then create the /cgroup directory and mount it.

    mkdir -p /cgroup
    mount /cgroup

The /cgroup mount can be poked by hand (like /proc) to adjust various resource
settings. Later we'll talk about how resource management can be controlled
using lxc user space tools.

Manipulating Containers
-------------------------------------

Once you have done the preliminary steps, you can now start creating and working
with containers. Try creating a container named 'vm0' by typing the following
commands:

    mkdir -p /var/lib/lxc/vm0
    /usr/lib/lxc/templates/lxc-debian -p /var/lib/lxc/vm0/

The command lxc-debian is in fact one of a few a wrapper scripts that
simplifies the container creation process. It performs a number of tasks for
you:

 * Downloads a minimal debian root using 'debootstrap' from
   http://ftp.debian.org/ to /var/lib/lxc/vm0/rootfs
 * Configures inittab, hostname, locale and networking for the container
 * Removes any unnecessary services such as hwclock and umountfs
 * Sets the root password to 'root'
 * Creates a configuration file in /var/lib/lxc/vm0/config

Of course you are always free to create your own script or to modify this one. In
most cases if you are looking to provision lots of containers that perform
similar functions its recommended that you tailor your own template to your
needs.

There are a number of lxc command line tools for manipulating containers. Most
of these are fairly self-explanatory by looking at their name. Lets start by
getting a list of instances:

    # lxc-ls

Then getting state information on the instance you just created:

    # lxc-info --name vm0

Once prepared, you can start the container in the background with:

    # lxc-start -d --name vm0

Then connect to the console of your container using:

    # lxc-console --name vm0

At this point you will be prompted with a Linux console login prompt. Log into
the console using root/root and take a look around. You will notice that a 'ps
auxw' results in only a small number of processes. Try the same in your main
OS, and you will see that you can see these processes as well, however the PIDs
are different.

 

Doing a pstree -pl however, allows you to see the relationship to a container
easily enough:

    |-lxc-start(22715)---init(22716)---dhclient3(22917)
    |                                |---getty(23006)
    |                                |---getty(23008)
    |                                |---getty(23009)
    |                                |---getty(23010)
    |                                \---login(23007)---bash(23013)

Notice how the container has its own copy of init? This provides a convenient
(and familiar) parent supervisor for all processes running in your container.
Modifying the containers /etc/inittab works just like the real thing, too.

To view container processes clearly from your real OS use this command:

    # lxc-ps --name vm0

Or, to see the processes for all containers (including a column which tells you
which container they are in) try:

    # lxc-ps --lxc

Now to exit out of your console, type Ctrl-A then q. You can then shutdown your
instance with:

    # lxc-stop --name vm0

Finally - if you wish to destroy your vm, simply do this with:

    # lxc-destroy --name vm0

This will delete the rootfs and configuration permanently.

Resource Management
-------------------------------------

Resource management is taken care of by the cgroups kernel feature.

CPU resource allocation can be done a number of ways, by either pinning CPU
affinity or by providing shares. For example, to control CPU affinity for our
process, you can use the `lxc-cgroup` command. First of all lets find out what
the current setting is:

    # lxc-cgroup -n vm0 cpuset.cpus
    0-1

This means that vm0 can use CPU 0 or 1. You can adjust this by providing a new
value:

    # lxc-cgroup -n vm0 cpuset.cpus '0'

Now our container processes will only schedule on CPU 0. The alternative is to
adjust shares, thereby defining priority of instances:

    # lxc-cgroup -n vm0 cpu.shares '2048'

    # lxc-crgoup -n vm1 cpu.shares '1024'
 
The above command signifies that vm0 will get twice as much priority as vm1.

If you are looking to permanent change these settings for a specific container,
modify the containers configuration file: `/var/lib/lxc/vm0/config` (for container 'vm0')

For example, to add a specific cpu affinity and share to the container add the
line:

    lxc.cgroup.cpuset.cpus = 0
    lxc.cgroup.cpuset.shares = 2048

There are lots of settings regarding resource management. Its recommended to
read the cpuset.txt documentation (see references) for futher details.

Other Cool Stuff
-------------------------------------

For those cases where you want to pause a container, freezing and unfreezing
instances can be done simply with:

    # lxc-freeze --name vm0
    # lxc-unfreeze --name vm0

If you want the power of LXC but don't want the hassle of creating an
environment first a temporary container for running a job can be created simply
with:

    # lxc-execute -n temp1 -- 'top'

This container can benefit from cgroups management and namespace isolation just
like a real container so may come in handy for wrapping application executions.

For fun, I recommend trying some of the other templates available in /var/lib/
lxc/templates. If you install the package 'febootstrap' you can try out
lxc-fedora which installs a mini Fedora root for you to use inside Debian
and Ubuntu.

Conclusion
-------------------------------------

I have only touched upon a number of functions within this LXC introduction,
so I recommend researching further if you wish to implement this in the wild.

In the mass-hysteria that is the 'Cloud' it's easy to forget that the solution
is all about the problem, not the other way around. There is no doubt that at
times containers and LXC will provide a neat alternative to platform
virtualisation but sometimes this will be the other way around. This of course
as usual depends on the problem at hand.

As you can see, LXC is pretty straight-forward. Be sure to try alternative
container tools I listed as well, as LXC may not suite your needs (or taste)
exactly. Lasty, anything new and adventurous should be thoroughly tested
before production deployment to avoid late night adventures.


Further reading:

 * [LXC at wiki.debian.org](http://wiki.debian.org/LXC)
 * [LXC on Wikipedia](http://en.wikipedia.org/wiki/Lxc)
 * [cgroups on Wikipedia](http://en.wikipedia.org/wiki/Cgroups)
 * [cgroups documentation](http://www.mjmwired.net/kernel/Documentation/cgroups.txt)
 * [A Five Minute Guide to LXC for Debian](http://nigel.mcnie.name/blog/a-five-minute-guide-to-linux-containers-for-debian)
 * [IBM developerWorks on LXC](http://www.ibm.com/developerworks/linux/library/l-lxc-containers/)
 * [fakeroot - a userland hack for faking root privileges for file manipulation](http://linux.die.net/man/1/fakeroot)

