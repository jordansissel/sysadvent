# DevOps is a mindset; a cultural case study

This was written by [Michael Stahnke](https://twitter.com/stahnma).

It’s happened. The DevOps term has been picked up by everybody and their
brother. From analysts, to marketing firms, to recruiters, the term is
everywhere. Beyond it being a very loud echo chamber, it sparks debate. I see
tweets and complaints all over the blogosphere about how hiring a ‘DevOps’
team, or being a ‘DevOps’ isn’t the proper adoption of this methodology. That
may be true, but arguing about it seems to only be a net-loss from the
collective brain-power reading and responding to  said internet ramblings
rather than solving difficult systems problems.

The push has been largely around culture. DevOps is culture. I’ll agree with
that, but it’s not just being rockstar-ninja-superheros operating at web-scale.

I’ll pick up my story in 2007. I had _just_ moved to a new state, new team, new
role as a system administrator (mostly doing Unix/Linux). This move was at the
exact same company I had worked at since 2002. This move wasn’t a promotion.
The Unix team, a seven person team, had had five amazing system admins quit in
span of about 60 days. On paper, me taking this job sounded like a horrible
idea, so why was it interesting to me? Unlike the rest of $Company, this
business unit did things a little bit differently. For some reason, they
purchased hardware not on the approved list. They let you run Linux on your
desktop. However, the thing that was most interesting to me was the software
stack: they ran on Open Source. The most profitable business unit in $Company
ran huge amounts of open source software! It was awesome. Rather than drowning
in Tivoli, HP, CA and BMC system tools, they had tooling set up with nagios,
irc, subversion, cfengine, trac and copious amounts of perl.

This spoke a bit about the culture of the business unit IT department.

## Stop the Bleeding

When I actually arrived on the scene in Nashville, TN, I was happy, but the
team was miserable. One junior unix administrator had been working 14-hour
days, 7 days a week, for several months. He learned by logging into systems and
typing “history” (and was among the best on the team by the time I arrived).
This team was blamed for everything. Database was down? Blame the server team.
Internet connection down? Blame the server team. Oracle upgrade failed? Blame
the server team. Obama won the election? Blame the server team. We were the
scapegoats of IT. Luckily, that meant improvement was an easy option.

One of the first problems I remember trying to fix was database outages. These
weren’t  gigantic databases doing cutting-edge things. This was Oracle 9i/10g
on clusters with 2 nodes in them. They were failing and failing all the damn
time. My boss was getting yelled at every day for servers causing outages. I
volunteered to help. I didn’t know a ton about Oracle, but I had written quite
a bit of code using it; so I knew more than some, so I figured I’d give it a
shot.

## Reduce variation

It was horrible.

I think we had about 24 database servers. They were all unique snowflakes. I
mean, all over the place: different hardware, different firmware, different OS
patch levels, different filesystem layouts, and different network
configurations. Basically, if you had paired 24 system admins with 24 DBAs you
likely wouldn’t have gotten something this crazy. What do you fix first?

We were a [Six Sigma](http://en.wikipedia.org/wiki/Six_Sigma) shop, but I
didn’t believe in any of it. My knowledge of Six Sigma was a slew of colored
belts and training courses about how to ensure anything that didn’t support
your project hypothesis (or mandate) was out-of-scope. I had wondered if 6
Sigma was magical elsewhere and just sucked where I worked. My boss actually
taught me everything I’ve ever needed from Six Sigma in a 10 minute conversation.
It boiled down to this:

> Reduce the standard deviation value. Raise the mean.

It’s so simple, but it really does encompass everything that 6 Sigma was
supposed to tell you. If you have a factory line or a datacenter, this logic is
universal. Reducing the type of and variation of defects will fix issues. Then
you can start to concentrate on raising quality. This met some resistance.
Suddenly, our team’s goal, repeat, our goal, was to make systems fail, but in
known ways. If they were going to fail, I wanted it to be 2 dozen of them
failing for the same reasons. The same but wrong is better than all different
and unknown.

I started planning changes and outages to move filesystems, reconfigure
networks, migrate hardware etc. The DB team was very scared of us making
changes to their systems because changes required downtime. This came down to
an argument of “Do you want your systems to have planned or unplanned downtime?
Because you’re going to get one or the other.”  I had support from management;
that helped.  Getting database servers to the point where they were operating
with extremely similar configurations reduced outages by about half. Then we
started learning how to actually tune and install Oracle properly.

## Break Down Silos

Can culture change begin by fixing some database servers? We worked with our
customers. In this case, it was mostly DBAs, but our business analysts and
accountants kept tabs on progress, as well.

We were still fighting turf wars over who could manage disks/filesystems and
who could manage backups etc. To eliminate these battles, I gave the entire DBA
team sudo access without restrictions. The security guy in me hated it. The guy
who wanted to solve problems thinks it was a great decision. (We did log
heavily). Part of the responsibility of getting sudo, however, meant that pages
went to the DBA team for many more types than they used to. If I was going to
be up at 3AM trouble-shooting something, so were they. We shared the pain. I
tried to push the DB specific pain to them. People who carry the pager will
make better design decisions when not on-call.

## Admit Failure, Build Trust

Post-mortem meetings were a major exercise in blame-storming. I decided that
instead of redirecting blame or telling customer groups to design for failure,
I would just own the failure. I walked in and said, “hey, we totally screwed
up,” continuing with a prepared statement in how we misconfigured some
enterprise storage and totally blew up many lines of business when it went
wrong.

The response was amazing. People were left with “oh...um ok then.” No blame and
no problems. Honesty panned out! That success drove me to run every post-mortem
like that: If was our fault, we shouted it.

Transparency builds trust.

## Experimentation Matters

The freedom to experiment was another awesome thing about that job. I tried
running our team via scrum. It more-or-less worked. Priorities were clearer. I
tried to teach everything I could think of from software development to my
unix/linux admins, and then the Windows team too. Some of it went really well,
but some of it flew by at 30,000 feet.

Experimentation happened people-side, technology-side, and process-side. I
wrote and deployed dumb tools. During that database server project, I wrote
something that ssh’d to each database machine, ran dozens of scripts to gather
inventory-type data, and stored it in subversion. It was a complete failure. It
was dumb. Oh well, we moved on. I wrote another application (in PHP aahhhh)
that should have been a complete failure, but was loved by the helpdesk.

## Solve causes, not symptoms

One of the last major feats I remember trying to teach culturally was to think
about solving problems not pain. Pain is 45 tickets to add new users. You
simply add the users and they go away. The problem is that somebody had to make
45 account-related tickets. How can you fix the account process to remove that?
Is it automation? Is it a new process?  Each month I would look at what our
most common ticket was, and try to reduce that type of ticket to virtually
zero. This worked well with account management, printer stuff, disk space
tickets, backup related items, etc. Some projects were certainly a long-play
and other could clearly be solved in a 30 day window.

This transformation of a team made me really start wondering, what is a
successful agile infrastructure adoption? I still wasn’t doing 35 deployments
of a website a day. We were not a site reliability engineering team. We
probably weren’t going to get invited to Velocity to talk about it, but when I
thought about success it came down a few questions:

 * Are we satisfied with how this works, or are we trying to make it better?
 * Have we influenced other teams enough that they ask us for design help,
   automation help, monitoring recommendations, etc?
 * Since I worked at an org where IT workers switch jobs every few years, are
   there people wanting to come to the Unix server team now? 

One day, I was asked by a member of my team if we were doing scrum. I responded
saying that we were just trying to be good at our jobs. On that team, the
culture had changed, the automation grew dramatically, we had metrics to prove
it and we shared what we could. We learned a whole lot along the way too.

Around this same time, a friend of mine from Puppet Labs was heading to Belgium
to speak at something called “DevOps Days.” Once I read more about that
conference, I realized we were doing those things. It now had a label. DevOps
was about using technology to solve problems. Using automation, showing results
with numbers, and having heavy collaboration. We changed the culture of a
team. We made our business better. We changed into a DevOps culture.

## Further Reading

* [Ben Rockwood's talk on DevOps Transformation](http://www.youtube.com/watch?v=3KpPBnEtRj4)
* [DevOps Days Conference](http://devopsdays.org/)
