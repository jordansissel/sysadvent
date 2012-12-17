# SSH keys shared with FUSE

This was written by [Kelsey Hightower](https://twitter.com/kelseyhightower)

With all its gems, syntax sugar and interfaces, Ruby is like the PS3 of system
programming. All the cool kids are playing with it, and there’s a huge library
of software to explore. It’s cool and all, but sometimes all you really want is
a Nintendo. Gaming in the ‘80s was all about the NES, and it was freaking
awesome!  I spent more hours than I care to admit playing all sorts of games,
but one sticks out in particular:

![](https://lh4.googleusercontent.com/-GVmY2WLDbgs/UM5z00hqxaI/AAAAAAAAAJg/Yz1MEa_1jfc/s256/bad-dudes.png Bad Dudes)

That’s how you introduce a video game. No 15 minute cutscenes and no confused
anti-heroes, just a straight-up challenge: Are you a Bad Enough Dude?

Sometimes I miss this simplicity.

High-level languages seem to get all the love from sysadmins these days, and
rightfully so, but what happened to the basics? Whatever happened to C? Well,
nothing; it’s been there, it’s here now, and it’ll be around longer than
anybody can predict. I’ve always been fascinated with C, but I never learned
enough of it to do anything useful. On top of that, most sysadmins I’ve
interacted with tend to shun it, so when re-visiting how to manage OpenSSH
public keys, it became a good excuse to force myself to build something with C.

## The Challenge

By default, OpenSSH expects to find public keys in user specific
"authorized_keys" files on a local file system, so my options are pretty slim
when it comes to managing public keys. Most of the time I simply end-up pushing
files around via rsync. Some people have even [resorted to patching
ssh](http://code.google.com/p/openssh-lpk/) to look up keys from LDAP. 

While I love the idea of managing public keys in LDAP, I’m just not willing to
run a patched OpenSSH server. What I want is "real-time" access to public keys
that works with OpenSSH out of the box.

## FUSE

Initially, I considered using NFS and a simple app to export public keys from
LDAP into files on an NFS share, but I found myself waiting for a cron job to
sync the keys, so I dropped that idea.

Enter FUSE. [FUSE](http://fuse.sourceforge.net/) is a library/API for creating
custom file systems. It sounds like overkill, but it’s really simple when you
break it down:  FUSE is about providing a file system interface to any type of
data. 

FUSE works by proxying local file system requests to a set of custom callback functions. What this means is that whenever an authorized_keys file is requested, using FUSE, I can query LDAP and return some data. 

So I decided to create [pubkeyfs](https://github.com/kelseyhightower/pubkeyfs).

## C

I could have used any of the popular scripting languages to write pubkeyfs. Most of them seem to have pretty good FUSE libraries and would totally work. But today we’re going Retro.

With the general design set, I started searching for C libraries. Unlike most
high-level languages, C does not have a central repository like
[rubygems](http://rubygems.org), [PyPI](http://pypi.python.org/pypi), or
[CPAN](http://www.cpan.org).

**Tip**: When searching the net for libraries just prepend 'lib' in front of
the thing you’re trying to do, and voila. I managed to find some great
libraries using this method including libfuse, libconfig, and libldap that made
it pretty straightforward to build pubkeyfs.

Developing in C is not much different from Ruby. The syntax is slightly
different, but many of the statements work the same. One of the biggest
differences is having to declare types for everything.

For example in Ruby I could just do this:

    count = 1

But in C, we have to do this:

    int count = 1;

That additional boilerplate turns a lot of people off when it comes to C. You
have to declare types for everything, and functions are strictly defined. It’s
more overhead than usual, especially coming from a scripting language, but I
think the pain is totally worth it. By using types we get  huge speed benefits
at runtime and an increase in readability. 

## Code

While I won’t be giving a full tutorial on programming in C, I would like to
review one of the utility functions used in pubkeyfs: `initialize_config()`.

Lets start with the
[utils.h](https://raw.github.com/kelseyhightower/pubkeyfs/master/utils.h)
header file. 

We start off by defining the constants UID_MAX and MAX_CONFIG, which are used
to set fixed sized arrays for holding configuration data. This is one of the
largest barriers to learning C; manual memory management. You the programmer
are totally responsible for making sure that strings fit into buffers. 

    #define UID_MAX 128
    #define MAX_CONFIG 256

Next we define the `pkfs_config` structure which will hold our LDAP
configuration settings. Structures allow us to associate multiple pieces of
data with a single object. It’s kinda like a hash in Ruby.

    struct pkfs_config {
      char base[MAX_CONFIG];
      char dn[MAX_CONFIG];
      char uri[MAX_CONFIG];
      char pass[MAX_CONFIG];
      char key_attribute[MAX_CONFIG];
    };

Then we declare our `initialize_config()` function. One big difference you’ll
see in the function definitions is we have to specify the return type and the
types of the arguments. In the case of `initialize_config()` we do not return
anything. The `initialize_config()` function does all its work and updates the
pkfs_config structure in the body of the function.

    void initialize_config(struct pkfs_config *config);

Finally, we define `initialize_config()` in [`utils.c`](https://raw.github.com/kelseyhightower/pubkeyfs/master/utils.c). I’m pretty sure it’s not the
most optimal C code around, but lets walk through it.

We start by logging a debug message via syslog that we have started
initializing the config. 

    syslog(LOG_DEBUG, "Initializing pkfs config");

Next we declare a few variables and initialize a new configuration object.

    config_t cfg;
    config_t *cf;
    cf = &cfg;
    config_init(cf);

Over the next several lines we load some LDAP configuration settings from
/etc/pkfs.conf:

    config_read_file(cf, "/etc/pkfs.conf");

    const char *uri = NULL;
    config_lookup_string(cf, "uri", &uri);
    strncpy(config->uri, uri, MAX_CONFIG);

    const char *dn = NULL; 
    config_lookup_string(cf, "dn", &dn);
    strncpy(config->dn, dn, MAX_CONFIG);

    const char *pass = NULL;
    config_lookup_string(cf, "pass", &pass);
    strncpy(config->pass, pass, MAX_CONFIG);

    const char *base = NULL;
    config_lookup_string(cf, "base", &base);
    strncpy(config->base, base, MAX_CONFIG);

    const char *key_attribute = NULL;
    config_lookup_string(cf, "key_attr", &key_attribute);
    strncpy(config->key_attribute, key_attribute, MAX_CONFIG);

Loading each setting follows the same pattern: set aside a variable to "hold" a
pointer to a string, lookup the string and store the results, then copy the
results into the corresponding member of the pkfs_config structure.

Tip: Functions like
[strncpy](http://stackoverflow.com/questions/1258550/why-should-you-use-strncpy-instead-of-strcpy)
are your friends because they help protect you from buffer overflows.

What’s up with all this copying of data around? Remember that manual memory management thing we were talking about? Let me explain.

Each of the config_lookup_string() calls allocates memory on the stack. The
stack should be considered temporary storage during the execution of a function
call. Once `initialize_config()` returns, that data goes away. If you try to
access that data later on, bad things will happen. Trust me, you will lose many
hours of your life trying to figure it out. 

Tip: A common pattern in C is to simply pass in a pointer to a variable or
structure and copy the things you care about into them. That way you can ensure
that your data can be used later on.

Now that we have updated the pkfs_config structure, we need to do a bit of
clean up, mainly free the memory allocated by `config_init()` and related
functions:

    config_destroy(cf);

What happens if we don’t call config_destroy? Well we would end up with memory
leaks, and those are bad too.  

# The Results: pubkeyfs

Like learning most things, C was a bit daunting at first, but with perseverance
(and google), this sysadmin made it through. I present to you pubkeyfs. Once
you have pubkeyfs
[installed](https://github.com/kelseyhightower/pubkeyfs#installation) and
configured, it’s pretty simple to use:

First we mount the file system:

    mkdir /var/lib/publickeys
    /usr/bin/pkfs -o allow_other /var/lib/publickeys

At this point FUSE will proxy file system requests for everything under /var/lib/publickeys/ to the mounted pubkeyfs file system.

Commands like ls and cat just work:

    % ls -lh /var/lib/publickeys/joe
    -r--r--r-- 1 root root 424 Dec 12 05:45 /var/lib/publickeys/joe

From this output I can tell that the size of the SSH key is 424 bytes.

Also, notice how the cat command has the ability to read the ssh public key for the joe user. It’s as if the file was on disk.

    % cat /var/lib/publickeys/joe
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDHo+5nVpxDhnWBPhEuQ7D7ZYELvA5+fPEWfHmMUwBdW069FSfX1LtbVAUKW7NGMfCxTijQMfvmFt7i+o28uqrVGN+xlDdkKTarPYO/Ux6Rukw0D5RZLVDVdRIOV8Si02pkFp4ezs1NFnCFsPTXD8U4cQ1lok//x123oKGsB4ZWuRNf4PCaIdXDveXdQRbaV5SDo9JEt9VkmfSraH5JENguP51RhFJYzWQAB1QbRZrHYUfZbE+pb/XDTdSPidfRCvss9fDrrhviZjv1Gr8C9jbmSGRB8pKwGC/GWV/mj8nYEY1K3/0c/N9WWIPtmvNkQjq7eGsSUf0cM8ZbwWugr8cB
    OpenSSH + pubkeyfs

With pubkeyfs mounted and working, we can now configure sshd to look under `/var/lib/publickeys` for authorized keys files:

    AuthorizedKeysFile /var/lib/publickeys/%u

Then restart sshd:

    service sshd restart

I’m now able to login via public key authentication backed by LDAP:

    % ssh joe@example.com
    Linux debian 2.6.32-5-686 #1 SMP Sun Sep 23 09:49:36 UTC 2012 i686
    Last login: Sun Dec  9 03:37:04 2012 from 172.16.89.1

    joe@debian:~$

Simply put, pubkeyfs works by taking the basename of the requested path (in this
case /var/lib/publickeys/joe becomes joe), querying LDAP for the ssh public key
attribute, then returning the data via FUSE, and the best part is that SSH is
none the wiser.

## Summary

I’m really glad I chose C for this project as it was nice to finally write
something useful in a language with such a huge learning curve. Outside of the
week I spent fighting pointers and ramping up on C, I found developing in C
quite enjoyable. I also got to add another tool to my tool belt, one that gives
me a better understanding of programming, and will be relevant for years to
come. I feel like I’ve accomplished something by going outside my comfort zone;
I’ve feel like I’ve leveled up.

While pubkeyfs is far from complete, I did end-up with a nice solution for managing SSH public keys. I plan to keep hacking on pubkeyfs and will be announcing a beta soon. Feel free to try it out and tell me what you think, and if you see me around, let’s go for a burger....

## Further Reading

* [Learn C the Hard Way](http://c.learncodethehardway.org/)
