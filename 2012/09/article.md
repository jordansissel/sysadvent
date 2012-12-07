                                                                     
                                                                     
                                                                     
                                             
In a blinding moment of schadenfreude, a promising social bookmarking
startup Gnolia disappeared after a common misunderstanding, mistaking
a fault tolerant mirror for a disaster recovery backup. [All user
data was lost and the startup soon dissolved][gn].

Another painfully public backup failure example comes from [Jeff
Atwood][jf], having relied on his hosting company to provide disaster
recovery backups without testing or verification. He was soon to find
out that they were not maintained correctly.
	
Let’s talk about your backups, I know you’re busy, startups are fast
moving operations, and backups are boring but this is important. We
won’t go into any great technical depth. This will be a high level
overview of backups, their purpose, and how to make effective choices
when designing a backup system that will scale with your need.

Essentially a backup is an offline point-in-time snapshot, nothing
more and nothing less. A backup is not created for fault tolerance, it
is created for disaster recovery. Disaster recovery begins after your
fault tolerance threshold has been exceeded. For example: a RAID 5 is
fault tolerant enough to lose one disk from the array, if two disks
fail, or the array has been corrupted, you are in a disaster recovery
mode. Your only tool for recovery is a good backup, and a stiff drink
(preferably after you've finished the restore).

A RAID or active mirror is [often mistaken][mis] as an effective means
of creating a backup solution. A RAID is not a backup, it is only a
fault tolerant array of discs. Likewise a mirror is not a backup, all
write operations including data corruption or destruction are mirrored
as well. Backups must be offline (that is, not writable), and should
be stored in a different media than the original data.

Let’s begin by making a list of all your critical data. In a typical
startup this is your code repository, the user data, and all of the
associated infrastructure configuration files (which should already be
checked into your code repository … right?). It may or may not include
the actual operating system.

This list will become a catalog of sorts, every time a new source of
data has been added to your application or infrastructure put it into
this catalog. At a minimum you’ll want a common name, path, and
description for each entry.

Once you’ve identified your data sources, begin to make estimations of
their potential growth over time. The growth of your data sources will
determine what media and technique that best fits your needs. Today
there are many options, hard drives, magnetic tape, and even solid
enough cloud solutions (such as Amazon’s S3).

To determine the best fit estimate and calculate several factors; time
to complete a backup, time to transfer your backup to your backup
media, and the cost of your backups per GB (cost per tape, cost for S3
storage, etc.). Next project your cost over your estimated growth,
this will function as your cost baseline. This baseline will be
continually revised throughout the rest of the process. Keep it handy.

For example, you determine that you currently have a database that is
at 10GB, and growing 10% a month. Amazon Web Services S3 pricing is
currently $0.095 per GB per month (not including other fees). The
first month will be $0.95 for 10GB, the second month will be $1.04 for
11GB, the third month $1.14 for 12.1GB, and so on.

Remember each type of backup media has hidden costs that you may not
have considered: tapes need to be replaced, S3 charges for services
other than just the storage, and removable commodity hard drives have
less than ideal failure rates. Find out as much as you can about your
media before committing to a long term solution.

Network transit times need to also be considered. If you collocate your
servers it may be more cost effective to keep large backup sets local
to the server rack on tape. While Amazon Web Services infrastructure
benefits from using Amazon’s S3. Ultimately it will depend on your
infrastructure, budget, and the amount of data which backup solution
best fits your needs.

Next you’ll want to determine your rotation and retention
scheme. There are many kinds of backups, some are vendor specific,
while others are universal. We’ll review the three most common:
Incremental, Differential, and Full.

Incremental, all data that has changed since the last incremental or
full backup. Benefits from smaller backup sizes, but you must have
every incremental backup created since the last full. Think of this
like a chain, if one link is broken, you will probably not have a
working backup.

Differential, all data that has changed since the last full
backup. Benefits from being smaller than a full, while removing the
dependency chain needed for pure incremental backups. You will still
need the last full backup to completely restore your data.

Full, all of your data. Benefits from being a single source restore
for your data. These are often quite large.  

A traditional scheme uses daily incremental backups with weekly full
backups. Holding the fulls for two weeks. In this way your longest
restore chain is six media (one weekly full, six daily incremental),
while your shortest restore chain is only 1 media (one weekly full).

Another similar method uses daily differentials with weekly
fulls. Your longest chain is just 2 media (one differential, and one
full). While your shortest is still just a single full backup.

Whatever your vendor of choice offers make sure to pay attention to the
longest possible restore chain and the time it takes to restore from
this chain. The length of the chain, time to completion, and time to
restore should be the major determining factors when you decide on a
scheme.

At some point between determining the length of time needed to
effectively restore and buying into a backup solution. Talk to your
business managers, bring your cost baseline, discuss the downtime,
costs associated, and estimated time needed to restore into a working
environment. Be ready to make the case that an effective backup
solution will save the company revenue, bolster customer confidence,
and generally make everyone life easier.

You will need to make these points not from a technical point of view,
but from a business point of view. This may be very difficult, but
there are certain ways to estimate the value of data. Estimates can
begin with real world hours that each developer and engineer have
already put into your systems, and the hours needed to recover from a
disaster. Customer confidence is notoriously hard to determine, but
you can certainly put a value on the current business income to
customer ratio.

If you can’t be specific, don’t make up specific numbers, in this case
tell your business managers what you know and let their intuition
about the business fill in the blanks.

Testing your backups is as important as creating them in the first
place. The only thing worse than not having a backup is believing you
have a backup when you really don’t. Three things you should monitor:
media space available, average time to completion, and successfully
restoring a canary.

Media space needs to be monitored as intently as a production server
file system. Running out of space will mean that backups are not able
to successfully complete. If space is limited, choosing a backup
scheme will become vitally important, if space is not limited or your
backups are small, your scheme will not need to be optimized so
quickly.

The time it takes to create a backup and write it to the backup media
is also very important. You’ll want to make sure that your backup runs
in sufficient time to complete the entire backup and send it to the
media you’ve chosen before the backup needs to run again.

Testing the validity of a backup is essential. It can be helpful to
restore a canary into a test/development environment on a regular
basis. Rebuilding your site and its data from a backup is something
that most of us wish we never have to do, but by making backup
restores part of your development framework every developer and
engineer will build a good set of disaster recovery skills and become a
fast expert in disaster recovery.

By giving you a broad overview I hope we’ve built a solid foundation
for understanding backups. While backups seem to be simple, there is a
lot of planning and consideration that goes into creating an effective
solution. Everyone will have slightly different needs, but we all have
a similar starting point.

Recommended Reading:

 * [Backup and Recovery][ab], By W. Curtis Preston
 * [Backups and Recovery][ps], W. Curtis Preston and Hal Skelly

**tldr;** Project your data growth, understand the characteristics of
your media, watch your metrics, remove fear and doubt from the restore
process.

[ab]: http://shop.oreilly.com/product/9780596102463.do
[mis]: http://www.google.com/search?q=raid+is+not+a+backup&oq=raid+is+not+a+backup
[ja]: http://www.codinghorror.com/blog/2009/12/international-backup-awareness-day.html
[gn]: http://blog.backblaze.com/2009/03/02/magnolia-wilts-with-no-backup/
[ps]: https://www.usenix.org/lisa/books/backups-and-recovery
