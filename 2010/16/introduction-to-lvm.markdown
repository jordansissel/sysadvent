# Introduction to LVM

_This was written by [Ben Cotton](http://www.funnelfiasco.com/) ([@funnelfiasco](http://twitter.com/funnelfiasco))_

Logical volume management (LVM) is not a new concept -- it first appeared in
Linux in 1998 and had existed in HP-UX before then.  Still, some sysadmins, new
and old, aren't familiar with it.  LVM is a form of storage virtualization that
allows for more configuration flexibility than the traditional on-disk
partitions.  In fact, LVM is a kind of anti-partitioning, where multiple
devices can be grouped together.  In this article, we'll assume you've got a
spare machine or VM to follow along on.  If not, you can use losetup to create
file-based "disks" (see the [man page](http://linux.die.net/man/8/losetup) for
instructions).
 
LVM setup starts with physical volumes. You mark disk devices (drives or
partitions) as physical volumes with the
[pvcreate](http://linux.die.net/man/8/pvcreate) command.  Physical volumes are
then grouped together into one or more volume groups with vgcreate.  It's most
common to create a single volume group, but there are cases when multiple
volume groups might be desirable.  For example, one vg may be created on a
solid-state drive to use for read-mostly data, with spinning disk(s) in a
separate vg for more volatile data.  
 
    # Initialize two drives for use in LVM
    pvcreate /dev/sda1 /dev/sdb1
    # Create a single volume group called "myvg"
    vgcreate myvg /dev/sda1 /dev/sdb1
 
Once the vg is created, you can generally think of it as a single disk.
Instead of partitioning it as you would with a traditional flat disk, space is
carved up by creating logical volumes with
[lvcreate](http://linux.die.net/man/8/lvcreate).  After a lv is created,
any OS-supported file system can be made on it.  (Note: it's important to
consider your use case when selecting the file system to put on an lv.  Not
only do file systems have different performance characteristics, but if you
want to grow or shrink the file system later, you'll have to use a file system
that supports such operations.  XFS and JFS in particular do not support
shrinking.)  
 
    # Create a 10 GB logical volume for MySQL in myvg
    lvcreate -L 10G -n mysql myvg
    # Create a 1 TB logical volume for MythTV in myvg
    lvcreate -L  1T -n mythtv myvg
    # file system creation omitted
 
Instead of the traditional /dev/sdxn nomenclature, the logical volumes are
available as /dev/mapper/$vgname-$lvname or /dev/$vgname/$lvname (e.g.
/dev/mapper/vg00-usr or /dev/vg00/usr). This lack of numbering hints at the
most beneficial feature of LVM -- the ability to flexibly re-allocate disk
space.  In traditional partitions, you generally create the partition layout
you think you need and then hope your needs don't change.  Although it's
possible to re-configure a disk after it's been used, it can get messy, and is
generally very difficult to do on a live system.  With LVM, you can start out
by provisioning a small amount of disk space and then growing the file systems
as needed.  
 
One real-life example is the case of a file server.  In a previous job, we had
a many-TB file server which groups in the department purchased space on.  Five
slices were available on each drive (actually a LUN from a SAN), and if a group
outgrew the LUN it was on, we had to split their data across two LUNs.
Additionally, if two groups were on the same LUN, we'd have to shift data
around as they competed for space (which happened a lot).  Had we used LVM
instead, each group could have an LV in the correct size and they'd only
compete with themselves.
 
In my current job, we leave most of the disk space on infrastructure servers
unallocated.  As the need for a particular file system grows, we grow that file
system.  Does the new temperature monitoring system blow up the /var file
system?  Grow it.  Need to add more applications to /opt?  Grow it.  The
flexibility LVM provides allows us to quickly adapt to the needs of  the
research we support.
 
For file systems that support online resizing, growing an lv is a simple
process.  The first step is to check to see if you've got enough disk space
available by looking at the "Free PE / Size" line of the output from
[vgdisplay](http://linux.die.net/man/8/vgdisplay).  The lv is resized with the
[lvresize](http://linux.die.net/man/8/lvresize) command.  Absolute and relative
sizes can be used, and unit abbreviations like G and T are supported.  After
the lv has been resized, the file system still needs to be grown the
appropriate tools (e.g. resize2fs).
 
    # All your data[base] are belong to us. Need more space for MySQL
    lvresize -L +5G /dev/myvg/mysql
 
Once the volume group is completely allocated, lvresize can be used to shrink
an overgrown lv after the file system has been shrunk.  Additional disks or
partitions can be added to the volume group as well.  After pvcreate has been
run as above, the [vgextend](http://linux.die.net/man/8/vgextend) command can
be used to add the physical volume to the volume group.  This makes LVM
somewhat similar to JBOD in that it can take disks of various sizes and combine
them into a single usable unit.
 
    # There's nothing good on TV. Shrink the MythTV lv
    lvresize -L -10 /dev/myvg/mythtv
    # We added another disk, put it in myvg
    pvcreate /dev/sdc1
    vgextend myvg /dev/sdc1
 
Flexibility isn't the only advantage that LVM provides sysadmins.  LVM also has
optional snapshots. If there's a volatile file system that doesn't lend itself
to live backups (e.g. our database), an LVM snapshot volume can be used to
allow the backup to run.  Snapshot volumes generally only need to be a small
fraction of the original lv (10-15% is a number I've seen frequently), but the
key point is that the snapshot lv size must be large enough to hold the changes
that happen to the original snapshot.  Thus it is better to overestimate the
size of the snapshot volume.
 
    # Create a snapshot volume for our MySQL file system
    lvcreate -L 2G -s -n dbbackup /dev/myvg/mysql
    # Mount the snapshot for the backup program (tar? rsync?)
    mount /dev/myvg/mysql /mnt
 
Although LVM can be set up on software RAID (md) devices, it also has some
built-in RAID-like features.  If the volume group has at least three devices,
mirroring can be used for logical volumes (the third device is a log, with a
live copy on one device and a mirrored copy on the second device).  To use
mirroring, the logical volume needs to be created with the -m or --mirrors
option, which take the argument n-1 for n copies.
 
    # Create an important data volume with two copies
    lvcreate -L 50G -m 1 -n important myvg
 
LVM also has a striping feature which allows the logical volume to be striped
across two or more devices.  Unlike the striping in RAID 5/6, LVM striping has
no checksum and therefore provides no data protection.  However, because I/O
operations are spread across multiple devices, performance is improved.  The
number of stripes can vary between 2 and the number of devices and is specified
by -i or --stripes.  The size of the stripe (in KB) is specified with -I or
--stripesize and must be a power of 2.
 
    # Create a 100GB 3-striped lv
    lvcreate -L 100G -i 3 -I 4 -n fastlv myvg
 
LVM isn't all [sunshine and rainbows](http://www.flickr.com/search/?q=sunshine%20and%20rainbows&w=all), though.  In the past, LVM support was not
baked in to initrd files and so it had to be manually included after a kernel
update.  That's not as much of a concern anymore as most distributions include
LVM support, but users of custom kernels should make sure the initrd contains
LVM support if the root partition is on a logical volume.  Because of this
historical issue, many admins still opt for paranoia and put / (or at least
/boot) on a traditional partition.  Additionally, LVM presents an additional
level of abstraction that can make recovery via Knoppix or a similar method
more difficult. Still, LVM offers a great deal of flexibility that makes it
indispensable to the system administrator.

Further reading:

* Software RAID with mdadm ([man](http://linux.die.net/man/8/mdadm), [howto](http://ubuntuforums.org/showthread.php?t=408461))
* [LVM Snapshots](http://tldp.org/HOWTO/LVM-HOWTO/snapshots_backup.html) on tldp.org
* [LVM Howto](http://tldp.org/HOWTO/LVM-HOWTO/index.html) on tldp.org
