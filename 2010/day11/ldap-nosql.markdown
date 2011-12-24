#A Journey to NoSQL

_Written by Michael Stahnke ([@stahnma](http://twitter.com/stahnma))_

## The N00b 

When I was first learning about being a Unix Admin, I just wanted to know what
systems my team supported, so that when I got called at 2 AM, I could either
make some weak attempt at getting online and fixing a problem (I was new...very
new), or promptly help that application analyst find the correct support team
pager number.  It was the week before I first went into our pager rotation that
I realized something was very wrong.  I had no idea what systems we actually
supported.  I wasn't the only one.

There had recently been some form of reorganization right before I hired in at
this company.  What was once four teams (IBM AIX, HP-UX, Sun Solaris and Red
Hat Linux), was becoming three teams (Capacity Planning, Systems Implementation
and Systems operations).  However, there were still other server teams at other
sites, plus Unix workstation support, and some IRIX somewhere out there.  The
fundamental problem, though, was, "Do I have the ability to help the person who
has paged my team?"

## A solution...sort of

I found this state to be extremely non-desired, so  I started writing a Unix
server tracking system.  It started out as a basic web application utilizing a
[MySQL](http://www.mysql.com "MySQL.com") back-end.  It worked great.  The
teams loved it.  They knew what we supported and what we didn't.  Then, the
requests for enhancement came in.  I needed to add MAC addresses, world wide
port names, cluster licensing terms, customer information, out-of-band
management URLs, etc.  This quickly grew, but I was still happy with it. We
designed several workflow automations through the tool as well. However, as the
tool grew larger, and less maintainable, I was starting to get extremely
frustrated with it. 

While problems for this application were abundant, there were two issues that
made it less of an operational platform than I desired.  The first problem was
that in order to do any type of CRUD actions, you have to have database drivers
on the client.  This was a big challenge.  We had an extremely heterogenous
environment, multiple firewalls, and some ancient operating systems that
probably couldn't have had a MySQL driver loaded on them without sacrificing
some type of domesticated animal and praying to a deity that was anything but
righteous. 

The other problem was flexibility of schema.  Each time we added a new piece of
data to track, it had to be analyzed, and then added into the schema.
Normalization was great for one:many and many:many relationships, but then made
the SQL queries much more complex with joins or sub-queries, especially for
unix admins without much or any SQL background.  In short, the relational
portion of the RDBMS system was in the way.  

## Another solution...getting warmer  

I left that shop before that problem was really solved, but since I had an
opportunity again at my next assignment to solve a similar problem, I decided I
would try some things in a different way. My first thoughts were around putting
some form of web-services infrastructure in front of a basic RDBMS backed web
application. I thought that speaking HTTP would be easier than MySQL, Oracle or
even DBI for most clients.  I toyed with it and did some mock-ups, but I still
felt like the data model was complicated and required many calls and
client-side parsing to really get the data into usable formats for automation,
updates, or to generate [Nagios](http://www.nagios.com "Nagios.com")
configuration, etc.  It was time for something completely different.  

NoSQL. It was obvious. Of course, at this time (2006) I had never heard of the
term NoSQL, but looking back on it, that was the epiphany I had.  If
relationships are difficult to model and manage, maybe some other model would
work.  Then it hit me:  LDAP.  The LDAP container is designed for easy
replication, extremely granular security controls, and availability.  On top of
that, those features were all there out of the box.  Schemas could be
programatically  deployed, and many of the data model questions were things
like 'should this be single-valued or multi-valued'.  Those questions were
quite simple when compared to joining 17 tables to see a complete system
configuration in the old RDBMS I had authored.  As an added bonus, using LDAP
didn't introduce a new source of truth for the environment since it was in use
for account management.  

LDAP also had a good solution for the driver problem.  We were using LDAP for
user authentication, so our systems already had LDAP client libraries loaded.
Even the few that didn't, the client-side libraries were readily available,
even on my less-than-favorite flavors of Unix.   

We modified schema, populated data by hand, and then with some simple scripts.
Life was good...at least for a while.  After a couple years operating in this
mode, the schema became a bit more problematic.  Extending schema at will was
not the greatest idea I've ever had.  We also had a problem where some admins
would make new objectClasses rather than extend one, or inherit from one.  This
led to conflicts in schema and some data integrity issues.  None of it was
absolutely horrible, but in the end it smelled like a chilli dog left in a desk
drawer overnight.

## The search continues 
 
I had a lot of discussion about this problem with a group of my friends (and
eventual business partners).  We spent hours going back and forth on how to
model host information and metadata and expose that information to our
configuration management, monitoring, accounting, chargeback, and provisioning
systems.  It always came back to a discussion on discrete math: use [Set
Theory](http://en.wikipedia.org/wiki/Set_theory "Set Theory").  The best, and
possibly only sane way, to keep this data organized was to use set theory.  

Luckily, we had a greenfield to play with as we forming a new company.  We
tried it out.  We tried to not extend or customize schema for host information
beyond loading in well-known [IANA](http://www.iana.org "IANA") referenced
schemas. The basic premise, obviously, is that everything can be grouped into
sets.  We created an `OU=Sets` at the top level our LDAP directory.  Under
`OU=Sets`, we created a DN of of 'set name' for example `dn:
cn=centos5,ou=Sets,dc=websages,dc=com` is an entry in our directory.  It is
setup as a `groupOfUniqueNames` and contains the DN of each host that is in
fact a CentOS 5 host.  The nice thing about `OU=Sets` is you can just keep
adding things into it, without extending schema.  

It may seem a bit backward at first to have the attribute as the set name and
then the host `dn` as the entry, but it seems to work.  LDAP also allows groups
within groups, so nesting works perfectly. As an example, if
`cn=ldap_servers,ou=sets` exists, it may contain
`cn=ldap_write_servers,ou=sets` and `cn=ldap_replicas,ou=sets`.  Grouping in
this manner allows one change to cascade through the directory.  

Of course, with every good solution, there are more problems to be solved.  In
this case it's recursion.  [OpenLDAP](http://www.openldap.org "OpenLDAP.org")
and [389](http://directory.fedoraproject.org/ "389
Site")/[RHDS](http://www.redhat.com/directory_server/
"RHDS")/Fedora-DS/SunOne/iPlanet/et all don't seem to automatically recurse
nested groups, though I have heard that some LDAP implementations do.  Luckily,
it's not that big of a problem.  

## Recursion 

In this example, I'll be looking for all LDAP servers.  Our directory
information tree is setup such that we have three groups:

   *  ldap_write_servers
   *  ldap_replicas
   *  ldap_servers

The `ldap_servers` entry is a `groupOfUniqueNames` whose `uniqueMembers` are
the other two groups.  To traverse this, we'll need some recursion.  

## Sample Code

In my code, I most often use ruby.  When working with LDAP, I've used the
[classic ldap bindings](http://ruby-ldap.sourceforge.net/ "ruby/ldap") heavily,
but recently I've really taken a liking to
[activeldap](http://rubyforge.org/projects/ruby-activeldap/ "activeldap").
Activeldap borrows heavily from the [Active Record design
pattern](http://en.wikipedia.org/wiki/Active_record_pattern "Active Record
Pattern") and applies it to LDAP.  It is not a perfect translation of active
record, but it is quite nice for most operations on a directory server.

Activeldap requires some minimal setup to be useful.  You can install it with
gems or your favorite package manager.  

    require 'rubygems'
    require 'active_ldap'

    class Entry < ActiveLdap::Base
    end

    ActiveLdap::Base.setup_connection(
      :host => 'ldap.websages.com', :port => 636, :method => :ssl,
      :base => 'dc=websages,dc=com',
      :bind_dn => "uid=stahnma,ou=people,dc=websages,dc=com",
      :password => ENV['LDAP_PASSWORD'], :allow_anonymous => false)


This is a simple setup section for some code using activeldap.  Require the
library (and rubygems unless your environment will load them, or you installed
activeldap in some other method).  Then you run `setup_connection`.  The Websages
directory server requires SSL and does not allow anonymous bind, so a few more
parameters are used than you might see on a clear-text, anonymous setup. 

From there, it's really not very difficult to recurse through groups and find
the entries. 

    # Returns the members of a ldap groupOfUniqueNames
    def find_members(search, members = [])
      Entry.find(:all , search).each do |ent|
        # Ensure the search result is a group
        if ent.classes.include?('groupOfUniqueNames')
           # Check to see if each member is a group
           ent.uniqueMember.each do |dn|
             members << find_members(dn, members)
           end
        else
        # Add the results to the members array
         members <<  search
        end
      end
      # clean up the array before returning
      members.flatten.uniq
    end


The above code will find all members of a groupOfUniqueNames including entries of
groups within groups.  

My calling function is just:

    puts find_members('cn=ldap_servers')

Another excellent feature of activeldap is that if you simple `puts` an
activeldap object, the
[LIDF](http://en.wikipedia.org/wiki/LDAP_Data_Interchange_Format "LDIF")  text
for the object is displayed on standard out. 

    Entry.find(:all , "cn=ldap_servers").each do |h|
      puts h
    end

Produces a simple LDIF output:

    version: 1
    dn: cn=ldap_servers,ou=Sets,dc=websages,dc=com
    cn: ldap_servers
    description: Hosts acting as LDAP Servers
    objectClass: groupOfUniqueNames
    objectClass: top
    uniqueMember: cn=ldap_replicas,ou=sets,dc=websages,dc=com
    uniqueMember: cn=ldap_write_servers,ou=sets,dc=websages,dc=com

## LDAP is a good answer

Now I can basically apply set theory for system management of meta data and
configuration information.  At Websages, we use our LDAP directory for nearly
everything and integrate it into our fact generation for puppet, our backup
schedules, our controlling IRC bots, and our broadcast SMSing while acting like
idiots at the bar.  

So next time you're faced with storing a bunch of host information or meta-data,
you might turn back to a technology that is non-relational, scales
horizontally, offers extensive ACL options, and is lightweight and fast.  LDAP was
NoSQL before the term was coined and often loses out on today's NoSQL
discussions, but it's track record is proven.  

When I see the term NoSQL, I am reminded of a classic Dilbert, "I assure you,
it has a totally different name."

![Dilbert](http://dilbert.com/dyn/str_strip/000000000/00000000/0000000/000000/00000/2000/200/2292/2292.strip.gif "It has a new name!")
  

