# Configuration Management as Legos

This was written by Adrien Thebo.

Configuration management is hard. Configuring systems properly is a lot of hard
work, and trying to manage services and automate system configuration is a
serious undertaking.

[cablefail]: https://lh6.googleusercontent.com/-mrCp_-fZfEY/UMmCyadDWkI/AAAAAAAAAJM/YMi-0GgUL8U/s512/cable-mess.jpg

Even when you've managed to get your infrastructure organized in Puppet
manifests or Chef cookbooks, organizing your code can get ugly, fast. All too
often a new tool has to be managed under a short deadline, so any sort of code
written to manage it solves the immediate problem and no more. Quick fixes and
temporary code can build up, and before you know it, your configuration
management becomes a [tangled mess][cablefail]. Nobody intends for their
configuration management tool to get out of hand, but without guidelines for
development, all it takes is a few instances of `git commit -a -m 'Good
enough'` for the rot to set in.

Organizing configuration management code is clearly a good idea, but how do you
do it? For normal development, there are many of design patterns for laying out
and organizing programs and libraries. Traditional software development has had
around 40 years to mature, and config management is fairly young by comparison
and hasn't had the time to have formal best practices.

[unix]: http://en.wikipedia.org/wiki/Unix_philosophy

This is a proposal for an organizational pattern that I'm calling the "lego
pattern." Admittedly, there's nothing revolutionary about these ideas. To be
honest, all the ideas espoused in this article are simply applications of the [unix
philosophy][unix]. This pattern can be used to organize code for any
configuration management tool, but for the sake of brevity, I'll be using
Puppet to provide examples.

## The Base Blocks

Fundamental behavior is provided by a set of base modules. These are akin to
the rectangular lego blocks - they're generic, they're reusable, and you can
swap them out for similar pieces. Modules like this should be focused on three
tenets of the Unix philosophy: the [__Rule of Modularity__, the __Rule of
Composition__, and the __Rule of Separation__](http://www.faqs.org/docs/artu/ch01s06.html).

When writing base modules, they should be, well, modular. They should do
one thing and do it well. For instance, a module for installing a web
application should not manage a database service, neither should it configure
logging. while these are valid concerns, they're not directly related.
Managing only one service in one module makes that module more reusable and
more maintainable.

Base block modules should also be built to be composed with other modules. If a
module only handles one service, then it can also safely interact with similar
modules. For instance, that web app module only handles installing and running
the web app, another module can handle backing up files, and they can be used
together to solve the whole of a business problem. If people want to use your
module and also back up related files, they won't be forced to use your backup
tool - they can use your module to provide the service and use their module to
handle backups.

Lastly, base block modules should be built to hide the underlying
implementation, and provide a fairly complete interface to the service that
they're managing. Modules like this only need to be manipulated via parameters
that they expose (much like software libararies), so you can see what options
you can tune and configure without having to have complete mastery of the
service that its managing. The advantage of this is that you have a clean
separation between how the core elements of the service work, and how you're
implementing them.

[apache]: http://forge.puppetlabs.com/puppetlabs/apache

The [puppetlabs/apache][apache] module is a good example of this. The apache
module is designed to give you the set of tools you'll need to manage almost
any apache configuration regardless of the underlying system. It hides the
system-specific configuration and presents you with a simpler interface to
configure vhosts, apache modules, and further to ensure that the necessary
packages are installed and the service is running. When using this module you
could have a vhost defined like this:

    apache::vhost { 'www.example.com':
      vhost_name      => '192.126.100.1',
      port            => '80',
      docroot         => '/home/www.example.com/docroot/',
      logroot         => '/srv/www.example.com/logroot/',
      serveradmin     => 'webmaster@example.com',
      serveraliases   => ['example.com',],
    }

The `apache::vhost` provides all the options that you could tune, and you set them
as needed. You don't need to have to touch the underlying templates used, or
know the syntax of apache configuration, or really anything about how the
module works, aside from the options presented by the vhost.

Fundamentally, the apache module does one thing, and does one thing well. It
doesn't handle things like monitoring, backups, and it doesn't try to run back
end services. You can use this module to run apache, and combine it with other
modules to build the rest of your configuration.

## The Weird Blocks and Code Layout

<img src="https://lh6.googleusercontent.com/-VNAY3iwgrHI/UMl_xLS8DpI/AAAAAAAAAI4/NyRfhaPJN7M/s150/lego-axle-hub.jpg" style="float: right; border: 0">

Of course, every site has their own internal services and applications, and this
is where the weird blocks come in. Weird blocks are analogous to the lego
blocks that have axles or hinges sticking out: they're designed to do
something very specific and can't really be reused anywhere else. In turn,
nothing else can provide the behavior that they provide.

Generally, these generally should be written like base blocks but with a
couple of twists. One twist is that since these modules cannot be reused
elsewhere, it can make sense to embed site specific data in templates and
manifests.  Secondly, these modules are located in a different place on the
filesystem.  Using the Puppet `modulepath` setting or chef `cookbook_path`
setting, you can specify a list of locations to check for modules. You can take
advantage of this to locate reusable base blocks in one place, and weird blocks
in another place.

    ├── base-blocks
    │   └── apache
    │       ├── manifests
    │       │   ├── init.pp
    │       │   ├── ssl.pp
    │       │   └── vhost.pp
    │       └── templates
    │
    ├── weird-blocks
    │   └── boardie
    │       ├── manifests
    │       │   └── init.pp
    │       └── templates
    │           └── config.yml.erb

Differentiating between base blocks and weird blocks is surprisingly powerful.
The distinction makes publishing your base-blocks easier, and allows you to
easily tell what sort of work a module is expected to do. 

This separation can also be used to control access - perhaps one team manages
an internal service, so they can handle the configuration management for
that service.  However this team won’t be administering the rest of your
infrastructure.  Giving them access to the weird-blocks directory means they’ll
be able to do their job, but they’ll be bound to respecting the interfaces of
the base-blocks instead of taking shortcuts and putting site specific changes
in your base blocks.

## Composing Blocks into Services (like lego kits)

<img src="https://lh5.googleusercontent.com/-3MLuMsRdjFQ/UMl_xK4_xzI/AAAAAAAAAI8/Smhy5n864n0/s200/back-to-the-future-lego-kit.jpg" style="float: right; border: 0">

So we have all of these well defined modules and classes, but without
assembling them you have a pile of legos - something that's not useful and
mainly exists to cause searing pain when you step on one. Therefore, we need
some sort of concept, like a site configuration, where you take these individual
parts and snap them into configurations that work for you.

Building on top of the multiple module-path idea outline, assembled modules go
in a site-services directory, like so:

    ├── site-services
    │   └── infrastructure
    │       └── manifests
    │           ├── dhcp.pp
    │           ├── mrepo.pp
    │           ├── webserver.pp
    │           └── postgresql.pp

Within this site-services directory, you build out modules that provide a
complete solution. For instance, the `infrastructure::postgresql` module would do
things like use the postgresql module to install and run the postgres service,
use the nagios module for monitoring postgresql, use the backupexec module to
back it up, and so forth. In addition, this is where you inject the
site-specific configuration into the modules, so this is where you make the
underlying modules work for your infrastructure.

Things in site-services generally won't directly include resources and will
only include other classes. Put another way, they exist almost entirely to
aggregate classes into usable units and configure their settings. The following
example would be an example of everything you would need to bring up the
[mrepo](http://dag.wieers.com/home-made/mrepo/) infrastructure on a node:

    class infrastructure::mrepo {

      motd::register {'mrepo': }

      class { 'staging':
        path  => '/opt/staging',
        owner => 'root',
        group => 'root',
        mode  => '0755',
      }

      $mirror_root = '/srv/mrepo'

      class { 'mrepo::params':
        src_root     => $mirror_root,
        www_root     => "${mirror_root}/www",
        user         => "root",
        group        => "root",
      }

      class { 'mrepo::exports':
        clients => '192.168.100.0/23',
      }

      # Bring in a list of the actual repositories to instantiate
      include infrastructure::mrepo::centos
    }

Using this model anyone can use the mrepo module, and our own implementation can
be used with `include infrastructure::mrepo`. We have a clear separation of the
mrepo implementation and how we're using it.

## Roles: They’re Like Lego Cities

<a href="http://seboslegoschool.edublogs.org/files/2011/08/legoCity-2cyt7cu.jpg"><img src="https://lh3.googleusercontent.com/-xJUV0OLw5Ho/UMmBB4xCNnI/AAAAAAAAAJI/Xi_r47VcX60/s200/legoCity-2cyt7cu.jpg" style="float: right; border: 0"></a>

At this point, we have the modules built in site-services that configure our
environment the way we need it. The final step is taking these services and
grouping them into configurations that we'll apply to machines. For instance,
bringing up a new webserver could involve including modules from site-services
to set up our configurations SSH, Apache, and Postgres. Bringing up a new host
for building packages would mean bringing in our site-specific configurations
for Tomcat, Jenkins, and compilers and such. This would give us a hierarchy
like this:

    ├── site-roles
    │   ├── buildhosts
    │   │   └── manifests
    │   │       ├── init.pp
    │   │       ├── jenkins.pp
    │   │       └── compilers.pp
    │   │
    │   └── webservices
    │       ├── manifests
    │       │   ├── redmine.pp
    │       │   └── wordpress.pp

Each manifest in here would be a further abstraction on top of the
site-services module. They would look something like this:

    class webservices::redmine {

      include infrastructure::apache::passenger
      include infrastructure::mysql

      class { 'custom_redmine':
        vhost_name    => $fqdn,
        serveraliases => "redmine.${domain} redmine-${hostname}.${domain}",
        www_root      => '/srv/passenger/redmine',
      }

      pam::allowgroup { 'redmine-devs': }
      pam::allowgroup { 'redmine-admins': }

      sudo::allowgroup { 'redmine-admins': }
    }

This final layer takes all our implementations of apache and mysql and applies
them, controls system access, and provides for a complete redmine stack.
Including this one class, `webservicse::redmine`, is all it takes to provide
for every requirement of a redmine instance, so deploying more machines for a
specific role means including a single self contained class. 

This gives us the following hierarchy

  * base-blocks and weird-blocks provide basic functionality
  * site-services assemble blocks into functional services
  * site-roles assemble services into fully functional and independent roles

If you use this pattern, in no time, you could have configuration
management code that is about as awesome as a seven foot replica of Serenity.

<a href="http://www.flickr.com/photos/brickfrenzy/sets/72157630914408000/with/7717701618/"><img src="http://farm9.staticflickr.com/8434/7717708760_365a1c0df8.jpg" style="border: 0"></a>
(image credit [brickfrenzy](http://www.flickr.com/photos/brickfrenzy/))

## Further Reading:

* [Stop Writing Puppet Modules That Suck](http://bombasticmonkey.com/2011/12/27/stop-writing-puppet-modules-that-suck/)
* [Simple Puppet Module Structure](http://www.devco.net/archives/2012/12/13/simple-puppet-module-structure-redux.php)
* [Guide to Writing Chef Cookbooks](http://www.opscode.com/blog/2011/09/07/guide-to-writing-chef-cookbooks/)
* [Host vs Service](http://sysadvent.blogspot.com/2008/12/day-7-host-vs-service.html) - sysadvent 2008 discusses the value of using roles in configuration.
