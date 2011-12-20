# What is Configuration Management?

Configuration management tools increase sysadmin efficiency and make sysadmin
life better.  As the systems we are responsible for grow larger and more
complex, we need these tools to help us increase control and reliability of 
ever growing quanities and complexities in computing. Examples of such tools
include Bcfg2, Cfengine, Chef, and Puppet - all of which are open source!

The traditional approaches to configuration management have been:

Configuring systems manually, in interactive root sessions, is error-prone and
extremely labor-intensive. Even somewhat-automated scripts, such as the typical
"ssh and a for-loop" solution, pushing ad-hoc changes are still error prone.
For example, if a system is down for maintenance while a change is being pushed
out, it will miss that change, and "state drift" will occur between it and
other systems in the same class that did receive the change. 

System imaging is a common strategy for dealing with complexities of config
management - make a copy of a system image, label it "gold master", and clone
it to make new systems. While this approach helps to crank out identically
configured systems, has the weakness that updating the master image can be a
pain and it does not KEEP the systems configured after the initial deploy.
It is also not very auditable (what changed between golden image v1 and v2?).

Many sysadmins still configure systems with more traditional manual, ad-hoc,
and hard-to-audit methods. In some cases, sysadmin teams build home-grown
tools to solve these problems. An example of this is
[Ticketmaster](http://code.ticketmaster.com/), who released their own config
management, "ssh and for loop" tool, and provisioning systems.

To increase the "extropy" potential of the system to combat the natural
tendency of this universe toward entropy (extropy, as the opposite of entropy,
is a state of high order and organization and complexity) -- in other words,
keep complex system operational, keep them from devolving, and document the
intended state of the system. 

Why do we care to do this? Well, why do we administer systems? Correct
configuration helps keep computer systems *in use by human civilization*.

CM tools free sysadmin's time for more challenging and creative system
engineering and architecture work and for taking naps which power such work.

## Minimize Manual Effort

Minimize manual configuration by automatically configuring new systems. This
works well because repeatable work is best left to computers; they don't get
bored, and they don't forget steps.

["Go away or I will replace you with a very small shell
script"](http://www.thinkgeek.com/tshirts-apparel/unisex/frustrations/374d/) -
you've probably seen this shirt before, right? How about hearing someone
recommend ["automating yourself out of a
job"](https://www.google.com/search?q=automate+yourself+out+of+a+job)?
Building systems and fighting fires without any tools is a slow task that is
difficult to repeat accurately, and with many sysadmin skills being
software-related, it is in your interest to automate system turn up,
maintenance, and repair. Automation helps reduce time spent in corrective
actions. 

Documenting the system's "desired state", including: Why is the system
configured this way? What are its dependencies? Who cares about the system?
This documenting capability helps protect against knowledge loss in both
forgetfulness and staff turnover. Moving configuration knowledge out of
individual sysadmin heads and into a version control system facilitates
alignment of efforts on a multi-sysadmin team. This idea is known
as "Infrastructure as Code" and brings us benefits of being able to apply
proven dev tools and methods (such as leveraging release engineering
methodology) - tag a new policy as "unstable", test it, then move the new
policy into the "stable" branch where servers will apply it.

## A Visualization

!!! INSERT IMAGE

1. Sys Admin configures a server manually, ad hoc, and hands-on.

!!! INSERT IMAGE

2. Sys Admin writes a configuration management tool program to configure a server. Then the CM tool (like a little sysadmin robot) configures the server.

!!! INSERT IMAGE

3. Sys Admin takes a nap, while the CM tool configures more servers, and keeps checking and re-configuring the servers (as needed) to keep them in compliance with the program.
                                                                     
## Getting Started

To encourage sysadmins to start using Configuration Management, the following
is a rough manual of how to do some small tasks in a few different, open source
configuration management tools demonstratiing what policies look like in common
open-source server.  Bourne shell examples are provided to help aid in
understanding.

## Using these examples

* Bourne shell
    Can be run on the command line or via cron
* CFengine
    Follow the quick start guide at http://cfengine.com/manuals/cf3-quickstart.html
    (In a nutshell, put into a promise bundle inside a policy file (example.cf)
    and run from the command line with "cf-agent -f example.cf -b $bundlename"; or
    integrate into the default policy set in promises.cf in
    the CFEngine work directory, often found in /var/cfengine/inputs)
* Chef
    Follow the quick start guide at http://wiki.opscode.com/display/chef/Quick+Start
    (In a nutshell, upload the recipe to Chef Server.)
* Puppet
    Follow the [Getting Started guide](http://docs.puppetlabs.com/learning/).
    (In a nutshell, Can be run as client of Puppet master, via cron or
    locally via the command line or triggered via Orchestration using
    MCollective.)

## Set Permissions on a File

* Bourne shell
    chmod 600 /tmp/testfile
* CFengine
    files:
        "/tmp/testfile"
             comment => "/tmp/testfile must
                         be mode 600 as it
                         contains sensitive
                         data",
             perms   => m("600");
* Chef
    file "/tmp/testfile" do
     mode "0600"          
    end                  
* Puppet
    file { "/tmp/testfile":
       mode => 0600;
    }

* Create with some content
    * Bourne shell
        echo 'Server will be down for maintenance 2 AM - 4 AM' > /etc/nologin
    * CFengine
        files:
             
            "/etc/nologin" 
                          
                 create     => "true",
                 edit_line  => down_for_maintenance,
                 # the details of the file editing policy are abstracted into a separate block 
                 comment    => "Prevent non-root users from logging on during maintenance window";
                 # the comment attribute is visible in verbose mode and in CFEngine reports, it
                 # documents the intention of the policy.
        
        
        bundle edit_line down_for_maintenance {
        # this is the separate block of the details of the file contents
            delete_lines:
                ".*";
            # empty entire file first
        
            insert_lines:
                "Server will be down for maintenance 2 AM - 4 AM";
                # make sure it contains just this one line
        }
    * Chef
        file "/etc/nologin" do
         content 'Server will be down for maintenance 2 AM - 4 AM' 
        end 
    * Puppet
        file { "/etc/nologin":
          ensure => present,
          content => "Server will be down for maintenance 2 AM - 4 AM", 
        }

## Install a package

* Bourne shell
    yum -y install httpd
* CFengine
    packages:  
              
        "httpd"

            package_policy => "add",
            package_method => yum,
            comment=> "Our web app is useless without the 'httpd' package";
* Chef
    package "httpd" 
* Puppet
    package { "httpd":
      ensure => present,;
    }
  
## Make sure a service daemon is running

* Bourne shell
    ps -ef | grep httpd >/dev/null 

    if [ $? -ne 0 ]  
      then /etc/init.d/httpd start 
    fi                            
* CFengine
    processes:                            
                                         
        "httpd"                         
    
             restart_class => "restart_httpd";
              # set "restart_httpd" to true if
              # "httpd" not found in process table
    
    
    commands:
    
      restart_httpd:: 
      # proceed only if "restart_httpd" is true
    
        "/etc/init.d/httpd start"
    
            comment=> "httpd must be up to enable access to our Web app";
* Chef
    service "http" do 
     action :start   
    end             
* Puppet
    service { "httpd":
      ensure => running;
    }

## Final Thoughts

There's going to be a learning curve to any config management system, but I have found that
the benefits in being able to audit, repeat, test, and share "desired state" in
code far outweigh any time spent learning the config management tools.

## Further Reading

* [MTTR is more important than
  MTBF](http://www.kitchensoap.com/2010/11/07/mttr-mtbf-for-most-types-of-f/) -
  John Allspaw presents that for many types of failure, speed of recovery is
  often more important than frequency of failure.
