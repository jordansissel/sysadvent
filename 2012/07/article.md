# Bacon Preservation with ZFS

## An Intermediate Guide to Saving Your Butt

This article will describe several circumstances where trivial ZFS usage can
aid you, as a systems administrator or developer, immensely.

Very briefly, ZFS is a pooled storage filesystem with many advanced features.
If you'd like an introductory view into ZFS and managing it, have a look at:

 * http://en.wikipedia.org/wiki/ZFS
 * http://illumos.org/man/1m/zfs
 * http://illumos.org/man/1m/zpool
 * http://www.solarisinternals.com/wiki/index.php/Solaris_Internals_and_Performance_FAQ

Ben Rockwood has also blogged extensively on ZFS features:

 * http://bit.ly/XeEyb1

Everything in this article is applicable to any version of ZFS, including
Oracle Solaris or an [illumos](http://www.illumos.org) distribution
(collectively known as "Solarish" systems) or the FreeBSD or [Linux
ZFS](http://zfsonlinux.org/) ports.

(There has been a fair amount of branching between Oracle ZFS and the open
version of ZFS curated by illumos, but none of those changes will be relevant
in this article.)

## Terminology

In ZFS, we refer to a single set of storage as a "pool." The pool can be one
disk, or a group of disks, or several groups of disks in any number of
configurations.

A single group of disks is referred to as a "vdev."

The pool contains "datasets." A dataset may be a native ZFS filesystem or it
may be a block device (referred to as a "zvol.")

ZFS supports mirrors and various RAID levels. The latter are referred to as
"RAIDZ1", "RAIDZ2", and RAIDZ3." The number denotes how many disks the vdev can
lose before the pool becomes corrupt.

## Comparable Stacks

If you're more familiar with Linux filesystems, ZFS condenses the facilities
offered by standard filesystems like `ext`, `XFS`, and so on, `md`, and LVM
into a single package. However, it also contains many features simply not found
in that stack. On Linux, `btrfs` has been trying to catch up, but ZFS has been
around for coming up on a decade, so they have a long way to go yet.

## Checksumming

By default, ZFS enables block-level checksumming: each block in the pool has an
associated checksum. If you have data [silently
corrupted](http://static.usenix.org/event/fast08/tech/full_papers/bairavasundaram/bairavasundaram_html/main.html)
by disk firmware, neutrons moseying by, co-workers playing with `dd`, you’ll
hear about it.

If you are working in a redundant pool configuration (and in production, you
will be) a `zpool scrub` will auto-heal any corrupted data.

 If an application tries to read a corrupted block and you’re running
redundant, it will go read a good block instead. And because ZFS loves you, it
will then quietly repair the bad block.

## Visibility

ZFS was developed at Sun Microsystems, where engineers had a deep and somewhat
disturbing love of numbers. They loved keeping metrics and stats for
everything, and then giving you, the administrator, access to them. Typically
these are exposed via the generic
[`kstats`](http://illumos.org/man/3kstat/kstat) facility:

    # kstat -l | wc -l
       42690

ZFS is no different. It exposes several hundred metrics to `kstats`.

Ben Rockwood’s [`arc_summary.pl`](http://www.cuddletech.com/arc_summary.pl) is
something I keep handy on all my Solarish systems. There is an overview of the
ARC below.

I also use [OmniTI’s resmon](https://github.com/omniti-labs/resmon) memstat
plugin to generate
[graphs](https://circonus.com/embedded/graphs/abaf826e-e17d-e87a-9a71-f9a8ffd120af/lqESWm).

You can also use command-line utilities on Solarish derivatives like `fsstat
zfs` and, more recently, `arcstat` to get live usage information.

For other versions of ZFS, look to the locally preferred method of exposing
kernel stats to userland for your ARC stats (`/proc` or `sysctl`, for
instance.)

## When New Users Say ZFS Sucks

You may notice some other behaviors with ZFS that you may not find with other
filesystems: it tends to expose poorly behaving HBAs, flapping disks, bad RAM,
and subtly busted firmware. Other filesystems will not surface these problems.
They way these issues are exposed tends to be in hung disks, or pools whose
files regularly become corrupted (even if ZFS recovers from those issues.)

Some new users complain about this ("It works fine with `foofs`!"), but it is
far better to be aware that your hardware is having problems. Run `zpool scrub`
periodically. Get your due diligence in, and sleep more soundly as a result.

Blissful ignorance stops being so blissful when you're blissfully losing
customer data.

## Bottlenecking on Disk I/O

In serverland, you’ll find you tend to have more CPU than I/O if your
application is `iops` heavy. Your applications will end up waiting on disk
operations instead of doing useful work, and your CPU will sit around watching
Vampire Diaries in its free cycles rather than crunching numbers for your
customers.

When your applications and users are suffering, it's good to have options.
Depending on your workload, ZFS gives you several easy performance wins.

### Write Log

ZFS provides a Separate Log Device (the “slog” or “write log”) to offload the
ZFS Intent Log to a device separate from your ZFS pool.

    zpool add tank log c1t7d0p1

In effect, this allows you to ship all your synchronous writes to a very fast
storage device (SSD), rather than waiting for your I/O to come back from a
slower backing store (SATA or SAS). The slog tends to not get very full (a few
dozens of megabytes, at most) before it flushes itself to the backing store,
but your customers won’t feel that. Once the data hits the slog, the
application returns, and the customer doesn’t feel the latency of your slower
but much larger SATA disks.

ZFS also batches async writes together into an atomic Transaction Group every 5
or 30 seconds, depending on your version. This not only ensures data should
always be consistant on disk (though perhaps not immediately up to date!), but
it gives you a heavy performance boost for applications not calling `fsync`.

If the txg fails to write due to a power outage or the system panicking or so
forth, you’ll get the most recently known-good transaction. Thus, no `fsck` in
ZFS.

### Filesystem Cache

ZFS also has a main memory filesystem cache called the Adaptive Replacement
Cache. The ARC both stores recently accessed data in main memory, and also
looks at disk usage pattern and prefetches data into RAM for you. The ARC will
use all available memory on the system (it's not doing anything else anyway),
but will shrink when applications start allocating memory.

You can also add extra cache devices to a ZFS pool, creating a Layer 2 ARC
(L2ARC):

    zpool add tank cache c2d0

The caveat for the L2ARC is it consumes main memory for housekeeping. So even
if you attach a very fast, battery-backed Flash device as an L2ARC, you may
still lose out if L2ARC consumes too many blocks of main memory as L2ARC
pointers. (My rule of thumb, which may be out of date, is that each 100GB of
L2ARC will utilize 1GB of ARC. So keep that in mind.)

Much like the main ARC, L2ARC is volatile cache: It's lost on reboot, and will
take some time to re-warm.

You can view both slog and L2ARC usage in the output of `zpool iostat -v`.

### Compression

However, there is an even simpler way to get more performance out of your
disks: 

    zfs compression=on tank

You can enable compression on a per-dataset level, or at the pool level. The
latter will cause all child datasets to inherit the value.

ZFS supports two compression algorithms: `lzjb`, which is a light-weight but
very fast streaming block compression algorithm, and `gzip`. I enable `lzjb` on
all my pools by default, and have since 2007.

Modern CPUs are ridiculously fast, and disks (even 6Gb/s 15k SAS) are rather
slow comparatively. If you’re doing a lot of I/O, you can get a simple but
impressive performance win here.

You also get a nice bonus: More disk utilization. On a simple RAIDZ1 SmartOS
compute node storing mostly VM block devices, I’m getting 1.48x compression
ratio using `lzjb`. So out of my 667GB SAS pool, I’m actually going to get
around a terabyte of actual capacity.

The default `gzip` level is 6 (as you’d get by running the command itself). For
my logserver datasets, I enable `gzip` and get an impressive compression ratio
of 9.59x. The stored value? 1TB. Actual uncompressed? Almost 10TB. I could
enable gzip-9 there and get more disk space at the cost of CPU time.

A couple years ago at a previous gig, we were rewriting 30,000 `sqlite` files
as quickly as possible from a relatively random queue. For each write, you read
the whole file into memory, modify it, and then write the whole thing out.

As initially deployed, this process was taking 30-60m to do a complete run.
Users were not too happy to have their data be be so far out of date, as when
they actually needed something it tended to be an item less than a few minutes
old.

Once we enabled compression, well, you can see
[here](https://circonus.com/embedded/graphs/f679b074-bccd-4eeb-8b9f-c08399904a1b/LnyJvw).

A job going from around an hour to a minute or less by running one command? Not
bad. We also minimized the I/O workload for this job, which was very helpful
for a highly multi-tenant system.

We later parallelized the process, so it now it takes only a [few
seconds](https://circonus.com/embedded/graphs/5ecf5944-c4ed-cfa6-888f-fb6b770bcc3c/ETRQZN)
to complete a run.

The caveat with compression is what when you send a compressed stream
(described below), you lose compression. You can compress inline through a
pipe, but the blocks will be written uncompressed on the other side. Something
to keep in mind when moving large datasets around!

Compression only works on new writes. If you want old data to be compressed,
you'll need to move the files around yourself.

## Snapshots

ZFS gives you an unlimited number of atomic dataset-level snapshots. You can
also do atomic recursive snapshots for a parent dataset and all its children.

    zfs snapshot tank/kwatz@snapshot

For application data, I tend to take snapshots every five minutes via a `cron`
job. Depending on the backing disk space and how often the data changes, this
means I can keep snapshots -- local to the application -- around for a few
hours, or days, or months.

For simple centralized host backups, I tend to use something like this:

    #!/bin/bash

    source /sw/rc/backups.common

    now=`/bin/date +%Y%m%d-%H%M`

    HOSTS="
    host1
    host2
    host3
    ...
    "

    DIRS="/etc /root /home /export/home /mnt/home /var/spool/cron /opt"

    for HOST in $HOSTS ; do

      echo "==> $HOST"

      /sbin/zfs create -p $BACKUP_POOL/backups/hosts/$HOST
      /sbin/zfs snapshot $BACKUP_POOL/backups/hosts/$HOST@$now

      for DIR in $DIRS; do
        rsync $RSYNC_OPTIONS --delete root@$HOST:$DIR /var/backups/hosts/$HOST/
      done

      /sw/bin/print_epoch > /var/run/backups/host-$HOST.timestamp
    done

    /sw/bin/print_epoch > /var/run/backups/hosts.timestamp

So the root of your backups is always the most recent version (note `rsync
--delete`). Not only are we only transferring the changed files, we're only
storing the changed blocks in each snapshot.

We also touch some local files when the backup completes, so we can both graph
backups latency and alert on hung or stale backup jobs.

Getting access to the snapshots is trivial as well: There is a hidden
`.zfs/snapshot/` directory at the root of every dataset. If you go looking in
there, you’ll find all your snapshots and the state of your files at that
snapshot.

    # cd /var/backups/hosts/lab-int
    # ls -l .zfs/snapshot | head
    total 644
    drwxr-xr-x   7 root     root           7 Aug 31 22:04 20120901-2200/
    drwxr-xr-x   7 root     root           7 Sep  1 22:03 20120902-2200/
    drwxr-xr-x   7 root     root           7 Sep  2 22:03 20120903-2200/
    ...

    # ls -l etc/shadow
    ----------   1 root     root        2043 Oct 12 00:22 etc/shadow
    # ls -l .zfs/snapshot/20120901-2200/etc/shadow
    ----------   1 root     root        1947 Jul 30 13:13 .zfs/snapshot/20120901-2200/etc/shadow

It makes building recovery processes rather painless. If you have customers who
often delete files they’d rather not, for instance, this is a very simple win
for both you (whose mandate as the administrator is to never lose customer
data) and the customer (whose mandate is to lose data that is most valuable to
them at the least opportune moment).

Make sure you set up your purging scripts, however, or months down the line you
might find you've used up all your disk space with snapshots. They're both
additive and addictive.

## Replicating snapshots

So local snapshots are awesome, but ZFS does you one better:

    zfs send tank/kwatz@snapshot | ssh backups1 zfs recv -vdF tank

That will send that one snapshot to another system. That particular command
will overwrite any datasets named `kwatz` on the target.

However, why only keep one snapshot, when you can ship every snapshot you’ve
taken of a dataset and all of its children, off-system or off-site entirely?

And you don’t actually want to send the entire dataset every time, for obvious
reasons, so ZFS handily provides deltas in the form of ZFS incremental sends:

    #!/bin/bash -e

    REMOTE_POOL=tank2
    LOCAL_POOL=tank
    TARGET_HOST=foo

    LAST_SYNCED=$( ssh $TARGET_HOST zfs list -t snapshot -o name -r $REMOTE_POOL/zones/icg_db/mysql | tail -1 )
    echo "r: $LAST_SYNCED"

    LAST_SNAPSHOT=$( zfs list -t snapshot -o name -r tank/zones/icg_db/mysql | tail -1 )
    echo "l: $LAST_SNAPSHOT"

    # In case the target/source pool names are different.
    RENAMED_STREAM=$( echo $LAST_SYNCED | sed -e "s/$REMOTE_POOL/$LOCAL_POOL/" )
    echo "s: $RENAMED_STREAM : $LAST_SNAPSHOT -> $REMOTE_POOL"

    zfs send -vI $RENAMED_STREAM $LAST_SNAPSHOT | ssh $TARGET_HOST zfs recv -vdF $REMOTE_POOL

I tend to ship all my snapshots to a backup host. Mail stores, databases, user
home directories, everything. It all constantly streams somewhere. The blocks
tend to already be hot in the ARC, so performance impact is generally very
light.

It’s also trivial to write a rolling replication script that constantly sends
data to another host. You might use this technique when your data changes so
often (I have one application that writes about 30GB of data every run) you
can’t actually store incremental snapshots.

Here’s a very [naive example](https://gist.github.com/4184921) that has served
me pretty well over the years.

Finally, need full offsite backups? Recursive incremental sends from your
backup host.

## Clones

By this point I hope you’re getting the idea that ZFS provides many facilities
-- all of them easy to understand, use, and expand upon -- for saving your
butt, and your customers data.

In addition to snapshots, ZFS lets you create a clone of a snapshot. In version
control terminology, a clone is a branch. You still have your original dataset,
and you’re still writing data to it. And you have a snapshot -- a set of blocks
frozen in time -- and now you can create a clone of those frozen blocks, modify
them, destroy them.

This gives you a way of taking live data and easily testing against it. You can
perform destructive or time-consuming actions, without impacting production.
You can time how long a database schema change might take, or you ship a
snapshot of your data to another system, clone it, and perform analysis without
impacting performance on your production systems.

Eric Sproul gave a talk at ZFS Days this year about just [that
topic](http://www.ustream.tv/recorded/25859777).

## Database Snapshots and Cloning

In the same vein, one of my favorite things is taking five minute snapshots of
MySQL and Postgres, shipping all those snapshots off-system, and keeping them
forever.

For most production databases, I can also keep about a days worth of snapshots
locally to the master... so if someone does a “DROP DATABASE” or something, I
can very quickly revert to the most recent snapshot on the system, and get the
database back up.

We only lose a few minutes of data, someone has to buy some new undies, and you
don’t have to spend hours (or days) reimporting from your most recent dump.

The best part about this bacon-saving process is how trivial it is. Here’s a
production MySQL master:

    # zfs list tank/zones/icg_db/mysql
    NAME                      USED  AVAIL  REFER  MOUNTPOINT
    tank/zones/icg_db/mysql  54.8G   184G  46.8G  /var/mysql

    # zfs list -t snapshot -r tank/zones/icg_db/mysql | tail -1
    tank/zones/icg_db/mysql@20121202-1005  15.6M      -  46.8G  -

    # zfs clone tank/zones/icg_db/mysql@20121202-1005 tank/database

    # zfs list tank/database
    NAME            USED  AVAIL  REFER  MOUNTPOINT
    tank/database     1K   184G  46.8G  /tank/database

    # zfs set mountpoint=/var/mysql tank/database

So we've got our data cloned and mounted. Now we need to start MySQL. Once we
do so, InnoDB will run through its crash recovery and replay from its journal.

    # ./bin/mysqld_safe --defaults-file=/etc/my.cnf 
    # tail -f /var/log/mysql/error.log
    121202 10:11:37 mysqld_safe Starting mysqld daemon with databases from /var/mysql
    ...
    121202 10:11:41  InnoDB: Database was not shut down normally!
    InnoDB: Starting crash recovery.
    ...
    121202 10:11:50 [Note] /opt/mysql/bin/mysqld: ready for connections.

MySQL is now running with the most recent snapshot of the database we have.

    # mysql
    Welcome to the MySQL monitor.  Commands end with ; or \g.
    Your MySQL connection id is 3 to server version: 5.5.27-log

    Type 'help;' or '\h' for help. Type '\c' to clear the buffer.

    mysql> 

This entire process took under a minute by hand.

Being able to very quickly spin up snapshots of any journaled datastore has
been incredibly helpful over the last few years, for accident remediation,
troubleshooting, and performance analysis.

## My Next Projects

At work, we’re building a malware lab on top of Joyent’s SmartDatacenter (which
runs SmartOS). There are many pieces involved here, but one of the biggest ones
is the ability to take a Windows VM image, install software on it, and then
clone it 20 times and run various malware through it.

With ZFS, this is as trivial as taking a snapshot of the dataset, cloning it 20
times, and booting the VMs stored on those volumes.

(There are many other facilities that aid in this process in SmartOS, namely
the way they’ve wrapped Solaris Zones with vmadm, but that’s perhaps for
another article!)

This facility would also make it trivial for us to implement something a lot
like AWS’s Elastic MapReduce:

Spin a master node, 20 slaves, and just keep track of which job(s) they’re
working on. When its done, terminate the VMs the ZFS datasets are backing, and
destroy the clones.

Wash, rinse, repeat, and all the lower-level heavy lifting is done with a
handful of ZFS commands.

## Conclusion

These processes have all saved multiple butts. More importantly, they have
helped us ensure services customers rely upon are not impacted by system
failure or accidents.

ZFS’s power lies not only in its many features, safety mechanisms or technical
correctness, but in the ways it exposes its features to you.

ZFS is a UNIX tool in the truest sense. It allows you to build powerful and
flexible solutions on top of it, without the gnashing of teeth and tedium you
might find in other solutions.

(Much thanks to @horstm22, @rjbs, @jmclulow, and @richlowe for help with this
article.)
