# Day 8 - systemd

In the past 3 sysadvents, I've covered various process monitor tools like
[monit](http://sysadvent.blogspot.com/2008/12/day-3-babysitting.html),
[supervisord](http://sysadvent.blogspot.com/2009/12/day-15-replacing-init-scripts-with.html),
and [upstart](http://sysadvent.blogspot.com/2010/12/day-19-upstart.html). A
little while back I put Fedora 15 on my laptop and found a new one, systemd.

Since every tool seems to invent different terminology for the same things, for
the purposes of this article when I say 'process' or 'service' I mean the same
thing - a systemd service.

So let's dig in a bit.

## A First Look

The first thing you'll need to know is how to interact with systemd: starting
and stopping things - the usual business. The main tool for this is systemctl.
Run it with no arguments, and it gives you a list of all services. You can
also ask for status:

    % systemctl status rsyslog.service
    rsyslog.service - System Logging Service
              Loaded: loaded (/lib/systemd/system/rsyslog.service)
              Active: active (running) since Tue, 06 Dec 2011 22:32:58 -0800; 1 day and 1h ago
            Main PID: 803 (rsyslogd)
              CGroup: name=systemd:/system/rsyslog.service
                      └ 803 /sbin/rsyslogd -n -c 5

From the above, you can see a few notable and strange things:

* it's called "rsyslog.service" not simply "rsyslog"
* the config file is in /lib/systemd/system/rsyslog.service
* it's running, and for how long
* the pid, and that it said 'main pid' indicating it might support child processes somehow
* it uses cgroups.
* and finally, the process command and arguments

## A Sample Service

What's the config file look like?

    [Unit]
    Description=System Logging Service

    [Service]
    EnvironmentFile=-/etc/sysconfig/rsyslog
    ExecStartPre=/bin/systemctl stop systemd-kmsg-syslogd.service
    ExecStart=/sbin/rsyslogd -n $SYSLOGD_OPTIONS
    Sockets=syslog.socket
    StandardOutput=null

    [Install]
    WantedBy=multi-user.target

Most of the above should be fairly straight forward, though the 'unit' and
'install' sections have strange names. I'll explain it from top to bottom.

The 'Unit' section is documented in the `systemd.unit(5)` manpage. This section
seems to cover things like ordering and dependencies. There's a separate section
for defining the rsyslog service itself because systemd supports many mor things 
than simply services, according to `systemd.unit(5)` -

> A unit configuration file encodes information about a service, a socket, a
> device, a mount point, an automount point, a swap file or partition, a start-up
> target, a file system path or a timer controlled and supervised by systemd(1).

That's a lot of stuff, but I'm mainly interested in how to run things in
systemd.

## Controlling a Service

Let's stop it.

    % sudo systemctl stop rsyslog.service

There's no output. If you run 'stop' again, it will again have no output and
will still exit with success - a nice touch making scripted management easier.
Check the status:

    % sudo systemctl status rsyslog.service
    rsyslog.service - System Logging Service
              Loaded: loaded (/lib/systemd/system/rsyslog.service)
              Active: inactive (dead) since Thu, 08 Dec 2011 00:36:46 -0800; 3s ago
            Main PID: 803 (code=exited, status=0/SUCCESS)
              CGroup: name=systemd:/system/rsyslog.service

Remember that stop and start only affect the current run-time and don't impact
other events that might cause rsyslog to start (like the system booting). You
can disable things fairly intuitively:

    % sudo systemctl disable rsyslog.service
    rm '/etc/systemd/system/multi-user.target.wants/rsyslog.service'

And enable it again:

    % sudo systemctl enable rsyslog.service 
    ln -s '/lib/systemd/system/rsyslog.service' '/etc/systemd/system/multi-user.target.wants/rsyslog.service'

It's an odd thing. The 'stop' and 'start' commands output nothing, but 'enable'
and 'disable' output shell commands? Additionally 'disable' and 'enable' do
those actions for you, so I don't know what I am supposed to do with the output.
Is systemd trying to encourage me to use those commands myself instead of using
systemctl? By the way, if you enable an already-enabled service, you
get no output and success. Same for disabling. Confusing!

## Add Your Own Service

Here's the config file I used, and I put it in `/lib/systemd/system/fizzle.service`:

    [Unit]
    Description=Hello World

    [Service]
    ExecStart=/bin/sh -c 'echo Hello World; sleep 5'
    StandardOutput=syslog
    StandardError=syslog

    [Install]
    WantedBy=multi-user.target

Nothing else is required to make systemctl aware of our new service, so we can
start it normally like shown before:

    % sudo systemctl start fizzle.service

And since I told it to take stdout and ship it over syslog, `/var/log/messages`
has the output:

    % grep 'Hello' /var/log/messages
    Dec  7 17:45:26 nightfall sh[22616]: Hello World

That's a nice feature and is similar features in supervisord and daemontools (with
multilog).

Checking the status, I see it has died:

    % systemctl status fizzle.service
    fizzle.service - Hello World
              Loaded: loaded (/lib/systemd/system/fizzle.service)
              Active: inactive (dead)
              CGroup: name=systemd:/system/fizzle.service

I don't want it to be dead. As described in past sysadvents covering process
monitoring, "if it dies, restart it." What can be done? The
`systemd.service(5)` manpage says to add '`Restart=always`' to the
'Service' section.

Once that is added, starting 'fizzle.service' again will get it rolling. After
5 seconds it will die and be started by systemd:

    % sudo systemctl status fizzle.service | grep 'Active'
              Active: activating (auto-restart) since Thu, 08 Dec 2011 00:52:50 -0800; 5s ago
    % sudo systemctl status fizzle.service
              Active: active (running) since Thu, 08 Dec 2011 00:52:55 -0800; 771ms ago

## Supporting Odd Services

I originally wanted to use nagios as the example, not rsyslog as above, but
when installing nagios on Fedora 15, I received the usual `/etc/init.d/nagios`
startup script. However, when I ran it, I saw this output:

    % sudo /etc/init.d/nagios start
    Starting nagios (via systemctl):                           [  OK  ]

Huh? I thought that was strange, so when I dug into the script, I saw no
mention of systemctl. It loads `/etc/init.d/functions` which, by default,
seems to pass itself into systemctl. Asking systemctl what's up, it says:

    % systemctl status nagios.service
    nagios.service - SYSV: Starts and stops the Nagios monitor
              Loaded: loaded (/etc/rc.d/init.d/nagios)
              Active: active (running) since Thu, 08 Dec 2011 00:59:22 -0800; 31s ago
             Process: 23567 ExecStop=/etc/rc.d/init.d/nagios stop (code=exited, status=0/SUCCESS)
             Process: 23590 ExecStart=/etc/rc.d/init.d/nagios start (code=exited, status=0/SUCCESS)
            Main PID: 23601 (nagios)
              CGroup: name=systemd:/system/nagios.service
                      └ 23601 /usr/sbin/nagios -d /etc/nagios/nagios.cfg

Funky, though ignoring old SYSV start scripts, having an explicit 'ExecStart'
and 'ExecStop' settings can be useful in putting together systemd and software
that insists on being run with its own management tools to stop and start.

## Concerns

This section is more sourced from my feelings on systemd than from facts as
above, so take this with a grain of salt.

My first problem with systemd is the huge feature list. It looks to be trying
to replace /sbin/init, SYSV init scripts and runlevels, inetd, udevd,
automount, and supports cgroups, inotify, and more. That's a pretty
big feature space, and it reflects in the size of the code base. At this time
of writing, the lines of code in systemd around 82000 lines of code. Of those,
only about 1000 are tests. That's got me quite worried.

Further, systemd is a major consolidation of several components of the system. 
I don't really want software replacing major components (/sbin/init, cron, etc)
with practically no tests and a fixation on problems I don't have. A bug in
cron doesn't crash init, but now it just might. 

Lastly, systemd relies on DBus. It's pretty rare for sysadmins to have work
experience with DBus. It's another layer to debug when things break. Are
there debugging tools? I hope I'm just failing to google for this, but I
always come up empty when looking for a decent tracing tool for DBus messages 
- all the ones I run across are graphical.

The above problems are not terrible things on desktops which tend to have much
looser expectations on software reliability and more flexibility on outages.
However, put these on a server, and what do you have? DBus usage, major
software consolidation into a single binary, 82000 lines of code and basically
no tests - all this adds up to great worry and concern. How long until systemd
ships with RHEL or your preferred production Linux distribution?

## Conclusion

As stated, please take my concerns detailed above with a grain of salt. I'm not
writing off systemd as a failure by any stretch. Systemd itself has some
fairly nice features for running services. Pretty much anything you'd want to
configure for a service is available: cgroups, user, oom tuning, output
logging, cpu and I/O tuning, etc. The command line tools and documentation
are also pretty good. It's the default on all Fedora 15 and newer releases, and
you can get it on many other Linux distributions, so go on and play with it!

## Further Reading

* [Slides](http://0pointer.de/public/systemd-lca2011.pdf) giving an overview of systemd
