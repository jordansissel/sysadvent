# Day 15 - Automating WordPress with CFEngine

This was written by Aleksey Tsalolikhin.

System administration is a relatively new profession. Without a standard
curriculum, practitioners have different philosophies and practices.
It is challenging for new sysadmins because every organization
implements differently: the how and why of system setup, how and why of
maintenance, and the how and why of disaster recovery and growth.

A software tool can respond faster than a human sysadmin
to a deviation from configuration policy (something being broken). The
corrective action can be automated, so chaos is kept to a minimum while not
requiring human action.

Why WordPress?  Installing WordPress involves coordinating multiple
system components into a harmonious whole.  It is a great demonstration
of the power of automated configuration management.  It involves copying and
editing files, installing packages, and starting and restarting services.  

Manually installing WordPress often takes tens of minutes.  An automated
install under CFEngine greatly shortens the time required and most
importantly provides a repeatable and auditable experience.

Lastly, an introduction to CFEngine is out of scope for this post, but you can
learn more [here](http://www.verticalsysadmin.com/config2010/),
[here](http://www.verticalsysadmin.com/cfengine/Getting_Started_with_CFEngine_3.pdf),
and
[here](http://sysadvent.blogspot.com/2009/12/day-24-config-management-with-cfengine.html).


## Automating WordPress Installation

The two main parts of infrastructure involved in making WordPress work are a
web server and a database. In this example, we'll use Apache httpd and MySQL as
well as assume a Red Hat (or derivative) system.

The most up to date version of the cfengine implementation of this post can be
found here:
<https://github.com/cfengine/contrib/raw/master/wordpress_installer.cf>

You can run this policy with: 

    cf-agent -f /var/cfengine/inputs/wordpress_installer.cf

The rest of this post covers the manual steps you might do to install WordPress and also
the equivalent implementation in CFengine.

## Ordering Things

Below shows the control promise which controls the behavior of cf-agent
including which files it should import (the standard Cfengine library) and in
what sequences to examine and keep bundles (collections) of promises.

    body common control 
    {

            bundlesequence => {
                                    "packages_installed",
                                    "services_up",
                                    "wordpress_tarball_is_present",
                                    "wordpress_tarball_is_unrolled",
                                    "configuration_of_mysql_db_for_wordpress",
                                    "wpconfig_exists",
                                    "wpconfig_is_properly_configured",
                                    "allow_http_inbound",
                              };

            inputs =>        { "/var/cfengine/inputs/cfengine_stdlib.cf" };
    }

## Get the Right Packages

With that order given above, let's start by ensuring we have all the necessary
packages. We will use the "yum" `package_method` since we are using a Red Hat
derivative.

The `packages_installed` bundle depicted in below promises to restart the
httpd if any packages are added to cover the case where httpd is up and running,
but "php" and "php-mysql" are missing, and Cfengine installs them.

    bundle agent packages_installed
    {

    vars: "desired_package" slist => {
              "httpd",
              "php",
              "php-mysql",
              "mysql-server",
             };

    packages: "$(desired_package)"
        package_policy => "add",
        package_method => yum,
        classes => if_repaired("packages_added");

    commands:
      packages_added::
      "/sbin/service httpd graceful"
        comment => "Restarting httpd so it can pick up new modules.";
    }

## Apache and MySQL

Now let's make sure httpd and mysqld are running with the `services_up` bundle
shown below:

    bundle agent services_up {
    processes:
      "^mysqld" restart_class => "start_mysqld";
      "^httpd"  restart_class => "start_httpd";

    commands:
      start_mysqld::
        "/sbin/service mysqld start";
      start_httpd::
        "/sbin/service httpd start";
    }

The "restart_class" is used to scan the "ps" output for the named string, and
if not found, the right hand side class will be set. We can then use that to
launch a command to start the server.

## Downloading WordPress

The next section shows the `wordpress_tarball_is_present` bundle where we  make
sure we have a copy of WordPress in an arbitrary location - let's say in `/root`.
We'll need it later to install WordPress under the httpd document root.

We test using Cfengine built-in test function "fileexists()". 
If the file exists the "wordpress_tarball_is_present" class gets defined.
(A class is Cfengine implicit if/then test.  If it is defined, the 
test passes.  If it is not defined it does not.  In other words,
defined = true, not defined = false.)

If the file does not exist, the "wordpress_tarball_is_present" class will not
be defined and the commands promise will download it. If the file does exist,
no action will be taken.

    bundle agent wordpress_tarball_is_present
    {
    classes:
      "wordpress_tarball_is_present" expression =>
        fileexists("/root/wordpress-latest.tar.gz");

    reports:
      wordpress_tarball_is_present::
        "WordPress tarball is on disk.";

    commands:
      !wordpress_tarball_is_present::
        "/usr/bin/wget -q -O /root/wordpress-latest.tar.gz
    http://wordpress.org/latest.tar.gz"
        comment => "Downloading WordPress.";
    }

## Unpacking WordPress

Next, we test if the WordPress directory exists under the document root
(assumed to be "/var/www/html").

If it doesn't, we'll extract our WordPress tarball to the docroot using "tar".

Note that the "tar" extract promise depends on the earlier promise that the tar
ball is on disk.  Because Cfengine does three passes through the promises when
it runs: on the first pass, the tar ball will be downloaded if necessary; on the
second pass, Cfengine will extract it. This is an example of convergence to 
desired state, part of the basic philosophy of Cfengine.

Because Cfengine is convergent in its operation, the above cf-agent command can
be run multiple times, and the system will always stay at or approach the
desired state, never get further away from it. It can fight entropy and system
state drift.

    bundle agent wordpress_tarball_is_unrolled
    {
    classes:
      "wordpress_directory_is_present" expression =>
        fileexists("/var/www/html/wordpress/");
    reports:
      wordpress_directory_is_present::
        "WordPress directory is present.";
    commands:
      !wordpress_directory_is_present::
        "/bin/tar -C /var/www/html -xvzf /root/wordpress-latest.tar.gz"
          comment => "Unrolling wordpress tarball to /var/www/html/.";
    }

## Configuring MySQL

Next, we use the "mysql" command to create the database
for the application data store as well as credentials to access it:

    bundle agent configuration_of_mysql_db_for_wordpress
    {
    commands:
      "/usr/bin/mysql -u root -e \"
        CREATE DATABASE IF NOT EXISTS wordpress;
        GRANT ALL PRIVILEGES ON wordpress.*
        TO 'wordpress'@localhost
        IDENTIFIED BY 'lopsa10linux';
        FLUSH PRIVILEGES;\"
      ";
    }


Please note the above command (like all these promise bundles)
is convergent to desired state - it will either get us to the desired state
if we are not there, or keep us there if we are there already. 

The desired state is a "wordpress" database that can be accessed via a "wordpress" 
user with the password "lopsa10linux".

## Adding the WordPress Config

Let's copy the sample config file WordPress ships with to `wp-config.php` if it
doesn't exist.

First, we check if `wp-config.php` exists using the built-in "fileexists()" function.
If `wp-config.php` exists, this will set a "wordpress_config_file_exists" class.

This class will be used to control what happens next: if the class is set, no changes 
will be made to the system; we'll just report wp-config.php is there.
If the class is not defined, we'll report wp-config.php is not there, and then put it there
by copying it from wp-config-sample.php

    bundle agent wpconfig_exists
    {
    classes:
      "wordpress_config_file_exists"
      expression => fileexists("/var/www/html/wordpress/wp-config.php");
    reports:
      wordpress_config_file_exists::
        "WordPress config file /var/www/html/wordpress/wp-config.php is present";
    commands:
      !wordpress_config_file_exists::
      "/bin/cp -p /var/www/html/wordpress/wp-config-sample.php \
        /var/www/html/wordpress/wp-config.php"
        comment => "Creating wp-config.php from wp-config-sample.php";
    }

Here is the `wp-config-sample.php` sample config:

    // ** MySQL settings - You can get this info from your web host ** //
    /** The name of the database for WordPress */
    define('DB_NAME', 'database_name_here');

    /** MySQL database username */
    define('DB_USER', 'username_here');

    /** MySQL database password */
    define('DB_PASSWORD', 'password_here');

Taking the sample config above, we can use the "replace_patterns" in
`cfengine_stdlib.cf` to replace `database_name_here` with our database name, and
so on.  Just like using a template, we replace placeholders with actual values.

    bundle agent wpconfig_is_properly_configured
    {
    files:
      "/var/www/html/wordpress/wp-config.php"
        edit_line => replace_default_wordpress_config_with_ours;
    }

    bundle edit_line replace_default_wordpress_config_with_ours
    {
    replace_patterns:
      "database_name_here" replace_with => value("wordpress");

    replace_patterns:
      "username_here" replace_with => value("wordpress");

    replace_patterns:
      "password_here" replace_with => value("lopsa10linux");
    }

## Configure IPTables

As a finishing touch, let's make sure our host firewall allows
inbound connections on port 80 TCP (Figure 9).

The is our most complicated promise bundle.  There are three
levels of abstraction: a "files" type promise that edits a file
using "edit_line" type promise bundle uses "insert_lines" (from
cfengine_stdlib.cf) which has an attribute "location" which
is defined (in a separate promise attribute body) as before
the iptables rule for accepting established TCP connections.

Incidentally, this promise bundle will also restart iptables if it edits the
iptables config file.

Abstracting the details allows the sysadmin to see at a high level what's going
on without being blinded by too many details at once, yet the details are
accessible to examination if needed.

    bundle agent allow_http_inbound
    {
    files:
      redhat::  # tested on RHEL only, file location may vary on other OSs
      "/etc/sysconfig/iptables"
        edit_line => insert_HTTP_allow_rule_before_the_accept_established_tcp_conns_rule,
        comment => "insert HTTP allow rule into /etc/sysconfig/iptables",
        classes => if_repaired("iptables_edited");
    commands:
      iptables_edited::
      "/sbin/service iptables restart"
        comment => "Restarting iptables to load new config";
    }

    bundle edit_line insert_HTTP_allow_rule_before_the_accept_established_tcp_conns_rule
    {
    vars:
      "http_rule" string => "-A INPUT -p tcp -m tcp --dport 80 -j ACCEPT";
    insert_lines: "$(http_rule)",
      location => before_the_accept_established_tcp_conns_rule;
    }

    body location before_the_accept_established_tcp_conns_rule
    {
    before_after => "before";
    first_last => "first";
    select_line_matching => "^-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT.*";
    }

To summarize, here is what the policy can do:

  - Install Web server and required httpd modules (php, php-mysql);
  - Install Web app in httpd docroot
  - Install and configure the database for the Web app
  - Configure the Web app to use the database
  - Configure the host firewall

There is a more sophisticated version of this automated WordPress installer in
Aleksey's "CFEngine 3 Examples Collection" (
http://www.verticalsysadmin.com/cfengine/cfengine_examples.tar ), see
2030_More_Examples._EC2._Example102_wordpress_installation.cf

## Further Reading

Aleksey has been a UNIX/Linux system administrator for 13 years, and will share
his knowledge during the "Time Management for System Administrators" session at
the So Cal Linux Expo on 20 Jan 2011
(http://www.socallinuxexpo.org/scale10x/events/scale-university) and
"Automating System Administration using CFEngine 3", a 3 day hands-on course,
in the Bay Area on 25-27 January 2012 and in Los Angeles on 20-22 February
2012.

* <http://www.cfengine.com/>
* <http://www.verticalsysadmin.com/cfengine/>
* [Automating Wordpress with Puppet](http://www.stevencharlesrobinson.com/sites/scrobinson.nsf/docs/Automated%20WordPress)
