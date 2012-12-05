# Following the White Rabbit

This was written by [Kent C. Brodie](https://twitter.com/KentBrodie)

How many of you have tried working with a vendor, and after much back and
forth, gotten an answer along the lines of "works for us, so it must be
something with your setup, sorry!"    This is such a story.  And like most
similar situations, I learned some valuable lessons worth sharing.    

## The Background (our environment)

I work in the Human & Molecular Genetics Center, a large center within a
private medical school.    We currently deal with whole genome analysis, and
let me tell you, it's pretty fun.   There's lots of data, lots of PhD-type
people doing complicated analysis, lots of servers, and lots of tools.    Did I
mention there's lots of data?    

In the middle of all of this is a Sun Grid Engine (SGE) cluster that's required
to run a key software package from Illumina, Inc, that does nifty genetic
things like "demultiplexing", "alignment", "variant calling", and several other
sexy scientist-things that I really don't need to know TOO much about.   (If I
did, I'd have to go get my PhD too....).  The cluster is not huge, but it's
large enough to get the processing done in a reasonable amount of time, between
8 and 14 hours depending on the data.   The nodes participating in the cluster
are all interconnected with a set of dedicated and isolated 10gb switches just
for this task.    Fast servers.  Dedicated 10gb network.    Industry-standard
cluster software.   What could go wrong?

## The Problem

The main problem with my clustered environment and the Illumina software was,
it wasn't working.    Specifically, while the demultiplexing and variant
calling steps always worked fine, the alignment step did not.    SOMETIMES the
alignment step would work, but much of the time it would fail.   The tricky
part of this was that it would run for 10,12, maybe 14 hours and then- boom.
In the resulting error log file, I found several instances of this kind of
error:

    AlignJob.e22203:error: __commlib error: got read error (closing "baku/shepherd_ijs/1") 

and elsewhere in the log I also saw errors like this:

    [2012-10-13 00:47:38]   [kiev.local]  ERROR: The ELAND extended file for the mate 2 reads 001_eland_extended.txt.oa) __could not be found.__
    [2012-10-13 00:47:38]   [kiev.local]  qmake: *** [205P_GCCAAT_L001_001_pair.xml] __Error 1__

It's important to point out that the software pipeline worked just fine in all
cases on a single node.   It's just in the SGE environment that it failed.
The Illumina pipeline is essentially really nothing more than a handful of
binaries, and dozens of complicated makefiles.   Many of you are familiar with
"make" and its use.   SGE introduces a new flavor of that called "qmake", which
is like "make", but is completely distributed when the code is designed to take
advantage of it.   In my case, "make" on a single node worked fine, "qmake" in
the cluster did not.

##Getting some help

The first place I turned to was of course, Illumina, our sequencing equipment
and software vendor.    Because of the complicated nature of the setup, they
really could not provide any clear answers.   The gist of the answers from them
were along the lines of "it's a cluster issue".   "Contact your grid engine
company", "It's a race condition, you probably have issues with your switches",
and so on.     They support their software tools completely, but can really
only guarantee help in single-server installations.  Due to the multiple
variables in a typical cluster setup, Illumina cannot support customer-built
clusters. (Illumina sells a specific cluster setup, we do not have that).
And in our case, single-node executions were fine.  So, nothing wrong with
their software. QED.   I was basically on my own.     But, I at least had some
useful suggestions from them to go on:

* Possible issues with the Sun grid Engine installation
* Possible issues with the 10gb switches, causing timing issues

## And So It Begins

Being a bit new to the SGE environment, I figured I had probably missed
something.   There ARE several installation options to choose from, and so I
went off to test each and every option that I could think of.

When debugging a problem, most of us sysadmins dive in, execute a task, analyze
the result, and repeat until the problem is solved.    This is how I worked on
this, no surprise there.   But here's the tricky part:   I had to wait at LEAST
12 hours or more between each failure to figure out if what I had changed had
any affect.    Let me tell you, that's not fun.    The emotional roller-coaster
of THINKING I had solved the problem, only to find out the NEXT DAY that I had
not, was incredibly difficult and took its toll.

## Tick... tock...  tick... tock

While I won't get into the full details of each step, I can summarize here a
number of the more important things I worked on.  Each of these is essentially
a variable – the combinations got pretty crazy.   I tried one change at a time,
and in some cases, multiple changes – all depending on gut feeling.  And all
out of frustration because no matter WHAT I did, I got the same errors.   Here
is the abbreviated list:

* Various versions of Grid Engine (official Oracle SGE, open source "Son of
  Grid Engine", and multiple versions of each)
* Various 10-gig switch settings (enable/disable STP/portfast, flow control, etc)
* Physical connections to the switches (all nodes on one switch vs multiple switches, etc)
* Grid engine options dealing with spooling (local?  Centralized?  classic(flat) vs BerkeleyDB?)
* Number of actual processes per node when running the job

## Finally, a Breakthrough

By this time in my troubleshooting marathon, over a month has now passed.   I
am losing sleep.   The boss is cranky.   He wants to replace the cluster with
several standalone 48-core machines to run the Illumina pipeline, which means
he's lost faith I can ever solve this.   (A horrible solution by the way,
because even on a 48-core server, a single alignment job takes 40 hours.)   It
WORKS, but it takes 40 hours.     [Note, in a WORKING cluster environment,
alignments finish in between 8-12 hours]

In my daily Google searches about grid engines and configurations and such, I
eventually come across the default configuration for ROCKS clusters with SGE –
and notice something I've not yet tried.   (ROCKS is a software distribution to
rapidly build physical and virtual clusters, pre-loaded with all sorts  of
goodies)  By default, the grid engine environment uses and internal RSH
mechanism to make all of the connections to the other hosts and/or back to the
grid master.    But in the ROCKS distribution, SSH is used.    Why?   Because
for extremely large clusters, OR for jobs that require a boatload of
communication streams to occur, RSH will run out of connections due to that RSH
only runs on ports < 1024.    Lather, rinse, repeat, wait 12 hours.   

_Bingo_.   Well, sort of.     The "commlib" errors are now gone.   Seems the
commlib error was trying to tell me, "can't establish connection because
there's no more ports left".     I am now left with the missing file(s) error.
I am closer.     The situation seems simple--  there are files that a job on a
node out there is expecting to be there, and it isn't.    OK, so the vendor's
claim of some "race condition" seems possible.    The testing continues.   

## Nothing.  Nada.  Zip.

Another 3 weeks pass.   I have made zero progress on the final error- the
famous missing file.   I have even gone so far as to acquire a demo Force10
switch from my partner/reseller to try out to see if that solves the problem
(Our cluster installation has a Dell 8024 10-gig switch, a choice made by a
former manager.   It was not on our storage vendor's approved-hardware list..).
The new switch makes no difference.  I am extremely thankful to my reseller and
Dell for allowing me to test the switch.    

## A pair of breakthroughs?

Finally, in week 8, two things come together, both pointing to issues with
Illumina software and "qmake":

## Use the Source, Luke

First, I find some interesting comments in two of the complicated makefiles in
Illumina's code.   Due to licensing restrictions on the code, I cannot post the
comments or code here, but the guts of it boil down to that (this is
paraphrased), "due to the limitations of qmake",... "we have to do it this
way".

This is interesting.   Even one of the authors of the code is sort of
acknowledging that he or she has had issues with qmake – the core utility I'm
using in SGE.

## A funny thing happened on the way to the Forum

Second, at about the same time, I got an answer from an online forum for people
doing sequencing analysis ("seqanswers").   As a hail Mary pass, I post
specific questions about my issue, and from more than one person I hear back,
"use distmake".

Distmake is an interesting animal.    It's a distributed make.    It's kind of
like qmake, but it BEHAVES like "make" on a single server.    It's a little
hard to explain, but the difference showed up in my logfiles.    When I ran the
alignment job using "qmake", the log was peppered with log entries from every
node in the cluster.   Node A did this step, node C did that step, and so on.
With "distmake", every single log entry is from ONE node.    The job
distribution works behind the scenes, but it also works within the SGE
framework.   This is critical, since we depend on SGE for the scheduling of all
of the jobs.

And..  it worked!

(Personal note, as soon as this happened, I took 2 days of vacation to
celebrate and basically do NOTHING except clean my garage and catch up on my
favorite tv shows).

What was wrong?    Why this failed in our environment, but works ok "at
Illumina", I can't say.    The type and size of the data?   The number of nodes
in the cluster?   The sequencing/alignment options?   Endless possibilities.
My own conclusion is this:  That under many circumstances, the Illumina code
and qmake, the heart of SGE, simply do not behave well together.     I have had
difficulty convincing them of that, and have to settle for the fact that I have
a working solution.  A solution several other sites are using, by the way.

## Lessons learned

I learned several lessons while going through this process.    Some are
technical tidbits specific to SGE, and some are well, words of advice.    Some
of these seem obvious now, but during those two months, it wasn't.

## Sun Grid Engine lessons

* In my opinion, "Son of Grid Engine" is where it's at.   Much more development
  activity and bug fixes and features and so on.   Oracle DOES still support
  their SGE product, but updates are slow, and I wouldn't bet long term banking
  on SGE support from them.   It was, after all, a SUN product.
  https://arc.liv.ac.uk/trac/SGE
* SGE spooling:   go with local spooling.    And classic mode is just fine
  except for perhaps the largest (hundreds of nodes) clusters, that's the only
  time you probably really need BerkeleyDB.
* SGE ports:  Despite what the documentation says, do not depend on scripts and such to define the ports used for qmaster or execd communication.  Always, always, use /etc/services entries.   
* SGE communication:   Use SSH.    ROCKS has it right.
# SGE error messages blow chunks.   Just sayin'.

## Other Lessons

* Do your own troubleshooting:  Probably the most important thing I got out of
  this experience was that I let myself be led, accidentally, by a software
  vendor. And while I did have a communication-based issue with my SGE setup
  (rsh vs ssh), the real issue I was having (missing file) was not caused by
  any issue with the Grid engine environment at all.   There was nothing wrong
  with my network, there was nothing wrong with my switches, and so on.     I
  let their suggestions get in my head and take me on an unnecessarily-long
  troubleshooting path.    Without predetermined suggestions for what might be
  wrong, I may have uncovered the flawed code earlier.
* Problems with one process are not necessarily related.   I initially thought
  the COMMLIB and MISSING FILE errors were related.   They were not.
* There is a support forum for EVERYTHING:   I can't explain why I didn't
  stumble upon SEQANSWERS earlier.   I just missed it.    I'm a sysadmin for a
  relative small community (institutions that do their own genetic sequencing),
  and I'm guessing the handful of us that are in this are WAY too busy to be
  real active on the Internet :-)  .   I guess I was looking for the wrong
  community (SGE users), when the proper community was there all along
  (sequencing analysis users).    http://seqanswers.com/
* DISTMAKE is basic, but really cool. 

I hope you enjoyed my little tale!     Now go finish your Christmas shopping.
There's only 19 shopping days left.

## Further Reading

(Author note, if you do nothing else, at least watch the NOVA episode.  It's awesome.  Really)

* [PBS Nova episode "Cracking your genetic
  code"](http://video.pbs.org/video/2215641935/) - features, in-part, my boss,
  Dr.  Howard Jacob.
* Main PBS ["Cracking your Genetic
  Code"](http://www.pbs.org/wgbh/nova/body/cracking-your-genetic-code.html)
  site, with many educational links (including one that shows you how to extract your own DNA!).
* [Illumina, Inc](http://www.illumina.com/):  Manufacturer of the world's most widely used sequencers
* [SEQanswers](http://seqanswers.com/): A super-useful site for just about anything to do with genetic sequencing>
* [ROCKS Clusters](http://www.rocksclusters.org)
* [distmake](http://distmake.sourceforge.net/pmwiki/pmwiki.php)
