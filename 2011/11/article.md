## Simple Disk-Based Server Backups with rsnapshot


[Phil Hollenback](http://www.twitter.com/philiph)  
[www.hollenback.net](http://www.hollenback.net)

### Introduction

I've helped a friend administer the network at his engineering firm
for about 10 years.  For most of that time they've used a standard
[Amanda](http://www.amanda.org/) configuration with a separate backup
server and a DAT drive. That setup worked well enough, as long as
someone remembered to swap the tape every day and occasionally run the
cleaning tape.

However, this backup system suffered from a few serious limitations:

* Annoyingly difficult to retrieve individual backup files for users
* 20GB tape size required small filesystems and other 'creative' tricks

There was also a desire to simplify the configuration and eliminate
the standalone backup server.  With those goals
in mind I set out to find a suitable replacement system.

### Physical Media

The big change compared to ten years ago is the easy
availability of very large and inexpensive external hard drives.  This
site is a small company so price is a major factor, and larger tape
systems were just too expensive compared to large drives.  At the time
this system was being considered (2008) you could buy 500GB SATA
drives for around US$120.  Compare this to many thousands of dollars
for a larger capacity tape system and media.

Based on this we purchased two 500GB SATA drives and two external
SATA/USB enclosures for the backup system.  The plan was to rotate the
drives every few days and assign someone to take the spare drive home
in case the office burned down.

I should also note that this site was and is connected to the internet
with consumer DSL so the very slow upload speeds prevented use of
network backups.

### Backup Software

We knew we wanted a backup mechanism that would copy important user
data to the external drive at regular intervals.  Bare metal restore
capability was judged unimportant because the main server that was
being backed up was a stock CentOS box.  Backing up user data and
system config files was enough of a safeguard, especially since the
filesystems were already running on RAID1.

Of course the other criteria was that the software needed to be
free as in beer and free as in Richard Stallman.  Google quickly told
us we should look at [rsnapshot](http://rsnapshot.org/).

### Hot Swap

This small site did not have a lot of technical expertise, other than
my friend who served as a part-time sysadmin.  We needed to find a
solution that was as simple and bulletproof as possible, particularly
for swapping out the external drives.  This meant hot swap and a
system that could handle being unplugged any time backups weren't
actually running.  I decided to use the autofs automounter to keep the
drive unmounted when it was inactive.

We had hoped to use eSATA as the hot swap mechanism to maximize
throughput, but that proved unworkable.  The CentOS 4 server would
autodetect the drive and load the appropriate storage drivers.
However, it refused to disconnect the drive and would spew console
errors if you then manually unplugged it.  While I suspected this
might be fixed in a newer Linux distro, we didn't want to go through
the effort of upgrading the server to something like CentOS 5.
Instead we tried a USB2.0 connection since the external drive
enclosures we had purchased supported that as well as eSATA.  USB
hotplug worked just fine - as long as the filesystem wasn't mounted
you could plug and unplug all day long.  Since this was just a backup
system on a small office server, the speed of USB2.0 has proven to be
just fine.

### Configuring Filesystems and the Automounter

For simplicity and robustness I configured the external backup drives
with one large journaled ext3 filesystem.  Again, I didn't try to
optimize for performance, the goal was just to create a large backup
filesystem that wasn't terribly slow.  Note I did label the filesystem
on each disk as `backup1` and `backup2` respectively.  This is
important because it provides an easy programmatic way to determine
which drive is connected.  The format command was thus:

    mkfs -t ext3 -j -L backup1

By default CentOS detects the usb device and mounts it as
`/media/<label>`.  This is not desirable for backups as I wanted to
filesystem paths to always be consistent.  Remember I also wanted to
use the automounter, so that the disk could be physically removed any
time it was not being actively used.

Automounter setup was as follows:

* Enable autofs with `/sbin/chkconfig autofs on`

* In `/etc/auto.master` configure mounts under `/misc` with a very short
  timeout of 5 seconds:

    `/misc	/etc/auto.misc --timeout=5`

* In `/etc/auto.misc` specify that `/dev/sdd1` will be mounted under `/misc/backup`:

    `backup	-fstype=ext3	:/dev/sdd1`

After that I was able to verify the configuration by running
`/etc/autofs start`, plugging in one of the backup drives, and
verifying I could access it as `/misc/backup`.

### Time for rsnapshot

[rsnapshot](http://www.rsnapshot.org) uses rsync and hard links to make
snapshots of a filesystem.  Since it uses hard links, only files
actually changed in each snapshot take up additional room. While
rsnapshot does not come with CentOS 4, I was able to install one from
[DAG](http://dag.wieers.com/rpm/) with no difficulty.  It was then
necessary to make a few edits to `/etc/rsnapshot` as follows:

    # where to make backups
    snapshot_root   /misc/backup
    # if the usb drive isn't mounted, don't create the root dir!
    no_create_root  1
    # number of each level of snapshot to keep
    # tune so you don't fill up the backup drive too fast
    retain  hourly  3
    retain  daily   7
    retain  weekly  4
    retain  monthly 3
    # extra verbosity, for analysis scripts
    verbose 4
    loglevel 4
    logfile /var/log/rsnapshot
    # collect stats for later analysis
    rsync_long_args --delete --numeric-ids --relative --delete-excluded --stats
    # don't cross filesystem boundaries
    one_fs          1
    # filesystem trees to back up
    backup  /home/          localhost/
    backup  /etc/           localhost/
    backup  /usr/           localhost/
    backup  /var/           localhost/

That was about the extent of the customizations I needed. After this I
was able to enable hourly rsnapshot backups with an entry in
`/etc/crontabs`:

    0 */8 * * * root /usr/bin/rsnapshot hourly 2>&1 | tee \
    /tmp/rsnapreport-hourly.log | /usr/bin/rsnapreport.pl \
    >>/root/cron/rsnapshot-hourly.log && /bin/echo >> \
    /root/cron/rsnapshot-hourly.log

I realize that is kind of an ugly cronjob but I'll come back to why I set up that
complicated job.  Also note that we are only doing backups of the main
server currently, but we did do backups of an additional machine via rsync
over ssh which rsnapshot supports fully.

Finally I needed a few other crontab entries to perform the daily,
weekly, and monthly backups.  Note that all other backups past the
hourly are really just renaming the latest hourly snapshot.

    50 23 * * * root /usr/bin/rsnapshot daily > /tmp/rsnapreport-daily.log
    40 23 * * 6 root /usr/bin/rsnapshot weekly > /tmp/rsnapshot-weekly.log
    30 23 1 * * root /usr/bin/rsnapshot monthly > /tmp/rsnapshot-monthly.log

Then finally I wanted to run a daily disk usage report [script that I
wrote](http://www.hollenback.net/junk/rsnapshot-du):

    1 6 * * * root /usr/local/sbin/rsnapshot-du

That script is the reason for the ugly hourly crontab entry.  On each
hourly run I do two things:

1. Run the hourly log through the supplied `/usr/bin/rsnapreport.pl`
   script to produce a report for the individual backup run showing
   how long the run took and how much was backed up from each
   filesystem.

2. Collect all hourly reports each day so they can be combined with
   additional housekeeping information into one simple mailed report.
   This report includes information such as how much space remains on
   the attached backup drive, and the filesystem label for the drive.

This nightly email report is critical because it allows us to monitor
the amount of free space on the backup drive and verify that the
drives get switched out on a regular basis.

Here's what the 
[daily report looks like](http://www.hollenback.net/junk/rsnapshot-usage.txt).

### In Practice

This backup system has now been running on the main server for about
two years, with great success.  In particular the ability for
non-admins to recover files from the snapshots has been very popular.

Initially we started with 2 500GB external drives in the rotation.
After one year one of these drives failed, and space was getting a
little tight, so we upgraded to 2TB drives.  The modular nature of the
automounted disk backups makes this change (and switching backup
drives in general) very simple.  All you need to tell an untrained
operator is to wait until the drive light isn't flashing, unplug it,
and plug in the new drive.  When we added the new larger drives to the
rotation we just had to format the filesystems ad label them backup3
and backup4.  Then we just rotated the new drives in and rotated the
one remaining non-failed old drive out.

While this sort of hotswapping of backup drives may sound a little
risky, in a small office environment the backup drives end up sitting
idle most of the time.  We have had no problems with rotating drives
every few days, and the external cables and drive enclosures have held
up just fine.

### Conclusion

The key things I want to emphasize about this setup are that it is
cheap and reliable.  While this design would probably not scale well
in a more demanding environment, for a small office it works just
fine.  The daily management load is substantially reduced from using a
tape drive, and reliability has been excellent.  I found it
particularly satisfying that we were able to assemble this backup tool
using existing software, off the shelf external drives, and a bit of
custom scripting.  This did not take a huge amount of time, and the
hardware investment was only a few hundred dollars.  This modularity
illustrates the greatest strength of open source software.

## Further Reading

* The [rsnapshot home page](http://www.rsnapshot.org)
