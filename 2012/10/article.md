## Packages do too much.

This was written by [Miah Johnson](https://twitter.com/miah_).

Before we had configuration management tools our UNIX vendors added
similar functionality to their package managers. For example, the ability to
run arbitrary scripts during a package installation enabled automatically
starting the new service, generating a configuration, creating a default
database, adding users, and an infinite assortment of possibilities.

Of course, packages have other useful features like file checksums, dependency
resolution, metadata, cryptographic signatures. Again, these are features
that are typically provided by our configuration management tool.

Because of these overlapping features, we have race conditions. Imagine
the situation where we want to manage `collectd` with `chef`. Our goal is
a fully configured collectd instance being supervised by `runit`.

The chef package provider is basically going to run this command:

```
apt-get install collectd
```

Whats wrong with this? Well, let's take a look inside the collectd-core package:

```
[~/tmp/packages]$: ls
collectd-core_4.10.1-2.1ubuntu7_amd64.deb

[~/tmp/packages]$: dpkg -e collectd-core_4.10.1-2.1ubuntu7_amd64.deb
[~/tmp/packages]$: ls DEBIAN/
conffiles       control         postinst        prerm
config          md5sums         postrm          templates
```

Above, we've extracted the `control-information` from the collectd-core package.
You can see we have some files prefixed with `post` and `pre`. These are scripts
that will be run when the corresponding action is run. With that in mind, we will
take a look at `postinst` (I've removed the comments and blank lines for brevity)

    set -e
    . /usr/share/debconf/confmodule
    case "$1" in
        configure)
            db_get collectd/auto-migrate-3-4
            if [ "$RET" = "true" ]; then
                tmpdir=`mktemp -dt collectd.XXXXXXXXXX`
                hostname=`hostname`
                if [ -z "$hostname" ]; then hostname="localhost"; fi
                cp -a /var/lib/collectd/ /var/backups/collectd-"$2"
                /usr/lib/collectd/utils/migrate-3-4.px \
                    --hostname="$hostname" --outdir="$tmpdir" | bash
                rm -rf /var/lib/collectd/
                mkdir /var/lib/collectd/
                mv $tmpdir /var/lib/collectd/rrd
                chmod 0755 /var/lib/collectd/rrd
                # this is only available on Solaris using libkstat
                rm -f /var/lib/collectd/rrd/$hostname/swap/swap-reserved.rrd
            fi
        ;;
        abort-upgrade|abort-remove|abort-deconfigure)
        ;;
        *)
            echo "postinst called with unknown argument \`$1'" >&2
            exit 1
        ;;
    esac
    db_stop
    if [ -x "/etc/init.d/collectd" ]; then
      if [ ! -e "/etc/init/collectd.conf" ]; then
        update-rc.d collectd defaults 95 >/dev/null
      fi
      invoke-rc.d collectd start || exit $?
    fi
    exit 0

As you can see, the script runs `migrate-3-4.px` which upgrades RRDs and various
other files. It also starts collectd via the included init script and adds it
to the init system for automatic startup. These scripts are fine, usually, if
you're not managing your system with a configuration management tool. If
you _are_ running a CM then you've just discovered some code you need to
be aware of and either disable or work around.

Because `dpkg` and `apt-get` lack a good way to disable these scripts, they will be
run when you install or remove packages. There are, of course, other ways to remove
them, but its going to add to your backlog. Additionally, you will have to make
your CM tool handle disabling that init system and stopping the current instance
of collectd. Hopefully, this doesn't change to often, but its entirely possible
that collectd may switch to init systems (say, to upstart) and change how you
disable and stop it.

It seems like you would be better off managing the package yourself - rather
than fighting upstream decisions. In the long run, managing packages yourself
will guarantee the software meets your exact needs. You can version it
appropriately, customize build options, properly integrate it with your CM
tool, and appropiately test each package.

As I think more about this problem, I realize that most UNIX distributions are
doing operations a disservice. The common UNIX install is full of assumptions
about how you're going to use it and configure it. It's difficult to customize
without a series of DSL wrappers linked into your CM.

Why does it have to be so difficult? How is a UNIX wrapped in a CM different
from its variants? Once you've abstracted your infrastructure into code, what
is the difference between Ubuntu and Redhat or Solaris? The feature variation
between Redhat and Ubuntu is basically non-existent once you're using a CM.

Linux is Linux. The other variations are assumptions about how you want to use
the system. In reality, we want a CM to manage all of the resources installed
on the system. We want the ability to choose how each piece is deployed,
upgraded, configured, logged, etc.

What is the point of using a CM tool if it is only managing a small percentage
of the system? Ultimately infrastructure management is a problem waiting to be
programmed away. We need to continue thinking about this as we build new
services, because ultimately everything I've talked about regarding packages
appears roughly as a waste of effort. Think of all the energy that goes into 
the `collectd` postinst script above, and add the work you have to do to
essentially revert all the actions done by that script - wasting effort!

There are, of course, some ideas on how to do this. I think its something we
all need to start exploring, but a good starting point would be
[NixOS](http://nixos.org/nixos/).

I think Nix, and systems like it, are going to be our 'third generation' configuration
management systems. This idea was proposed before Nix, but I don't think it
received as much attention. You may have forgotten about rPath and their
[Conary](http://wiki.rpath.com/wiki/Conary) project.

Recently the GNU project forked the Nix package management to investigate using
Scheme as the internal configuration language (rather than bash). Their project
is called [Guix](https://savannah.gnu.org/projects/guix/).
