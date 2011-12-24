# Package Maintainer Scripts are an Anti-pattern

_Written by [Joshua Timberman](http://twitter.com/jtimberman)_

Package management is a best practice in system administration. So is
automated configuration management. However, the maintainer scripts
run by package management tools are an anti-pattern almost in direct
conflict or competition with configuration management systems.

In my examples I'm going to talk about Debian packages and Chef,
because that is what I use. Adapt your mindset for your own favorite
distribution and configuration management tool.

## Server Lifecycle

When almost all the modern, popular Linux distributions were created,
servers had a general lifecycle, and an expected supportability
throughout that lifecycle. Some distributions have a commercial entity
that provides paid support. Others have an excellent user community
that volunteers their time to help users and administrators. Many
considerations in the development of the Linux distribution stem from the
expectation that someone will require support, and the distribution should
provide a supportable release. In addition to this, the package's maintainer
scripts is what provides additional configuration, such as creating users, or
starting services provided by the package.

## Package Management

One of the value-adds of most Linux distributions is the package
management system. Package management behavior and maintainer scripts
are well documented by the distribution to be supportable by a company
of support engineers, or a community of volunteers. For system
administrators, however, the main reason to use package management is to get
some pre-compiled software on the system, and to resolve and install any
dependencies that package may have; it is less necessary to have a service
start on package install. For example, CouchDB requires Erlang and various
other libraries, so the package manager would install those libraries, Erlang
and CouchDB. While package management has many other benefits, such as version
management, and they can do things like drop off configuration files and start
up daemons that were installed. There is definite business value in using
packages, and that's why it is a sysadmin best practice.

Many system administrators create their own packages and host them on
an internal repository. In most of the environments I've worked in,
these packages were as simple as just managing the files included in
the package usually ignoring the upstream culture of maintainer scripts and
other policies, because the system administrator planned to use a configuration
management tool to automate setup and maintenance of the software to run the
business application. In these cases, the software provided by the distribution
did not meet the needs of the business in some way. Perhaps an application
required a newer library version, or you needed to patch in a feature or bug
fix, or the default setup of a package conflicted with the way a business
application was deployed.

## Configuration Management

There are as many different application deployments as there are
businesses. The different ways the application stacks are deployed
provide a specific business value. The application stack often
includes a number of the distribution-provided packages, as well as
the code written by the business's software developers.

However, most companies have unique needs when it comes to how the
software runs in their environment. Perhaps the HTTP server default
configuration isn't properly tuned for the web application that it
serves. Maybe the business requires that the MySQL server have
replication slaves, and this configuration is not enabled by default.
Perhaps the system administrator(s) that run the servers have tuned a
particular web server for performance, but it conflicts with another
web server package. The actual conflict is based on configuration, not
on binaries that are created - both packages by default listen on the
same port when the service is started.

For these reasons and more, automated configuration management tools
such as Chef are now modern system administration best practice.

The problem we face, is that the packages that we install often run a
number of maintenance scripts to ensure that the package is set up and
configured. The distribution included the scripts to enforce some
policy such as where to put certain configuration files, start
services, or where to locate data files created by the packaged
software. In some cases, the package maintainer scripts only perform
actions when the package is removed (postrm in Debian/Ubuntu), and if
there are problems, they don't surface until the package is removed.

## Example of the Conflict

To illustrate the conflict between package maintainer scripts and
configuration management systems, let's look at a couple use cases
with MySQL. We are using Chef to automatically install the
mysql-server package on Ubuntu 10.04 LTS running on an instance in
Amazon EC2. Our two business requirements are setting a randomly
generated root password and move the MySQL data directory to ephemeral
storage, as the default location is on a smaller filesystem size.
Normally, the package installation on Ubuntu will prompt the user for
input on the password, which we then need to work around to automate
the package installation. We'll need to generate a preseed file to
give the proper settings to the package manager. We install
mysql-server on a test system:

    sudo apt-get install mysql-server

(And enter a bogus password when prompted, which is what we are trying
to avoid).

To get the preseed settings for the package, we need the
debconf-get-selections package:

    sudo apt-get install debconf-get-selections

Then we get the mysql-server settings for our preseed file:

    sudo debconf-get-selections | grep ^mysql-server > mysql-server.seed

We'll use a template that has a generated password
(`@mysql_root_password`), along with the rest of the contents in the
file:

    mysql-server-5.1 mysql-server/root_password_again select <%=
@mysql_root_password %>
    mysql-server-5.1 mysql-server/root_password select <%=
@mysql_root_password %>

And we set this up with Chef using a template and execute resource:

    template "/var/cache/local/preseeding/mysql-server.seed" do
      source "mysql-server.seed.erb"
      owner "root"
      group "root"
      mode "0600"
      notifies :run, "execute[preseed mysql-server]", :immediately
    end

    execute "preseed mysql-server" do
      command "debconf-set-selections /var/cache/local/preseeding/mysql-server.seed"
      action :nothing
    end

Then we have a package resource that installs mysql-server:

    package "mysql-server"

Next, we want to configure an alternate location for the MySQL
database on the ephemeral storage, as the database size may grow
beyond the default root partition size (10G). An example Chef recipe
to do this might look like:

    service "mysql" do
      action :stop
    end

    execute "install-mysql" do
      command "mv /var/lib/mysql /mnt/mysql"
      not_if do FileTest.directory?("/mnt/mysql") end
    end

    directory "/mnt/mysql" do
      owner "mysql"
      group "mysql"
    end

    mount "/var/lib/mysql" do
      device "/mnt/mysql"
      fstype "none"
      options "bind,rw"
      action :mount
    end

    service "mysql" do
      action :start
    end

We have to stop MySQL, move the directory, and restart MySQL. We use a
bind mount so the configuration in /etc/mysql/my.cnf does not need to
be changed. If we wanted to do that, there's additional configuration
required.

Neither of these scenarios take into account the additional complexity
required to manage the Debian system maintenance user set up in the
MySQL package, or countless settings possible to set up MySQL tuning
parameters, or database formats.

We're forced, here, to do extra work to skirt around problems created by the
package management tool trying to be responsible for things outside of
packages. The anti-pattern is exacerbated if we have to manage the package and
installation on a different OS. Then, we'd have to redo the whole dance for
another platform. If our package manager simply dropped the binaries/libraries
off and we could handle this configuration directly and much in the
configuration management, it would be much easier to manage in a
heterogeneous environment.

## Conclusion

Package management certainly has value! It allows system
administrators to install a base OS image that gives all the hardware
support and user-land well known and loved in Unix/Linux systems. When
it comes to the application stack required by the business, custom
configuration is often required. Package maintainers don't, and can't
be expected to, imagine every possible custom configuration.
Configuration management tools can, however, be used to cover any
custom configuration, since that is their job.

After all, part of the Unix (and Linux) philosophy is that each
program should do one thing well.

## Further Reading

* [Chef](http://opscode.com/chef)
* [MySQL Chef Cookbook by Opscode](http://cookbooks.opscode.com/cookbooks/mysql)
* [Amazon AWS EC2](http://aws.amazon.com/ec2/)
* [Amazon AWS EC2 Instance Sizes](http://aws.amazon.com/ec2/instance-types/)
* [Debian Policy: Maintainer
Scrips](http://www.debian.org/doc/debian-policy/ch-maintainerscripts.html)
* [Unix Philosophy](http://en.wikipedia.org/wiki/Unix_philosophy)
* [Disabling maintiner scripts on Ubuntu](https://gist.github.com/748313) - a hack that makes apt-get strip packages of maintainer scripts before they install.

## About the author

Joshua Timberman is a Technical Evangelist for Opscode. He has worked
for a wide range of companies as a system administrator: from small
company IT support to Enterprise web infrastructure delivery for
Fortune 500 companies. He helps companies and individuals learn how to
use Chef and the Opscode Platform. He wrote the majority of the Chef
cookbooks Opscode publishes, teaches the Chef Fundamentals class, and
speaks at user groups and conferences. He can be found as jtimberman
on Twitter, Skype Freenode, GitHub and more, or via email
joshua@opscode.com.
