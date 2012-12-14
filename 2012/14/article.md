# Migrating Legacy (Physical) Servers into OpenStack

This was written by [Greg Retkowski](https://twitter.com/gregretkowski)

Many organizations have discovered the value of clouds and IaaS setups and may
be actively using Amazon EC2 or OpenStack. IaaS requires a shift in thinking:
from the state where a physical server has an expensive up-front cost but is a
peristent entity to one where a VM is very cheap to spin up or destroy, but
doesn't have persistent storage by default. The shift of old services into a
new IaaS Cloud is often time-consuming and prone to failures. It may often
require a ground-up re-engineering of all of your existing services to fit into
the new IaaS platform.

But can we do something short of re-engineering our services yet still retire
our legacy physical hardware by moving them to a cloud platform? Short answer:
Yes. This tutorial will show you how. We'll migrate a legacy physical server
into our OpenStack cloud and use a persistent volume so that the migrated VM
will be backed by persistent storage. The function provided by this legacy
server will be the same afterwards and will have the managability benefits from
running on an infrastructure platform.

## Enter OpenStack

I am running OpenStack (Folsom release) using CEPH for volume storage and flat
DHCP networking. The hypervisors are running Ubuntu Quantal. I used the
procedure described here to migrate a CentOS 5 system into OpenStack, but
you can use the same procedures to migrate just about any UNIX/Intel 32/64bit
OS.

I'd love to dive into the particulars on how to set up OpenStack, but there
already exists a ton of really good information and documentation on how to
deploy it. The best starting point is the excellent set of docs provided by the
OpenStack project at [http://docs.openstack.org/] .  I'll assume you've already
set up a tenant and user on your OpenStack cloud, and have given this
tenant/user enough of a quota to complete all the steps
below.

My instructions will be a mix of using the web UI and the command line to
accomplish the server transition. Before I get started, let's define some terms:

* horizon: the OpenStack Web-UI that is installed alongside OpenStack. 
* legacy server: is the old physical server (and the OS and data therein)
* instance: the vm, or virtual machine, running under OpenStack

## Create a 'Working' VM and a new Volume

You'll first need to create two things: a volume that will contain the data
from your legacy server and a 'working' VM as a way to work with that volume
throughout the migration process.

Start out in horizon dashboard. First go into 'volumes.'. 'Create Volume.' 
Name it something appropriate - like your legacy server's hostname. The volume
size should be large enough to store all the filesystems from your legacy
system, with appropriate growth, and include any swap-space you may need.

Next go into 'instances' and launch the 'working' instance we'll use to set up
this new volume. you can call it 'working' or whatever. I recommend you use a
system image as closely related to the OS on your legacy server as possible so
that the tools and libraries are similar.

This instance should have port 22 open under access and security, and you
should be sure your ssh key pair is placed onto the system. The flavor (size)
doesn't need any particular setting as this VM won't need many resources.
Nothing set under volume options either.

Launch the instance and allocate a floating IP to it.
Next, under 'volumes' attach your volume to the working instance. 

## Layout the Volume Disk

Login to the working instance. run 'dmesg' and you should see the message
indicating the volume was attached, i.e.
 
    "[   78.450985]  vdb: unknown partition table"

You'll need to now layout this device. Use 'fdisk' or your favorite partition
tool. In my example, I'll set up the first partition as my swap partition, and
the second partition as my root filesystem. If you have multiple partitions on
your legacy server, you have the choice to either put all the data onto a
single partition, have multiple data partitions on your volume, or even have
multiple volumes, and attach the additional volumes to your final VM at
boot-time. In my example, I use a single partition on the vm even though the
legacy server has multiple partitions.

Set up your swap partition(s) using mkswap, ala:

    mkswap /dev/vdb1

Now create a filesystem on the root partition, ext3, ext4, or whatever the old
system had as a root filesystem.

    mkfs.ext4 /dev/vdb2

If your old system had a disk label on the root partition set this up here too.
You can find out if it did by running 'e2label /dev/(myrootdev)' on your legacy
system. If so, add that label to your VM's root partition.

    e2label /dev/vdb2 my-new-label

Now, mount the newly created root partition. You'll need it mounted to sync the
data onto it from the legacy server.

    mkdir /legacy-system ; mount /dev/vdb2 /legacy-system

## Sync your Data

You will use rsync to synchronize files between your legacy system and your new
VM. The rsync tool is perfect for this for a few reasons: If interrupted, it
can resume where it left off. Further, it can be throttled so that data can trickle
over to the new volume without impacting the performance of the legacy server.

For minimal downtime you will need to do two separate rsyncs. The first one
will sync over the vast majority of the data from the legacy server to the
volume. The second one is done while both servers are down in order to sync
the final changes from the legacy server right before the replacement VM is
booted.

The first rsync will be run while your legacy system is still live and active.
This has the drawback that any actively-used files on the legacy system will be
corrupted on the VM's volume, but we'll be fixing that when we do the second
rsync. Remember, we're trying to minimize outages.

With the rsync, the important thing is that you exclude filesystems that are
mounted from remote systems or are kernel-managed virtual filesystems (like
/proc).

From your working VM, rsync the data over from your legacy system onto your
volume:

    rsync -av root@legacy-system:/ --exclude /proc --exclude /sys --exclude /dev/pts --exclude /dev/shm --exclude /dev /legacy-system/

The rsync will likely take many hours to complete, particularly if you are
throttling the bandwidth. Since you'll perform it while the legacy system is
still live, all services will remain available during the rsync.

## Changing System Configuration to Support Virtualization #

You will need to make some additional changes to your 'ed over system, to
support the new system running as a VM instead of directly on hardware.

First, create any directories that were explicitly skipped by the rsync, so that
they'll be mountable when the system boots:

    mkdir /legacy-system/{proc,dev,sys}

Update the /etc/fstab so that it'll mount the new swap and root correctly. The
changes to my fstab look like this:

    /dev/vda1       swap     swap   defaults        0 0
    /dev/vda2       /        ext4   defaults        0 0

Next update your network configuration so that the system gets its IP address
from DHCP. On redhat-derived systems, you'd typically edit
`/etc/sysconfig/network-scripts/ifcfg-eth0` and set `BOOTPROTO=dhcp`. On Ubuntu
systems, you'd edit `/etc/network/interfaces` and change it to contain `iface
eth0 inet dhcp`. I've glossed over this, you'll need to Google up on the
specifics for your OS. You may also need to make changes to `/etc/hosts`. Your
`/etc/resolv.conf` is typically overwritten by your DHCP client as part of
OpenStack's networking setup - so be prepared for that.

Your legacy system was likely configured with a publicly-available static IP
address. VMs inside OpenStack (specifically in flat DHCP mode) are all
assigned a private address via DHCP, and then the public (termed 'floating') IP
address is associated with the VM by associating it with the private DHCP
address via iptables on the hypervisor.

## Installing the Bootloader #

The next step is to make the volume bootable by adding a bootloader at the
beginning of the volume. There's many variations of bootloaders, and even the
most common bootloader (grub) has several variations. 

If your bootloader is configured to boot via a disk label (i.e.
`root=LABEL=some-name`) and you've already set that label when configuring the
volume you won't need to change your grub config. Otherwise you may need to
edit either `/boot/grub/menu.1st` or `/etc/grub.conf`, and make sure the kernel
command line is set to `root=/dev/vda2`

Now, install grub on your volume from within your working VM by issuing:

    grub-install --root-directory=/legacy-server /dev/vdb

You may optionally need to create an initrd with virtio drivers, and then
update your grub configuration to boot it:

    chroot /legacy-server
    mkinitrd --with virtio_pci --with virtio_blk -f /boot/initrd-${legacy_kern_vers}.img ${legacy_kern_vers}

Your volume should be ready for the final steps to replace your legacy system.

## Adding a Security Group and Floating IP

OpenStack provides firewalling, so you will need to set up a special
security-group for your VM that allows all expected traffic to reach
the server. This is done under "Access & Security" in horizon. 

Click "Create Security Group", name the group and description, and then click
'Create'. Next, go into 'Edit Rules' for the new group, and add the rules you
need. I added a group called 'wide-open' where I allowed all traffic, because
my legacy system is already locked-down via iptables. To do that add a rule for
TCP, and UDP allow ports 1 to 65535, and ICMP that allow -1 to 65535. 

Next, add the IP address of the legacy server as a floating IP address in
OpenStack. From your OpenStack controller node, use the nova-manage tool to add
the IP to the nova database:

    nova-manage floating create --ip_range=1.2.3.4 --pool nova

If you have a single-tenant setup, you can allocate the IP to your tenant
by running `nova floating-ip-create`. If you haven't already allocated all
previously-defined floating IP's then you may need to repeatedly run
`floating-ip-create` until you get the IP you need, then release the IP's you
don't need via `floating-ip-delete`.

## Preflight before the Change-Over #

Before committing to the change-over you should verify that your newly-created
bootable volume does indeed work as expected.

First, unmount all of the volume's filesystems from the working VM, and then
detach it through the 'Volumes' page in Horizon.

Next, launch the new VM through the 'Instances' page. Select the 'Image' that
most closely resembles your VM's OS (it isn't used, but you still need to
specify it). Set the image name appropriately (i.e. the hostname of your legacy
server) and select a flavor with sufficient memory and CPU's for your new VM.
On the 'Access & Security' tab, check the Security Group you set up. Then under
"Volume Options" select "Boot from Volume", select your volume, and add a
device name (it is unused, but must be filled in). Be sure 'Delete on
Terminate' is NOT checked. Click 'Launch'.

Your instance should show up in the 'Instances' page. Once it is in state
"running," click on the hostname link for it, and go to the 'VNC' tab.. This
will allow you to follow along as the system boots, and see any signs of
trouble if there are problems. If all goes well, you will see all the services
start and be at a login prompt.

## The Cut-Over #

Once you've verified your VM is setup correctly, shut it down and re-mount it
on your working VM.  Boot your legacy server to single-user, start the
network, then do the final rsync to your new VM's volume on the working VM.
Exclude /etc and /boot to avoid overwriting the changes you made to files in
those directories.

    rsync -av / --exclude /etc --exclude /boot --exclude /proc --exclude /sys --exclude /dev/pts --exclude /dev/shm --exclude /dev root@working:/legacy-system/

Once you've finished the rsync, unmount the volume from your working VM, and
power down your legacy server. Launch your new VM system, and as it is booting,
associate the floating IP address with it.

One side-effect OpenStack networking is that connections that originate from
your VM directed to the Floating IP for it will fail. If your VM depends on
this working you can add the following IPTables rule as part of your VM
start-up scripts:

    iptables -A OUTPUT -d ${YOUREXTIP} -j DNAT --to-destination 127.0.0.2

## Conclusion #

You now have a VM that's cloned from your legacy server and running inside your
OpenStack environment, so your legacy server can be retired! This procedure
can be applied (with a few tweaks) to migrate servers into public clouds that
support bootable volumes, such as Amazon AWS, or Rackspace's OpenStack-based
cloud.

Migrating your server into your cloud this way allows you to continue
supporting legacy systems while improving flexibility and operational control.
I hope you found this article informative and useful. Feel free to contact me
and I'll help you through them!

## Further Reading

* [Dope 'n Stack](http://www.dopenstack.com/)
* [Getting Started with OpenStack](http://wiki.openstack.org/GettingStarted)

