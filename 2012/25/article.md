# Day 25 - High-Level CM with CFEngine Sketches

This was written by [Aleksey Tsalolikhin](https://twitter.com/atsaloli).

I learned something new at LISA this year!  CFEngine is building a high-level
approach to configuration management called “design sketches”.  “Sketches” are
built on top of the comprehensive CFEngine 3 language.  

CFEngine 3 itself is quite comprehensive.  CFEngine 3.3.9 contains:

* 25 primitives, called “promise types”, which can be used to model system
  aspects, such as files, processes, services, commands, etc.; 
* 870 potential attributes of those primitives; 
* 95 functions; 
* 2200 total pages of documentation for CFEngine 3.

Because sketches overlie the DSL, you never have to touch the DSL to configure
a system.  In other words, the DSL is abstracted, and the configuration becomes
data driven. That’s what we really care about, isn’t it?

The reason it’s called a “sketch” is because you take a design pattern (such as
configuring sshd to increase security) and fill it with data (the exact
settings you want at your site or for a particular group of machines) and only
then do you have something usable. You can’t use the sketch by itself, it is
incomplete.  You complete it by configuring it.

> sketch + data = something usable

This is still 1.0 and being worked on; but I’m very excited about what I’ve
seen so far.

## Demonstration

Allow me to demonstrated how easy CFEngine makes to implement a design pattern
using sketches.  

Let’s start by installing CFEngine and the add-on tool, cf-sketch, which allows
us to handle sketches.  I invite you to follow along in a VM:

    # Run these commands to get cf-sketch installed
    lynx http://www.cfengine.com/inside/myspace # download package
    rpm -ihv cfengine-community-3.4.1.rpm # install RPM or dpkg
    wget --no-check-certificate https://github.com/cfengine/design-center/raw/master/tools/downloads/cf-sketch-latest.tar.gz
    tar zxvf cf-sketch-latest.tar.gz # download cf-sketch add-on
    cd cf-sketch
    make install

cf-sketch is prototyped in Perl.  I’m doing this on CentOS 5.8, and my perl
File::Path module wasn’t up to date, so cf-sketch wouldn’t run until I updated
File::Path.  I also installed the other Perl modules cf-sketch complained
about:

    echo "install File::Path" | perl -MCPAN -e 'shell'
    perl -MCPAN -e 'install JSON'
    perl -MCPAN -e 'install Term::ReadLine::Gnu'
    yum -y install perl-libwww-perl
    yes | perl -MCPAN -e 'install  LWP::Protocol::https'  

I could then fire up cf-sketch with no complaints: 

    # cf-sketch
    Welcome to cf-sketch version 3.4.0b1.
    CFEngine AS, 2012.

    Enter any command to cf-sketch, use 'help' for help, or 'quit' or '^D' to quit.

    cf-sketch>

The "list" command shows cf-sketch ships with the CFEngine standard library,
same version as in the main RPM:

    cf-sketch> list

    The following sketches are installed:

    1. CFEngine::stdlib (library)

    Use list -v to show the activation parameters.

    cf-sketch>

The "info all" command will show you all available sketches - there are 28
sketches available today.  Anybody can submit a sketch.  However, sketches are
closely reviewed and curated by CFEngine staff to ensure high quality.  After
all, our civilization will be running on configuration management tools and
policies!

Let’s try VCS::vcs_mirror -  its purpose is to keep a git (or Subversion) clone
up to date and clean.  

First, let’s install it:

    cf-sketch>  install VCS::vcs_mirror

    Installing VCS::vcs_mirror
    Checking and installing sketch files.
    Done installing VCS::vcs_mirror

    cf-sketch>

“List” now shows the vcs_mirror sketch is installed but not configured:

    cf-sketch> list

    The following sketches are installed:

    1. CFEngine::stdlib (library)
    2. VCS::vcs_mirror (not configured)

    Use list -v to show the activation parameters.

    cf-sketch>

Let’s configure it.  You have to specify the path that you want the clone to
be, the origin, and the branch to keep the working tree checked out on.  

So let’s say we want to clone the CFEngine Design Center.  The Design Center
contains sketches, examples and tools, and is at
https://github.com/cfengine/design-center.git

Let’s say we want to mirror the master branch to /tmp/design-center.

  cf-sketch> configure  VCS::vcs_mirror

  Entering interactive configuration for sketch VCS::vcs_mirror.
  Please enter the requested parameters (enter STOP to abort):

  Parameter 'vcs' must be a PATH.
  Please enter vcs: /usr/bin/git

  Parameter 'path' must be a PATH.
  Please enter path: /tmp/design-center

  Parameter 'origin' must be a HTTP_URL|PATH.
  Please enter origin: https://github.com/cfengine/design-center.git

  Parameter 'branch' must be a NON_EMPTY_STRING.
  Please enter branch [master]: master

  Parameter 'runas' must be a NON_EMPTY_STRING.
  Please enter runas [getenv("USER", "128"): cfengine

  Parameter 'umask' must be a OCTAL.
  Please enter umask [022]: 022

  Parameter 'activated' must be a CONTEXT.
  Please enter activated [any]: any

  Parameter 'nowipe' must be a CONTEXT.
  Please enter nowipe [!any]: !any
  Configured: VCS::vcs_mirror #1

  cf-sketch>

The sketch is now configured and ready for use.  Note the “#1”, that means this
an instance of the sketch - you can have more than one instance.

* `runas` is the user CFEngine will run the command as.
* `activated` refers to the context of the promise - where does it apply.
  “any” is a special context that is always true.  If we wanted to limit this
  policy to linux servers, we could have put “linux” there.  Or “Wednesday” if
  we wanted this policy to only run on Wednesdays. 
* `nowipe` refers to saving local differences. We set it to “not any” which means, always wipe local differences.

If you have any questions about what the parameters mean, the sketch is
documented in /var/cfengine/inputs/sketches/VCS/vcs_mirror/README.md.  All
sketches get installed under /var/cfengine/inputs/sketches/ and come with
documentation.

The documentation is not yet available from within the cf-sketch shell but this will be added next year.

Let’s check the configuration:

    cf-sketch> list -v

    The following sketches are installed:

    1. CFEngine::stdlib (library)
    2. VCS::vcs_mirror (configured)
            Instance #1: (Activated on 'any')
                    branch: master
                    nowipe: !any
                    origin: https://github.com/cfengine/design-center.git
                    path: /tmp/design-center
                    runas: cfengine
                    umask: 022
                    vcs: /usr/bin/git

    cf-sketch>

Now let’s run our sketches, to make sure they work OK:

    cf-sketch> run

    Generated standalone run file /var/cfengine/inputs/standalone-cf-sketch-runfile.cf

    Now executing the runfile with: /var/cfengine/bin/cf-agent  -f /var/cfengine/inputs/standalone-cf-sketch-runfile.cf

    cf-sketch>

Check in /tmp/design-center.  It now contains a mirror of the design-center
repo.  Pass!

Now let’s deploy our sketch so it is run automatically by CFEngine (which runs
every 5 minutes):

    cf-sketch> deploy

    Generated non-standalone run file /var/cfengine/inputs/cf-sketch-runfile.cf
    This runfile will be automatically executed from promises.cf

    cf-sketch> list

## Advanced Uses

You can deploy a sketch on your policy hub and have it affect your entire
infrastructure or a portion of it that you specify (that’s the “activated”
field in the “list -v” output - where the policy should be activated).

You can capture the configuration data of a sketch instance into a JSON file,
and move it from one infrastructure to another.

## Further Reading

* [CFEngine Design Center Wiki](https://github.com/cfengine/design-center/wiki)
* ["Modern Infrastructure Engineering with CFEngine 3"](https://www.usenix.org/lisa/books/modern-infrastructure-engineering-cfengine-3)
  USENIX Short Topics Book #26 Mark Burgess and Diego Zamboni
* ["Introducing the CFEngine Design
Center"](http://www.youtube.com/watch?v=t1HJvBEkvJk ) video by Diego Zamboni
  [60m]

## Appendix: 28 sketches available now

* CFEngine::sketch_template - Standard template for Design Center sketches
* CFEngine::stdlib - CFEngine standard library (also known as COPBL)
* Cloud::Services - Manage EC2 and VMware instances
* Database::Install - Install and enable the MySQL, Postgres or SQLite database
  engines
* Library::Hardware::Info - Discover hardware information
* Monitoring::Snmp::hp_snmp_agents - Install and optionally configure hp-snmp-agents
* Monitoring::nagios_plugin_agent - Run Nagios plugins and optionally take
  action 
* Packages::CPAN::cpanm - Install CPAN packages through App::cpanminus 
* Repository::Yum::Client - Manage yum repo client configs in /etc/yum.repos.d 
* Repository::Yum::Maintain - Create and keep Yum repository metadata up to
  date 
* Repository::apt::Maintain - Manage deb repositories in
  /etc/apt/sources.list.d/ files or /etc/apt/sources.list 
* Security::SSH - Configure and enable sshd 
* Security::file_integrity - File hashes will be generated at intervals
  specified by ifelapsed. On modification, you can update the hashes
  automatically. In either case, a local report will be generated and transferred
  to the CFEngine hub (CFEngine Enterprise only). Note that scanning the files
  requires a lot of disk and CPU cycles, so you should be careful when selecting
  the amount of files to check and the interval at which it happens (ifelapsed).  
* Security::security_limits - Configure /etc/security/limits.conf 
* Security::tcpwrappers - Manage /etc/hosts.{allow,deny} 
* System::config_resolver - Configure DNS resolver 
* System::cron - Manage crontab and /etc/cron.d contents 
* System::etc_hosts - Manage /etc/hosts 
* System::set_hostname - Configure system hostname 
* System::sysctl - Manage sysctl values 
* System::tzconfig - Manage system timezone configuration 
* Utilities::abortclasses - Abort execution if a certain file exists, aka
  'Cowboy mode' 
* Utilities::ipverify - Execute a bundle if reachable ip has known MAC address 
* Utilities::ping_report - Report on pingability of hosts 
* VCS::vcs_mirror - Check out and update a VCS repository.  
* WebApps::wordpress_install - Install and configure Wordpress 
* Webserver::Install - Install and configure a webserver, e.g. Apache 
* Yale::stdlib - Yale standard library
