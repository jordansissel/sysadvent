# Upstart

_This article was written by [Jordan Sissel](http://www.semicomplete.com) ([@jordansissel](http://twitter.com/jordansissel))_

In past sysadvents, I've talked about [babysitting services][sysadvent 2008/03]
and showed how to use [supervisord][sysadvent 2009/15] to achieve it. This
year, Ubuntu started shipping its release with a new init system called Upstart
that has babysitting built in, so let's talk about that. I'll be doing all of
these examples on Ubuntu 10.04, but any upstart-using system should work.

For me, the most important two features of Upstart are babysitting and events.
Upstart supports the simple runner scripts that daemontools, supervisord, and
other similar-class tools support. It also lets you configure jobs to respond
to arbitrary events.

Diving in, let's take a look the `ssh` server configuration Ubuntu ships for
Upstart (I edited for clarity). This file lives as /etc/init/ssh.conf:

    description     "OpenSSH server"

    # Start when we get the 'filesystem' event, presumably once the file
    # systems are mounted. Stop when shutting down.
    start on filesystem
    stop on runlevel S

    expect fork
    respawn
    respawn limit 10 5
    umask 022
    oom never

    exec /usr/sbin/sshd

Some points:

* `respawn` - tells Upstart to restart it if sshd ever stops abnormally
  (which means every exit except for those caused by you telling it to stop).
* `oom never` - Gives hints to the Out-Of-Memory killer. In this case, we say
  never kill this process. This is super useful as a built-in feature.
*  `exec /usr/bin/sshd` - no massive SysV init script, just one line saying
  what binary to run. Awesome!

Notice:

* No poorly-written 'status' commands.
* No poorly-written /bin/sh scripts
* No confusing/misunderstood restart vs reload vs stop/start semantics.

The `initctl`(8) command is the main interface to upstart, but there are
shorthand commands `status`, `stop`, `start`, and `restart`. Let's query status:
      
    % sudo initctl status ssh
    ssh start/running, process 1141

    # Or this works, too (/sbin/status is a symlink to /sbin/initctl):
    % sudo status ssh 
    ssh start/running, process 1141

    # Stop the ssh server
    % sudo initctl stop ssh
    ssh stop/waiting

    # And start it again
    % sudo initctl start ssh 
    ssh start/running, process 28919

Honestly, I'm less interested in how to be a user of upstart and more
interested in running processes in upstart.

How about running nagios with upstart? Make /etc/init/nagios.conf:

    description "Nagios"
    start on filesystem
    stop on runlevel S
    respawn

    # Run nagios
    exec /usr/bin/nagios3 /etc/nagios3/nagios.cfg

Let's start it:

    % sudo initctl start nagios
    nagios start/running, process 1207
    % sudo initctl start nagios
    initctl: Job is already running: nagios

Most importantly, if something goes wrong and nagios crashes or otherwise dies,
it should restart, right? Let's see:

    % sudo initctl status nagios
    nagios start/running, process 4825
    % sudo kill 4825            
    % sudo initctl status nagios
    nagios start/running, process 4904

Excellent.

## Events

Upstart supports simple messages. That is, you can create messages with
'initctl emit <event> [KEY=VALUE] ...' You can subscribe to an event in your
config by specifying 'start on <event> ...' and same for 'stop.' A very simple
example:

    # /etc/init/helloworld.conf
    start on helloworld
    exec env | logger -t helloworld

Now send the 'helloworld' message, but also set some parameters in that message.

    % sudo initctl emit helloworld foo=bar baz=fizz

And look at the logger results (writes to syslog)

    2010-12-19T11:03:29.000+00:00 ops helloworld: UPSTART_INSTANCE=
    2010-12-19T11:03:29.000+00:00 ops helloworld: foo=bar
    2010-12-19T11:03:29.000+00:00 ops helloworld: baz=fizz
    2010-12-19T11:03:29.000+00:00 ops helloworld: UPSTART_JOB=helloworld
    2010-12-19T11:03:29.000+00:00 ops helloworld: TERM=linux
    2010-12-19T11:03:29.000+00:00 ops helloworld: PATH=/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
    2010-12-19T11:03:29.000+00:00 ops helloworld: UPSTART_EVENTS=helloworld
    2010-12-19T11:03:29.000+00:00 ops helloworld: PWD=/

You can also conditionally accept events with key/value settings, too. See the
init(5) manpage for more details.

Additionally, you can start jobs and pass parameters to the job with `start
helloworld key1=value1 ...`

## Problems

Upstart has issues. 

First: Debugging it sucks. Why is your pre-start script failing? There's no
built-in way to capture the output and log it. You're best doing '`exec 2>
/var/log/upstart.${UPSTART_JOB}.log`' or something similar. Your only option
for capturing output otherwise is the '`console`' setting which lets you send
output to /dev/console, but that's not useful.

Second: The common 'graceful restart' idiom (test then restart) is hard to
implement directly in Upstart. I tried one way, which is to in the 'pre-start'
perform a config test, and on success, copy the file to a 'good' file and
running on that, but that doesn't work well for things like Nagios that can
have many config files:

    # Set two variables for easier maintainability:
    env CONFIG_FILE=/etc/nagios3/nagios.cfg
    env NAGIOS=/usr/sbin/nagios3

    pre-start script
      if $NAGIOS -v $CONFIG_FILE ; then
        # Copy to '<config file>.test_ok'
        cp $CONFIG_FILE ${CONFIG_FILE}.test_ok
      else
        echo "Config check failed, using old config."
      fi
    end script

    # Use the verified 'test_ok' config
    exec $NAGIOS $CONFIG_FILE.test_ok

The above solution kind of sucks. The right way to implement graceful restart
, with upstart, is to implement the 'test' yourself and only call `initctl
restart nagios` on success - that is, keep it external to upstart.

Third: D-Bus (the message backend for Upstart) has very bad user documentation.
The system seems to support access control, but I couldn't find any docs on the
subject. Upstart doesn't seem to mention how, but you can see access control in action
when you try to 'start' ssh as non-root:

    initctl: Rejected send message, 1 matched rules; type="method_call",
    sender=":1.328" (uid=1000 pid=29686 comm="initctl)
    interface="com.ubuntu.Upstart0_6.Job" member="Start" error name="(unset)"
    requested_reply=0 destination="com.ubuntu.Upstart" (uid=0 pid=1 comm="/sbin/init"))

So, there's access control, but I'm not sure anyone knows how to use it.

Fourth: There's no "died" or "exited" event to otherwise indicate that a
process has exited unexpectedly, so you can't have event-driven tasks that
alert you if a process is flapping or to notify you otherwise that it died.

Fifth: Again on the debugging problem, there's no way to watch events passing
along to upstart. strace doesn't help very much:

    % sudo strace -s1500 -p 1 |& grep com.ubuntu.Upstart
    # output edited for sanity, I ran 'sudo initctl start ssh'
    read(10, "BEGIN ... binary mess ... /com/ubuntu/Upstart ... GetJobByName ...ssh\0", 2048) = 127
    ...

Lastly, the system feels like it was built for desktops: lack of 'exited'
event, confusing or missing access control, stopped state likely being lost
across reboots, no slow-starts or backoff, little/no output on failures, etc.

## Conclusion

Anyway, despite some problems, Upstart seems like a promising solution to the
problem of babysitting your daemons. If it has no other benefit, the best
benefit is that it comes with Ubuntu 10.04 and beyond, by default, so if you're
an Ubuntu infrastructure, it's worth learning.

Further reading:

* [Upstart's site](http://upstart.ubuntu.com/)
* [Upstart](http://en.wikipedia.org/wiki/Upstart) on Wikipedia
* [init(5)](http://manpages.ubuntu.com/manpages/lucid/en/man5/init.5.html) - upstart job configuration
* [initctl(8)](http://manpages.ubuntu.com/manpages/maverick/en/man8/initctl.8.html) - upstart control tool

[sysadvent 2008/03]: http://sysadvent.blogspot.com/2008/12/day-3-babysitting.html
[sysadvent 2009/15]: http://sysadvent.blogspot.com/2009/12/day-15-replacing-init-scripts-with.html "Replacing Init Scripts with supervisord"
[sysadvent 2010/03]: http://sysadvent.blogspot.com/2010/12/day-3-debugging-ssltls-with-openssl1.html "Debugging SSL/TLS With openssl(1)"
