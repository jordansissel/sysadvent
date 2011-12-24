Introducing Configuration Management to Legacy Environments
(With a focus on Puppet and MCollective as I use those)

This was written by Dean Wilson (www.unixdaemon.net)

Configuration management is perfect for green field projects, you can
choose the best technical solutions, there are no existing
inconsistencies and you have a window to build, deploy and test all
the manifests and recipes without risking user visible outages or
interruptions. Unfortunately most of us don't have the luxury of starting
from scratch in a pristine environment. We have to deal with the
oddities, the battle scars and the need to maintain a good quality of
service while evolving the platform.

In this article we'll discuss some of the key points to consider as you
begin your journey.

Discovery
-------------

It's worth making a special note about the discovery phase of most
configuration management projects. You'll be asking yourself questions like
"how many differences are there across the sshd_config files? Where do
we use that backup users key? What's the log retention setting of the
apache servers? Is it identical between those we upgraded from apache 1
and the fresh apache 2 builds?"

When I first started to bring puppet in to my systems I wrote custom
scripts, ssh loops and inventory updating cronjobs to give me
the information I needed now there is an excellent solution
to gather information you need, in real time: MCollective.

With the appropriate agents you can compare, peer and probe in to
nearly every aspect of your infrastructure. The FileMD5er agent for example
will show you groups of hosts that identical config files. Using
this you can partition the environment and work section by section
to control the settings. One of my favourite current "tricks" is to
query config file settings with the
[AugeasQuery](https://github.com/deanwilson/unixdaemon-mcollective-plugins/tree/master/augeasquery)
agent. No more regex based matching for me!

    # Does your ssh permit root logins?
    
    $ mco rpc augeasquery query query='/files/etc/ssh/sshd_config/PermitRootLogin' --with-agent augeasquery -v
    ...

    test.example.com : OK
        {:matched=>["no"]}

    test2.example.com: OK
        {:matched=>["no"]}


Short Cycles
-------------

One of the key factors to consider when starting large scale
infrastructure refactoring projects is that you'll need information and
you'll need it quickly.

You should always be the first to know about things you've broken. Your
monitoring system, centralised logging, trend graphing and config
management systems reporting server will become your watchful allies.

The speed at which you can gather information, write the manifest,
deploy and run your tests is more important than you'd think. Keeping
this cycle short will encourage you to work in smaller sections, reducing
the time between you actually testing your work and keeping the possible
problem scope small. Tools like MCollective, mc-nrpe and nrpe runner will
enable you to rapidly verify your changes.

Version Control
-------------

The short version is: version control everything.

There's no reason, whether you are in a team or working alone
(especially when working alone!), not to keep your work in a
version control system. "That change didn't work, I've rolled it back".
Really? By hand? Are you sure? You didn't forget to remove one of the
additions? Why would you shoulder the mental burden of knowing all the
things you changed recently when there are so many excellent tools that
will do it for you, and allow seamless rollbacks to old revisions.

Beyond the benefits of providing an ever present safety net, using a VCS
provides an easy way to hook your exact change in to
incident, audit or change control systems, a perfect place to do smaller
code reviews and a basic but permanent collection of institutional
knowledge. Being able to search through the puppet logs / reports when
debugging an issue to find exactly which resources changed and when,
pull up the related changeset and the actual reason for it (and who
you should ask for help) changes your process and reports from
best guesses based on peoples memories to quick fixes backed by
supporting evidence.

On a positive note it's amazing how much you can learn from reading
through a branch of commits from such projects as DBAs performing
performance tuning. Seeing which settings were changed, the reasons why
and in some failed cases explanations for them being reverted can save
you, new staff and even the same staff in six months time from redoing
parts of the work again.

Use Packages
-------------

A lot of older environments have fallen in to the habit of pushing tarred
applications around (and sometimes compiling software on the hosts
as needed). This isn't the best way to deploy in general and it will
make your manifests ugly, complicated, sprawling messes. In most cases
it's not that hard to produce native packages and tools like
[fpm](https://github.com/jordansissel/fpm) make the process even easier.

By actually packaging software and running local repositories you can 
use native tools, such as yum and apt, in a more powerful way. Processes
become shorter and have simpler moving parts, more meta information
becomes available and importantly it's possible to trace the origin of
files. You can then use other tools, such as puppet and MCollective to ease
upgrades, additions and reporting.

As an aside there is disagreement as to whether packages should
handle related tasks, such as deploying users, however once you've
reached the point where this is your biggest worry you've surpassed
most of your peers and will have an environment that gives you the
freedom to do whichever you choose.

Baked in Goodness
-------------

As you bring more of your system under puppet control you'll begin to
experience the continuously improving system baseline. Every improvement
you make is felt throughout the infrastructure and regressions become
infrequent, easy to spot and quick to remedy. You should never wonder if
you've deployed nginx checks to a new server, it should be impossible to
have a mysql server without your graphing applied and every wiki you
deploy should be added to the backup system without you intervening.
Once you've started to write modules for your server roles you can begin
to add supporting services and start to gain some free functionality.

By having infrastructure manifests such as a monitoring module and
writing some generic "add monitoring check" defines you can sprinkle
reuse throughout other, more functionality focused modules. In my test
manifests, for example, nearly every class has nagios checks associated
with it and every service declares the ports it listens to. This might
not sound like much but it's impossible for me to deploy a server
without monitoring, every time I add a new nagios check all the hosts
with that role receive it and generating security policies, firewall
rule sets and audit documents is done automatically for me and requires
no manual updating. Being able to supply people with links to live
documentation is a wonderful way to remove awkward manual steps from
reports, audits and inventories.

Involve Everyone
-------------

While you don't have to agree with the DevOps movement and ideas to use
configuration management some of its principles (such as communication,
openness, shared ownership and responsibility) are worthwhile and have a
low overhead once you start to config manage everything. Look for simple
requests for information from other teams. Do they want to know which
cronjobs run and when? What modules the apache servers have configured
or which rubygems you've deployed on the database servers? (from
packages!)

By allowing them to see modules that don't have special security
requirements you develop a shared understanding of the platform. You
enable them to regain time they'd waste raising support tickets and they
can see the changes happening, via commit mails or reporting tools like
Foreman, without feeling like they are hassling you.

At $WORK a large percentage of our developers are comfortable reading
manifests, running MCollective commands and using custom foreman pages
and cgi-scripts to investigate issues and answer their own queries
without the sysadmins being involved. This has dropped our workload,
given them quicker answers and allowed them to ask targeted questions
after doing their own research.

It's not all about developers either, with a custom puppet define and a
little reporting wrapper we can expose the list of ports required by
every machine to our network teams and auditors along with accurate
timestamps showing when information was gathered. Using MCollective and
custom database facts our DBAs have dashboards showing deployed packages
and services, current running configuration and the ability to gather
ad-hoc real time information from any of our systems, whether production,
development or QA and even compare the differences between them.

Pick your fights
-------------

While you're growing accustomed and skilled with your new tools
you need to be aware of its strengths and the best places to
apply them. As the person pushing change you have to prove your way
is at least as good as current practises and hopefully an improvement.
Because of this some tasks are bad places to prove your point and you
need to be weary of them.

Large monolithic deployment or configuration scripts can be handled if
you break them down to manageable components but often tight
coupling and intertwined code makes them bad places to start. Explaining
that it took three hours to unpick a shell script that seems to work
fine is never a good opening move. Vaguely defined processes are
the other common tar pit, bringing attention to processes that people
seem to do slightly differently is a great way to unite people against
what you are trying to accomplish.

User accounts for example are a complex areas to automate. While it
starts with a simple "deploy the admin accounts, add them to wheel and
push the SSH keys" it eventually becomes a sprawl of teams needing
different sets of access on a semi-rotating basis.

It's worth noting that you'll often be considered slower, especially
when starting out. Writing ten line throwaway shell scripts or hand
hacking something will be quicker in the short term than writing clean
manifests that include monitoring, meta data and tests but the
comparison is unfair. You're building flexible, reproducible, systems
that support future change, not focusing on a single server.

Roles, not hosts - No more snowflakes
---------------------------------------

As you build your collection of configuration management techniques
you'll find special snowflake hosts. Machines performing several
small but important tasks, nodes hand constructed under time constraints
(and needing that one extra config option) and boxes you'll "only ever
have one of". Don't fall in the trap of assuming any machine is special
or you'll only ever have one of them. Building a second machine for
disaster recovery, a staging version or even an instance for upgrade
tests means there will be times when you'll want more than one of them.
If you find yourself adding host conditional 'if's or listing hostnames
in your manifests then it's time to stop, take a step back and consider
alternatives. Any list, especially of resource names, that you hand
maintain is a burden and will eventually be wrong.

A sign that things are starting to click is when you stop thinking in
terms of hosts and start thinking in roles. Once you begin assigning
roles to hosts you will find the natural level of granularity you should
be writing your modules at. It's common to revisit previously written
modules and extract aspects of them as you discover more potential reuse
points.

Conclusion
-------------

With a little care and consideration it's possible to integrate
configuration management and even the largest legacy infrastructures
while enjoying the same benefits as the newer, less encumbered projects.

Take small steps, master your tools and good luck.

Further Reading
-------------

* [Planet Puppet](http://www.planetpuppet.org/)
  * especially posts by Masterzen and R.I.Pienaar
* [PlanetDevops](http://www.planetdevops.net/)
