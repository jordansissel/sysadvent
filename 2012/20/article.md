# Data Driven Firewall Management

This was written by [Zach Leslie](https://twitter.com/xaque208).

During his [keynote presentation at PuppetConf
2012](http://www.youtube.com/watch?v=-Ykb2j2ojYU&feature=youtu.be), Tim Bell
said something about the way in which machines can be classified that stuck
with me:

> The service model we've been using ... splits machines into two forms. The
> _pets_: these are the guys you give nice names, you stroke them, you look
> after them, and when they get ill, you nurse them back to health, lovingly.
> The _cattle_: when they get ill, you shoot them.

What follows is my attempt to explain the impact those words have had on the
way I think about firewall management.

## Firewalls As Pets

Managing firewalls has always felt like caring for those pets.  By their
nature, firewalls are uniquely connected to several networks - deciding what
traffic should be allowed to pass.  No other role in the network can
make those decisions quite like the firewall due to its strategic placement in
the architecture.  There is often only a single unit controlling access for a
specific set of networks at any given time.  As such, rules about how traffic
should be handled are specific to each firewall placement or cluster.  

Perhaps you manage one with a web interface, or if you are lucky, execute
commands at a shell, upload data, etc.  You take backups and hope nothing goes
sour with the hardware.

Like many people, I like reusing my previous work to gain more benefit from my
efforts than I originally intended.  It's the force multiplier.  If I write a
method that does X, I should be able to apply X in lots of places without much
additional work.  When dealing with a unique box like a firewall, I've found
myself stuck with very little reuse of my efforts; one unit of gain for one
unit of effort, etc.  Web interfaces don't usually lend themselves to help
understand *why* rules are in place, or *why* the configuration is just so.  If
there is a comment field, you might be able to drop a link to a ticket tracker
or some such to provide you some external information, but even then you might
loose historical context.  Certainly, configuration management alone does not
gain you this context, but if you store your configurations and code in a
revision control system, then you can look through the history of changes and
understand the full picture, even if its lifetime spans years.  Its fantastic.

Configuration management just extends mentality that software development has
had for years with respect to writing libraries that can be leveraged many
times over.

As I spend more time with configuration management as a discipline, I find
myself wanting to treat more machines like cattle so I can rebuild at will and
know with reasonable certainty what exactly has been done on a given system to
get it into its current state, as well as the reason.  If you construct data
that is consumed by various parts of the infrastructure and you want to make a
change, you need only manipulate the data to make it so.  In this way, you
force yourself to consider the architecture as a whole, and apply consistency
throughout, leaving you with a cleaner and more maintainable infrastructure.

## Refactoring is not just for the Devs anymore

Refactoring has the benefit of allowing you to take the knowledge that you
learned the first time around and apply that knowledge as you move forward.
Especially as the requirements for your infrastructure change over time, often
rebuilding the parts that are no longer sufficiently implemented is necessary.
If you have to start from scratch with every re-factor, the time required is
often daunting and so the re-factor gets pushed out until is critical that the
work be done.

Refactoring may not always apply to more mature environments where executions
are carried out with a project plans and don't change without summoning the
gods in the moonlight on the 13th day of spring, but even in these
environments, things fail and need replacement.

Combining the data that describes your infrastructure, and the code to rebuild
it, I question the need for backups.  In such cases as firewalls where there
is no data to save from the box in the event of a crash what remains?  Just the
configuration, assuming you ship logs off disk.

## What does it mean to be data driven?

When I think of a data driven infrastructure, I think of constructing a
model for how I want the  systems involved to behave and perform.  Your model
could include common data as well as unique data.  Perhaps only certain parts
of your system make use of this data over here, but this other data over here
might apply to multiple systems.

For a long time I thought that all the talk of data driven was just for the big
cloud providers or large enterprise.  Data driven is just a mechanism to
distill your configuration into reusable pieces, which we do with configuration
management anyway.  In puppet, its modules, or more accurately, the
*implementation* of the modules.

## Building The Model

Lets start constructing a model beginning with the common elements.  I've been
building all of my data models in YAML since its easy to write by hand and easy
to consume with scripts.  Eventually, we may have some better tooling to store
and retrieve data, but for now, this works.  So, we'll start with a network
hash and tack on some VLANs.

    ---
    network:
      vlans:
        corp:
          gateway: '10.0.200.1/24'
          vlan: 200
        eng:
          gateway: '10.0.210.1/24'
          vlan: 210
        qa:
          gateway: '10.0.220.1/24'
          vlan: 220
        ops:
          gateway: '10.0.230.1/24'
          vlan: 230

Now we can load the hash and take some action.  I'm loading this data with
hiera into a hash for puppet to use.  Dropping the above hash into a file
called `network.yaml`, you can load it up with a hiera call like so:

    hiera('network',{},'network')

This will look for a key called 'network' in a file called 'network.yaml' with
a default value of an empty hash, '{}'.  Now you can access your data as just a
hash.

We use FreeBSD as our firewall platform and PF for the packet filtering and
since we use puppet, I've compiled some defined types to create the VLAN
interfaces and mange parts of FreeBSD, all of which is up on GitHub.

Our firewalls also act as our gateways for the various VLANs, so we can
directly consume the data above to create the network interfaces on our
firewalls.

    #
    # Read in all network data for variable assignment
    $network  = hiera_hash('network',nil,'network')
    $vlans    = $network[$location][vlans]

    #
    # Create all the vLANs
    create_resources('freebsd::vlan', $vlans)

One function that puppet provides to inject the VLAN interface resources into
the puppet catalog is `create_resources()`.  If the parameters on the hash
match exactly the parameters the defined type expects as in the case above,
this works wonders.  If not, you'll need to create a wrapper define that
consumes the hash to break it into its various pieces to hand out to smaller,
more specific defined types.

Now lets model the network configuration of the firewall.

    ---
    network:
      firewall:
        laggs:
          lagg0:
            mtu: 9000
            laggports:
              - 'em1'
              - 'em2'
        defaultrouter: 123.0.0.1
        gateway_enable: true
        ipv6: true
        ipv6_defaultrouter: '2001:FFFF:dead:beef:0:127:255:1'
        ipv6_gateway_enable: true
        ext_if: 'em0'
        virtual_ifs:
          - 'gif0'
          - 'lagg0'
          - 'vlan200'
          - 'vlan210'
          - 'vlan220'
          - 'vlan230'
        interfaces:
          em0:
            address: '123.0.0.2/30'
            v6address: '2001:feed:dead:beef:0:127:255:2/126'

Much of the above is FreeBSD speak, but each section is handed to different
parts of the code.  Here we build up the rest of the network configuration for
the firewall.

    $firewall    = $network[$location][firewall]
    $virtual_ifs = $firewall[virtual_ifs]
    $ext_if      = $firewall[ext_if]
    $interfaces  = $firewall[interfaces]

    class { "freebsd::network":
      gateway_enable      => $firewall[gateway_enable],
      defaultrouter       => $firewall[defaultrouter],
      ipv6                => $firewall[ipv6],
      ipv6_gateway_enable => $firewall[ipv6_gateway_enable],
      ipv6_defaultrouter  => $firewall[ipv6_defaultrouter],
    }

Now we create the LACP bundle, ensure that the virtual VLAN interfaces are
brought up on boot, and set the physical interface address properties.

    create_resources('freebsd::network::lagg', $laggs)

    $cloned_interfaces = inline_template("<%= virtual_ifs.join(' ') %>")
    shell_config { "cloned_interfaces":
      file  => '/etc/rc.conf',
      key   => 'cloned_interfaces',
      value => $cloned_interfaces,
    }

    create_resources('freebsd::network::interface', $interfaces)

The puppet type `shell_config` just sets a key value pair in a specified file,
which is really useful for FreeBSD systems where lots of the configuration is
exactly that.

Now that we have build the network configuration for the firewall, lets do some
filtering on those interfaces.  In the same spirit as before, we'll look up
some data from a file and use puppet to enforce it.

For those new to PF, tables are lists of address or networks that have names,
so you can refer to the names throughout your rule set.  This keeps your code
much cleaner since you can just reference the table and it expands to a whole
series of addresses.  PF macros are similar but more simple.  They are just key
value pairs, much like variables.  They are useful for specifying things like
`$ext_if` or `$office_firewall` that can be used all over your `pf.conf`.  The
data blob for 'pf' might look like this:

    pf:
      global:
        tables:
          bogons:
            list:
              - '127.0.0.0/8'
              - '172.16.0.0/12'
              - '192.168.0.0/16'
          v6bogons:
            list:
              - 'fe80::/10'
          internal_nets:
            list:
              - '10/12'
              - '10.16/12'
          dns_servers:
            list:
              - '10.0.0.10'
              - '10.0.0.11'
              - '10.2.0.10'
              - '10.2.0.11'
          puppetmasters:
            list:
              - '10.0.0.20'
              - '10.0.0.21'
              - '10.0.0.22'
              - '10.0.0.23'
              - '10.0.0.24'
          puppetdb_servers:
            list:
              - '10.0.0.25'
      dc1:
        macros:
          dhcp1:
            value: '10.0.0.8'
          dhcp2:
            value: '10.0.0.9'
        tables:
          local_nets:
            list:
              - '10.0.0.0/24'
          remote_nets:
            list:
              - '10.2.0.0/24'
      office:
        macros:
          dhcp1:
            value: '10.2.0.8'
          dhcp2:
            value: '10.2.0.9'
        tables:
          local_nets:
            list:
              - '10.2.0.0/24'
          remote_nets:
            list:
              - '10.0.0.0/24'

While the puppet configuration might look like this:

    include pf
    $pf = hiera_hash('pf',{},'pf')

    $global_tables = $pf[$location][tables]
    create_resources('pf::table', $global_tables)

    $location_tables = $pf[$location][tables]
    create_resources('pf::table', $location_tables)

    $global_macros = $pf[$location][macros]
    create_resources('pf::macro', $global_macros)

At this point, we have configured FreeBSD gateway machine attached to a few
networks.  We have the PF configuration file primed with tables and macros for
us to use throughout our rule set, but we aren't doing any filtering yet.

I've thrown in some data to clue in some of the possibilities.  If you don't
want all ports reachable on your DNS and DHCP servers, you can use the tables
and macros above to do some filtering so that only the required ports are
available from other networks.

## An Example Implementation

Now that we can build firewall resources with puppet, this opens the doors for
all kinds of interesting things.  For example, say we want to open the firewall
for all of our cloudy boxes so they could write some metrics directly to our
graphite server.  On all of your cloud boxes you might, for example, include
the following code to export a firewall to be realized later.

    @@pf::subconf { "graphite_access_for_${hostname}":
      rule  => "rdr pass on \$ext_if inet proto tcp from $ipaddress to (\$ext_if) port 2003 -> \$graphite_box",
      tag   => 'graphite',
      order => '32',
    }

In the code that builds your graphite server, you might also add something like
this to ensure that the rest of your `pf.conf` can make use of the macros.

    pf::macro { "graphite_box": value => $ipaddress; }

Then on your firewall, you can just collect those rules for application.

    Pf::Subconf <<| tag == 'graphite' |>>
    Pf::Macro <<| |>>

Now all of your cloud boxes are able to write their graphite statistics
directly to your NATed graphite box, completely dynamically.

## Conclusion

This method still requires that you know the syntax of PF.  It also requires
that you know which macros to escape in the rule string and which to interpret
as puppet variables.  Personally, I am okay with this because I like the
language of PF.  Also, I don't know if the code complexity required to abstract
the PF language is worth the effort.  The `pf.conf` is very picky about the
order of rules in the file.  This complicates the issue even more.

I think my next steps will be to create some helper defines that will know how
to work with the order of PF.  Rather than have just one `pf::subconf`, perhaps
there will be many, like `pf::filter`, `pf::redirect`, etc.  Also, I'd like my
switches to be consuming the same data so that I can ensure consistency across
all of the devices involved in the network.

In talking to people about these concepts, I have come to think that this is
yet a solved problem when dealing with configuration management.  What I have
talked about above is in relation to an example hardware firewall, though I
believe the challenges this attempts to solve plague the host firewalls as well
as virtual packet filtering and security zones in virtual networks.

All of the code for this experiment is on GitHub.  I'd love to hear how others
are solving these kinds of issues if you have some experience and wisdom to
share.

Happy filtering.
