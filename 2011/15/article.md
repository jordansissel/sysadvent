Automating WordPress installation using CFEngine 3


  Internet use is growing and new services are appearing hourly. The number of servers (both physical and virtual) is becoming uncountable. Automation of system administration is a must to handle the deluge; else many swarms of sysadmins would be needed to handle all these systems.

  In companies with multiple sysadmins working the old way, in interactive root sessions, there is a potential for sysadmins who are making changes at the same time to step on each other’s toes (and on the config!);

    System administration is a relatively new profession, without a standard curriculum, so practitioners have different philosophies and practices. Going from organization to organization, it is a challenge for a new sysadmin to learn:

        - how is the system setup,

        - why was it setup that way,

        - how it needs to be setup to keep operating,

        h- ow to set it up that way again in case of disaster or normal growth.

Automating system administration addresses all the above and makes new things possible.

For example, a CM tool can respond faster than a human sysadmin to a deviation from configuration policy to remedy it or it may automatically instantiate, configure and bring online a new virtual server instance if an old one dies.

CFEngine 3 is modern configuration management tool that uses a descriptive language to document the intended end state of the system -- its desired configuration -- as well as why it is being configured this way.

This article not an introduction to CFEngine 3. For an introduction to CFEngine 3, see the CFEngine section in "State of the Art of Automating System Administration with Open Source Configuration Management Tools" ( http://www.verticalsysadmin.com/config2010/ ) and "Getting Started with CFEngine 3" ( http://www.verticalsysadmin.com/cfengine/Getting_Started_with_CFEngine_3.pdf )

This article demonstrates automating a WordPress installation with CFEngine 3.

Why WordPress?  Installing WordPress involves coordinating multiple
system components into a harmonious whole.  It is a great demonstration
of the power of automated configuration management.  It involves copying and editing files, installing packages, and starting and restarting services.  

To install WordPress manually normally takes tens of minutes.  An automated install under CFEngine cuts that time by an order of magnitude.


  The two main parts of infrastructure involved in making WordPress work are:

1. Web server

2. Database server

In this example, we'll assume Apache httpd is our Web server, and mysqld is
our database server.  We'll also assume we're running on a Red Hat or Red Hat-like
system.


Installing WordPress

Installing WordPress involves the following:


   1. Install and Configure the Infrastructure

           1.1. Install httpd and httpd modules: mod_php (since WordPress
                is written in PHP) and PHP MySQL client library (so we
                can talk to the database server).

           1.2. Install MySQL server.

                   1.2.1. Create WordPress User in MySQL.

                   1.2.2. Create WordPress Database in MySQL.

           1.3. Make sure httpd and MySQL servers are running.

       1.4. Make sure firewall (iptables here) allows TCP 80
	    connections (to httpd).

   2. Install and Configure the PHP application, WordPress.

       2.1. Download tarball with the latest version of WordPress.

       2.2. Extract it to the httpd document root

       2.3. Create WordPress config file wp-config.php by copying
	    wp-config-sample.php 

       2.4. Edit wp-config.php to put in the db name and credentials.

After the above is done, the owner can login to the WordPress blog and 
configure it: set the blog's name, admin credentials, configure preferences, 
and so on.  Our deliverable is a new blog ready for the owner to configure it.


CFengine 3 wordpress_installer policy

The most up to date version of this policy can be found on github:

https://github.com/cfengine/contrib/raw/master/wordpress_installer.cf

Here is our policy, it starts with a control promise and requires
the Cfengine Open Promise Body Library (which ships with Cfengine): 


The policy is runnable either via
"cf-agent -f /var/cfengine/inputs/wordpress_installer.cf" or via
"chmod 700 /var/cfengine/inputs/wordpress_installer.cf; 
/var/cfengine/inputs/wordpress_installer.cf".

Figure 1 shows the control promise, which controls the behavior of
cf-agent, including which files it should import (the standard Cfengine
library) and in what sequences to examine and keep bundles (collections)
of promises.


Figure 1: Control Promise


Let's make sure we have all the necessary packages. We will use the "yum" 
package_method since we are using a Red Hat derivative.

The packages_installed bundle depicted in Figure 2 promises to restart the 
httpd if any packages are added to cover the case where httpd is up and running but 
"php" and "php-mysql" are missing, so Cfengine installs them.

Figure 2: packages_installed bundle

Now let's make sure httpd and mysqld are running with the services_up bundle
shown in Figure 3. 


Figure 3: services_up bundle

--------------------
About: "restart_class"

About "restart_class": if a scan of the "ps" output does not contain the 
named string, then the right hand side class will be set.  Then we can use
that to launch a command to start the server.
--------------------


Figure 4 shows the wordpress_tarball_is_present bundle where we  make sure we have a copy of 
WordPress in an arbitrary location - let's say in /root.  We'll need it later to install
WordPress under the httpd document root.

We test using Cfengine built-in test function "fileexists()". 
If the file exists the "wordpress_tarball_is_present" class gets defined.
(A class is Cfengine implicit if/then test.  If it is defined, the 
test passes.  If it is not defined it does not.  In other words,
defined = true, not defined = false.)

If the file does not exist, the "wordpress_tarball_is_present" class will not be defined 
and the commands promise will download it.

If the file does exist (because we already went through the above scenario), no action
will be taken.



Figure 4: wordpress_tarball_is_present bundle

Similarly, in Figure 5 we test if the WordPress directory exists
under the document root (assumed to be "/var/www/html").

If it doesn't, we'll extract our WordPress tar ball to the docroot using "tar".

Note that the "tar" extract promise depends on the earlier promise that the tar
ball is on disk.  Because Cfengine does three passes through the promises when
it runs, on the first pass the tar ball will be downloaded if necessary, on the
second pass Cfengine will extract it.  This is an example of convergence to 
desired state, part of the basic philosophy of Cfengine.


Because Cfengine is convergent in its operation, the above
cf-agent command can be run multiple times, and the system
will always stay at or approach the desired state, never 
get further away from it.  This is convergence to desired state.
It can fight entropy and system state drift.

Figure 5: wordpress_tarball_is_unrolled bundle


Next, Figure 6 shows how we use the "mysql" command to create the database
for the application data store as well as credentials to access it:

Figure 6: configuration_of_mysel_db_for_wordpress bundle

Please note the above command (like all these promise bundles)
is convergent to desired state - it will either get us to the desired state
if we are not there, or keep us there if we are there already. 

The desired state is a "wordpress" database that can be accessed via a "wordpress" 
user with the password "lopsa10linux".

Next, in Figure 7, let's copy the sample config file WordPress ships with to 
"wp-config.php" if it doesn't exist.

First, we check if wp-config.php exists using the built-in "fileexists()" function.
If wp-config.php exists, this will set a "wordpress_config_file_exists" class.

This class will be used to control what happens next: if the class is set, no changes 
will be made to the system; we'll just report wp-config.php is there.
If the class is not defined, we'll report wp-config.php is not there, and then put it there
by copying it from wp-config-sample.php


Figure 7: wpconfig_exists bundle

In Figure 8, we make sure "wp-config.php" contains our database name and credentials.

Default wp-config-sample.php settings


    // ** MySQL settings - You can get this info from your web host ** //
    /** The name of the database for WordPress */
    define('DB_NAME', 'database_name_here');

    /** MySQL database username */
    define('DB_USER', 'username_here');

    /** MySQL database password */
    define('DB_PASSWORD', 'password_here');



In Figure 8, we use "replace_patterns" in cfengine_stdlib.cf to replace
database_name_here with our database name, and so on.  Just like using
a template, we replace placeholders with actual values.


Figure 8: wp_config_is_properly_configured


As a finishing touch, let's make sure our host firewall allows
inbound connections on port 80 TCP (Figure 9).

Figure 9 is our most complicated promise bundle.  There are three
levels of abstraction: a "files" type promise that edits a file
using "edit_line" type promise bundle uses "insert_lines" (from
cfengine_stdlib.cf) which has an attribute "location" which
is defined (in a separate promise attribute body) as before
the iptables rule for accepting established TCP connections.

Incidentally, this promise bundle will also restart iptables
if it edits the iptables config file.

Abstracting the details allows the sys admin to see at a high
level what's going on without being blinded by too many details
at once; yet the details are accessible to examination if needed.

Figure 9: allow_http_inbound


To summarize, here is what the policy can do:

  - Install Web server and required httpd modules (php, php-mysql);
  - Install Web app in httpd docroot
  - Install and configure the database for the Web app
  - Configure the Web app to use the database
  - Configure the host firewall

There is a more sophisticated version of this automated WordPress 
installer in Aleksey's "CFEngine 3 Examples Collection" ( http://www.verticalsysadmin.com/cfengine/cfengine_examples.tar ), see
2030_More_Examples._EC2._Example102_wordpress_installation.cf



Further Information

http://www.cfengine.com/
http://www.verticalsysadmin.com/cfengine/



About Aleksey Tsalolikhin

Aleksey has been a UNIX/Linux system administrator for 13 years. Wrangling EarthLink's server farms by hand during growth from 1,000 to 5,000,000 users, he developed an abiding interest in improving the lot of system administrators through configuration management, documentation, and personal efficiency training.   

Aleksey will teach "Time Management for System Administrators" at the So Cal Linux Expo on 20 Jan 2011 (http://www.socallinuxexpo.org/scale10x/events/scale-university); and "Automating System Administration using CFEngine 3", a 3 day hands-on course, in the Bay Area on 25-27 January 2012 and in Los Angeles on 20-22 February 2012.


