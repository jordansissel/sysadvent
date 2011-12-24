# About DNS and Troubleshooting 

_Written by [Kris Buytaert](http://www.krisbuytaert.be/blog/) ([@KrisBuytaert](http://twitter.com/krisbuytaert/))_

Systems break. Whether you like it or not, one day, they will break. Either
when they are up and running or when you are building new stuff, you will one
day run into problems. Sometimes the error messages will guide you to the
solution quickly, but sometimes they give you no pointers at all, and
sometimes there are no error messages - just weird behavior. 

When that happens, it's time to pull out your troubleshooting skills. And so,
you read logfiles, you google, but you find nothing; you lie awake at night
trying to figure out what parameter in which config file you forgot. 

In the next couple of examples, I'll guide you to some issues I ran into over
the past decade. The list is far from exhaustive but it might give you an idea.

Let's start with some trivial stuff.

Who hasn't heard the "When I log on to server X, it takes a while" complaint
from a user? However, when you log on to the box, it goes lightning fast.
At first, you think it was a temporary glitch, but those 5 users keep
complaining. You go to their workstation and, indeed, from their desk things do
go a lot slower.  Turns out, they are on a newer part of the building that is on
the newest subnets in your organization, and for those networks, there are no
reverse mappings yet. As when the users log in, the server first tries to
figure out who they are, and sometimes it takes more than an acceptable timeout
before the lookup has been made.

Reverse DNS lookups causing performance problems are amongst the most common
problems around. They happen with databases, regular logins, etc, and sometimes
people doing performance comparisons of MySQL vs NoSQL tools fall into the <a
href="http://www.ruturaj.net/redis-memcached-tokyo-tyrant-mysql-comparison#comment-22565">trap</a>
, and they end up testing a Failing DNS lookup


The quick fix, adding the hosts to your /etc/hosts file is sometimes the only
alternative as you don't always have control over the reverse dns mapping.  

Luckily lots of daemons also let you disable the feature, such as the
skip_name_resolve entry in your my.cnf  or the UseDNS=no stanza in your
sshd.conf .

Don't think it's just the regular MySQL and sshd services, there's even web
applications that start performing slow because of dns problems, such as one <a
href="http://blog.avirtualhome.com/2008/12/03/wordpress-being-slow-a-dns-problem/">wordpress</a>
user figured out.  Some applications are slow when dns is misconfigured,  but
plenty of applications just don't want to launch when they can't figure out
where they are running.  e.g an old DRBD issue caused <a
href="http://www.krisbuytaert.be/blog/yet-another-dns-issue">drbdadm</a> to
crash. The easy ones to detect are the ones that actually tell you they can't
lookup localhost, or the node you are starting the application on, performance
issues are usually also a good pointer,  but plenty of times it just doesn't
show.

I've seen dns causing problems across the board: Xen, GFS, DRBD, Oracle and
many others, but apart from applications that have problems with misconfigured
DNS setups, there's also people who try parsing the output of dig to find out
the nameserver by grepping for "SERVER"  as in the comment section of the dig
output it notes what nameserver it used. Now imagine the output of dig
containing any of the root nameservers such as  A.ROOT-SERVERS.NET  indeed ..
the detection will fail 

DNS problems can creep up on you in expected ways in every part of your
infrastructure, so what can you do to prevent them?

The first and most important problem to solve to ensure that for every part of
your network, you have a correct reverse mapping. RFC 1912 clearly points out
that "Every Internet-reachable host should have a name." and "Make sure your
PTR and A records match.  For every IP address, there should be a matching PTR
record in the in-addr.arpa domain.  If a host is multi-homed, (more than one IP
address) make sure that all IP addresses have a corresponding PTR record (not
just the first one)."

So, if you have a 172.16 RFC 1918 subnet in your network  you want to have a
reverse zone that looks like: 

<code>
more 172.16.0.db  
$TTL    604800
$ORIGIN 0.16.172.in-addr.arpa.
@       IN      SOA     ns1.yournetwork.org. root.yournetwork.org. (
                     2010101501		; Serial
                           3600         ; Refresh
                           3600         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
        IN      NS      ns1.yournetwork.org.

1	IN	PTR	ns1.yournetwork.org.
2	IN	PTR	zion.yournetwork.org.
3	IN	PTR	matrix.yournetwork.org.
</code>

For public networks addresses, you sometimes have to talk to your upstream
vendor for reverse mappings that match your domain. Sometimes they already have
a reverse-map.customerof.theirdomain.com, but they usually are happy to make
the updates or to delegate the administration whenever possible.  

The second problem when relates to updating DNS zonefiles: people often forget
to update the serial number of their zonefile. After hours and hours, the newly
added host still isn't known on the network or Internet and the zonefile on the
primary nameserver is showing it correctly. However, the nameserver and his
slave haven't realized there is a new zonefile around yet. Failing to update
the serial-number of the zonefile is the default problem that everybody falls
in to once in a while. What if you are using a YYYYMMDDID timestamp and you by
accident put in a YYYYDDMMID timestamp in place .. chances are you need to wait
a whole year before you can continue to use your old scheme, or you can add
2147483647 to the now-incorrect value as [documented
here](http://www.krisbuytaert.be/blog/serial-typo).


Before I let you guys go, I do have to point you to a tool you can't live
without: [http://intodns.com/](http://intodns.com/). This is an online service
that will check your public dns config, and point out different improvements
you can make. Try it! It's worth your time.

By now, you must realize that _everything is a funky DNS problem_, and as
@patrickdebois realized, DNS stands for Devops Need Sushi, but that's a
different post :) 
