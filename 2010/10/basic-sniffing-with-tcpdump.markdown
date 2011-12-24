# Basic sniffing with tcpdump

_This article was written by [Evan Anderson](http://www.wellbury.com)_

## The How and Why of Sniffing

It starts with something like an innocuous-sounding error message during setup
of a new piece of software: "Fatal Error: Can't connect to server." You peruse
the configuration files again and can't see anything wrong. You check the
documentation and note that it isn't exactly clear on the syntax (FQDN of the
server or the DN of the server object the LDAP directory, etc). You know the
story-- the documentation is unclear and you're not sure if you've got things
configured right. You try it both ways and it still doesn't work. You scratch
your head, check for working name resolution on your machine again, and try to
think about what you might've missed.

This story plays out over and over with different OS's and applications but the
frustration is the same. "Why isn't this thing working?" "What do you mean
'Cannot connect' !?!" Wouldn't it be nice to see what's actually being sent
back and forth on the wire instead of poking around in the dark?

I'm regularly surprised at how long it takes sysadmins to reach for the
sniffer. Many times I've found that sniffing traffic early in the process of
troubleshooting, often while taking stock of the issue and documenting the
symptoms, ends up revealing the root cause of issues. Sniffers aren't just for
"network guys", and as a sysadmin you'll do well to become familiar with a
sniffer for your operating system of choice.

The particular challenges related to bringing a sniffer to bear on a problem
typically come (a) from getting the sniffer installed, (b) deciding how to
capture the traffic you're looking for, and (c) filtering out extraneous
traffic such that you can end up with a sample size small enough to make sense
out of.

A piece of terminology worth mentioning as you get into using sniffers is the
phrase promiscuous mode. Typically an Ethernet network interface card (NIC) and
/or its driver will only forward broadcast frames or frames explicitly
addressed to the NIC's physical address up to the operating system. If the NIC
receives frames destined for other hosts (as would be the case in "old school"
shared-media Ethernet) they are simply ignored. In promiscuous mode all frames
received by the NIC are forwarded up to the operating system. Most operating
systems restrict switching an interface from normal operation to promiscuous
mode to only privileged users (root, Administrator, etc).

It's also bears mention that the architecture of the Windows networking stack
doesn't permit sniffing of traffic to 127.0.0.1 in any reasonably easy manner.
You can do this on most *nix operating systems, but the Windows networking
stack architecture isn't conducive to this type of capture.

Finally, this article talks in broad terms but, generally, is oriented toward
traffic capture on wired Ethernet networks. Capturing traffic on wireless
Ethernet networks, in particular, comes with its own set of concerns, and is
really a topic unto itself.

## tcpdump and WinDump

On *nix operating systems [tcpdump](http://www.tcpdump.org/) reigns supreme as
the sniffer of choice. Most Linux distributions, including many tiny
space-conscious embedded distributions, have a binary available. The pervasive
availability is a testament to its utility. In the Windows world, a port of
tcpdump called [WinDump](http://www.winpcap.org/windump/install/default.htm) is
available and mimics the functionality of tcpdump.  The
[WinPcap](http://www.winpcap.org/) driver is required to facilitate the
low-level packet capture.

The learning-curve for tcpdump isn't particularly steep assuming you have a
comfort-level with the command-line. The manual page for tcpdump is the
canonical reference. Some common command-line arguments that I use include:

* `-X` -- Display packets in hex and ASCII
* `-n` --  Don't resolve addresses to hostnames
* `-s N` -- Capture N bytes from each packet (defaults to 68). Set to 0 to capture entire
  packets.
* `-i x` -- Capture from interface x, or any (on most *nix operating systems) to capture
  from all interfaces (useful to see if you're getting anything, but captures
  from any aren't performed in promiscuous mode so only traffic to / from the
  host will be captured)
* `-D` -- Dumps a list of available interfaces (very useful in Windows since the
  interface names aren't easy things to type like eth0)

## Filtering traffic

Capturing everything on the wire isn't tremendously useful since you're likely
to be deluged with more information than you can handle. Turning off reverse
DNS lookups with the -n option is a nice first step (because the reverse
lookups themselves will end up generating more traffic), but filtering the
traffic is essential to pinpointing exactly what you're looking for. The
tcpdump filter syntax is very human-readable and reasonably intuitive so it's
pretty easy to get started.

Suppose you're interested in seeing a hex dump of packets on your eth0
interface, without resolving addresses to hostnames, for the LDAP protocol (or,
at least, the standard TCP port LDAP runs on). You can do that with the
command: tcpdump -i eth0 -n -X tcp port 389. The filter portion of this
command, tcp port 389 is fairly easy to understand. Other example filters
include:

* `host 10.1.1.1` -- Captures only traffic to / from the host 10.1.1.1
* `src 10.1.1.1` -- Captures only traffic sourced by 10.1.1.1
* `dst tcp port 22` -- Captures only traffic destined for TCP port 22

Bear in mind that filters that mention "src" and "dst" only capture one
direction of a conversation because they only match against the source or
destination address or port number.

Using boolean operators allows you to get fancier with your capture. Suppose
you're connected to a host with SSH (or RDP, in the Windows world-- just
substitute 3389 into the example) and you want to capture all traffic except
the traffic moving between the remote host and your machine (hypothetically at
10.1.1.2). You can use the boolean not operator to exclude that traffic with
the very simplistic filter: `not host 10.1.1.2`

While that filter will work, it will also exclude all other traffic between
your computer and the remote host. With some clever use of parenthesis and the
boolean and operator you can construct a more complex filter that allows any
non-SSH traffic between your computer and the remote host to be captured: not
(tcp port 22 and host 10.1.1.2) (Beware that using parens on a *nix OS may
require you to surround the filter expression with quotes since your shell is
likely going to see the parenthesis as shell metacharacters!)

As a general filtering strategy, if I know what the traffic is that I'm trying
to capture I write a filter that includes only the traffic I'm looking for. If
I'm unsure about what I'm looking for I begin by capturing everything for a
short period of time, reviewing the captured data, and creating a progressively
longer filter excluding more types of traffic that aren't what I want. So, a
filter that might start as something really simple like ip might become ip and
not (tcp port 443 or icmp or tcp port 80 or tcp port 22 or udp port 53) as I
find traffic that I don't want to see in my capture.

The best way to get familiar with tcpdump filters is to start using them.
Capture known traffic and attempt to filter it. The manual page provides some
much more detailed examples (performing bitwise comparisons of TCP header
fields to catch packets with particular flags set, etc) to get you started.

## Saving captures

tcpdump has the handy feature of allowing you to save captures to disk and
replay them. The replay functionality is particularly handy if you want to
capture traffic on one host then ship it to another host (or even another
program, like [Wireshark](http://www.wireshark.org/)) for analysis.

The -w file argument specifies that packets should be written to the specified
file rather than decoded and displayed. You can also use the optional -C
argument to limit the size of capture files and the -W argument to specify the
number of capture files to maintain. For long-term traffic analysis the latter
two options can be used to create a "ring buffer" of capture files that will be
re-used ad infinitum.

Once you've captured traffic you can "play it back" with tcpdump by using the
-r file argument to read the captured traffic from file. Traffic read from a
file "acts" like traffic being captured from an interface so all the
command-line arguments to manipulate the output behaviour, and to filter the
traffic stream, are applied in the same manner as traffic being captured from
an interface.

## Getting to the traffic

As we've already seen with using tcpdump's capability to write captures to disk
remote executing of tcpdump is one method that can be used to capture traffic
in situations where the traffic might not flow to or from your computer. If you
need to monitor traffic between hosts where you can't run tcpdump you'll have
to think of some way to bring the traffic to you. Some options to get to the
traffic include:

* Switch-based monitoring - Different Ethernet switch manufacturers call this
  mechanism by different names (SPAN, port-mirroring, monitor ports), but the
  functionality is the same. The Ethernet switch can "tee" the traffic in one
  or both directions from one or more ports into a dedicated "monitoring
  port" where your sniffer is connected. Most of the time the monitor port
  won't function as a normal network connection while monitoring is enabled
  so be wary that you may need a second interface in your sniffer computer,
  attached to a non-monitor network port, if you want communication with the
  network as-normal while you are monitoring. This is typically the least
  disruptive method for getting your sniffer in-line with the traffic to be
  captured, but requires a switch with monitoring capability and the
  cooperation of whoever manages the switch.

* Insert a shared medium - It's a less common technique today with gigabit
  Ethernet being more pervasive, but an older technique for monitoring
  traffic included attaching a shared medium, like an Ethernet hub, between
  the host to be monitored and the LAN switch. Traffic moving through an
  Ethernet hub appears on all ports of the device, unlike an Ethernet switch.
  Attaching the LAN to one port of the hub, the host to be monitored to
  another port on the hub, and the sniffer to a third port permitted
  monitoring of the traffic between the host and the LAN. Since there aren't
  gigabit Ethernet hubs this method has become less commonplace as gigabit
  Ethernet has become more common.

* Physically intercept the connection - Most modern Linux distributions and
  Windows versions allow you to create a "network bridge" between two (or
  more) network interfaces. In cases where the traffic flow between the host
  to be monitored and the LAN is not so great as to overwhelm the CPU in your
  sniffer computer you can opt to create a network bridge and physically
  insert the sniffer computer between the host to be monitored and the LAN.
  Your sniffer software can be configured to capture traffic on the virtual
  "bridge interface". This method works for low bandwidth captures, but high
  traffic hosts can overwhelm the CPU of the sniffer computer with traffic.

* Redirect the traffic flow - You can redirect the traffic flow between the
  host and the LAN through various methods. ARP cache poisoning, using tools
  like [Ettercap ](http://ettercap.sourceforge.net/) can "trick" hosts into
  forwarding traffic through your sniffer machine. The specific details of
  using this tool are beyond this post but many guides are out there. Be warned
  that ARP cache poisoning may be detected by an intrusion detection system
  (IDS) as an attack. If you're going to use ARP cache poisoning on someone
  else's LAN be sure you've cleared it with the network or system
  administrators, lest you send them into a panic when their IDS starts
  sounding alarms.

  Another method for traffic flow redirection is to use a layer 7 proxy, such
  as [rinetd](http://www.boutell.com/rinetd/), to redirect traffic flows
  through your sniffer computer. With this method you would configure your
  sniffer computer to answer for the protocol to be captured and to forward
  those incoming connections to the host where the "real" server software is
  running. Client computers will need to be reconfigured to use your sniffer
  computer's IP address as their "server" unless you change the server
  computer's IP address and assume its address with your sniffer computer. This
  is the method that I use when I can't get access to a switch monitor port and
  don't want to run the risk of scaring somebody with ARP cache poisoning.

## From here?

The next time you're faced with an opaque and unhelpful "Can't connect to
server"-type message take a moment and fire up tcpdump to see what's happening
on the wire before you start double-checking configuration files or stopping
and restarting service programs. Mis-specified host names, malformed
configuration parameters, and a whole host of other maladies that could be
hiding behind that opaque error message can become visible immediately once you
look at the conversation actually taking place on the wire. Mysterious "delays"
and "timeouts" are great candidates for troubleshooting with a sniffer. And,
finally, even if you're not troubleshooting a problem just using a sniffer to
analyze protocols can provide you with valuable details that will help your
understanding.

Obviously, this article is just a brief introduction. tcpdump has capabilities
that I haven't mentioned, and there are a wealth of other tools out there that
can do more. Get out there and sniff some traffic!

Further reading

* [Wireshark and the Art of Debugging Networks](http://blogs.usenix.org/2010/11/08/wireshark-and-the-art-of-debugging-networks/)
* [tcpdump primer](http://danielmiessler.com/study/tcpdump/)
* [strace and tcpdump - SysAdvent 2008 Day 1](http://sysadvent.blogspot.com/2008/12/sysadmin-advent-day-1.html)
