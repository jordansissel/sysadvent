# Keep Track of Requests with Request Tracker

One of the first things that Tom Limoncelli talks about in the "Practice of System and Network Administration" is getting a request tracking system in place. While you are not always tracking requests per-say, I have never seen an environment that didn't have tasks, work orders, requests, tickets or some other variant on that theme. Because my roles have always been rather customer facing, whether internal or external, the idea of a ticket system always appealed to me. So here are my reasons you should dive head first into a system, why I chose Request Tracker by Best Practical and a quick HOWTO on getting RT up and running on Ubuntu/Debian.

# Why a Ticket System?
A ticket system is important because email, conversations, sticky notes, etc get lost and forgotten. That is it, plain and simple. But that just scratches the surface of the real power of a ticket system. For starters, tickets make great collaboration spaces for dealing with issues. Everyone involved gets updated when new info is available and it provides a great blow by blow when you are dealing with the postmortem. The other thing that comes from all of this effort is metrics. Metrics about which users or customers make the most requests, what kinds of requests happen regularly and how long it takes to get certain tasks accomplished. It becomes an easy way to justify the need for more staff, or more staff in specific areas, when there is a sustained volume of tickets.

# Why RT?
Request Tracker by Best Practical, or RT, is fairly simple to get up and running and is extremely easy to bend to meet the needs of most environments. I personally chose RT because of the general ease of setup (Debian has packages), it is email based, has a REST API and there is a mobile interface and iPhone app. Sure there are a bunch of other way cool things you can do with it, but those where my personal reasons. Being email based is a huge advantage because of the limited amount of retraining that will need to be done to get people started. Instead of sending mail to you they are going to send to this new address you create. The REST API is rather new, but I am looking forward to being able to automate ticket creation from scripts and events from Nagios or Munin.

# Getting Dirty
The easiest way to get this up and running is using Vagrant. If you aren't familiar with Vagrant I highly suggest taking a look at http://vagrantup.com to get it running, as it is much easier to use Vagrant to start playing with RT. Otherwise, I will provide instructions on getting it installed on Ubuntu and Debian.

## With Vagrant
Once you have Vagrant installed, perform the following steps:

    git clone git://github.com/cwebberOps/rt-vagrant.git
    cd rt-vagrant
    vagrant up

From there, wait for the instance to come up all the way and browse to http://10.0.0.10/rt

## Without Vagrant (The Manual Way)
If this is Debian Squeeze, you will need the backports repo installed and setup. To do this, please see http://backports-master.debian.org/Instructions/ for more details.

1. Install the packages. Add the password as you see fit. On Debian, you will need the '-t squeeze-backport' option to be passed to apt-get

    apt-get install rt4-db-mysql rt4-clients rt4-apache2 mysql-server postfix request-tracker4
	
2. Running the following commands to create all the necessary symlinks.

    ln -s /etc/request-tracker4/apache2-modperl2.conf /etc/apache2/sites-enabled/001-rt4
    ln -s /etc/apache2/mods-available/actions.conf /etc/apache2/mods-enabled/actions.conf
    ln -s /etc/apache2/mods-available/actions.load /etc/apache2/mods-enabled/actions.load

3. Restart Apache

    /etc/init.d/apache2 restart

4. Add the aliases for the general queue to /etc/aliases and run newaliases
	
    general: "|/usr/bin/rt-mailgate-4 general --action correspond --url http://localhost/rt"
    general-comment: "|/usr/bin/rt-mailgate-4 general --action comment --url http://localhost/rt"

5. From there you should be able to browse to http://<system name>/rt to get started.

# First Steps
If you used Vagrant to bootstrap a test instance, the default password is root:password. Once you are in there are a few things that are worth taking a look at:
1. Start by going to Tools > Configuration > Global > Group Rights and granting Everyone the right to create tickets. This will allow for people to send mail and create tickets. This is a setting that will likely be worth revisiting once you have a better handle on how you are going to break up your ticket queues.
2. Add a group for administrative users. The interface for this can be found at: Tools > Configuration > Groups > Create
3. Go back to Tools > Configuration > Global > Group Rights. Type the name of the new group you just created in the box below Add Groups. Then grant all of the permissions to that group as you see fit.
4. Add a user for yourself. The interface for this is located Tools > Configuration > Users > Create. Once the user is created, you will likely want to visit the Memberships tab and add the user to the new admin group.
5. Goto Tools > Configuration > Queues > Select. From there choose the General queue and then the Watchers tab. From there, find the new user you created and add them as an AdminCC. This will cause that user to receive email messages when tickets are created or updated.

# Notes About Going Production
* Make sure that the $rtname setting (what shows up in the ticket subject when dealing with mail) is set correctly. It breaks things if you change it after you have a number of tickets in the system.
* The postfix configuration that makes this all work will likely need a bit of tweaking to fit into any given environment.
* The actual configuration file for RT is located in the /etc/request-tracker4/RT_SiteConfig.d directory. The update-rt-siteconfig-4 command builds the /etc/request-tracker4/RT_SiteConfig.pm file. 
* Because of the credentials and other potentially sensitive information, you should get an Apache vhost setup with SSL for this site.
