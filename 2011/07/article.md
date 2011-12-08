# Communicate change where folks will come in contact with it

This was written by [Aaron Nichols](https://twitter.com/anichols/)
([www.opsbs.com](http://www.opsbs.com/))

Whether we like it or not, we sysadmins are all about "me". When someone else
sends an email about something, our interest in that thing is inversely
proportional to the length of the email. When stuff breaks at 3AM and we *know*
there was an email sent out about that, we go looking and can't find it - so we
call the person who sent it. 

There is a better way. 

This post is about communication and documentation for day-to-day stuff. This
is not the documentation you dig through when you have all day to sort out a
problem. This is the stuff you want, now, without getting intimate with a
search engine.

Pop the hood on any car, and you'll see an example of this documentation.
Right there - all the stuff you are most likely to care about when you are
looking under the hood. It doesn't matter if you've never driven this car or
not: the documentation is placed as close to the problem as it can get. 

Here are some examples. 

## Communication in your Config Management System

Today, most of your configuration-related changes should be distributed through
some sort of CM system. Since this is where most folks will go looking for the
status of things when they break, this is a great place to document the status
of things as they are changing. Here are some examples using puppet as the CM.

### Identify files that are managed by the CM system

The top of every file managed by your config management system should have a
line that looks something like this:

    # This file is managed by puppet - any changes made to this file
    # directly will be deleted
    # Source: puppet/modules/wibble/templates/wibble_a.erb

This makes it perfectly clear where to find this file if you want to edit it. 

If you are moving things from one CM to another, tag the old ones too so people
can tell which system is the source for a particular file. 

### Tell users about things they should know when they are running the CM manually or debugging it

If there's important information you want people to know about when they run
your CM in debug mode (presumably looking for problems) you can usually add
notifications. Comments in the code are great if someone is looking in the
right place, but messaging like below  directs them to that place:

In puppet you can use
['notify'](http://docs.puppetlabs.com/references/stable/type.html#notify) for
this:

    class java {
      notify { "WARNING: This module (java) is experimental and may break things!":; }

And you should see something like this when you run the manifests by hand:

    notice: WARNING: This module (java) is experimental and may break things!

### Send short email messages when things are changing, with links to more details

If you are making major changes to your CM and you need people to be aware,
send a short email out with a link to details. Make sure you include enough
keywords to make it searchable later on, but short enough to ensure people read
it:

> Everyone,
>
>
> I am renaming the 2 puppet modules 'wibble' and 'wobble'. I will be working
> on this over the next 2 days. This work is being done on the 'wibblewobble'
> branch. An explanation of these changes can be found here:
> http://wiki/why-wibblewobble-must-change

And add a notify to those modules warning users. Add comments to those modules
where users will see them. Put links to your wiki in both places. 

### Leverage your MOTD

It's very common to be working on a system and need to let people know you do
not want them making changes to the system or disturbing the state of things.
It's fine to send email about this, but don't get stabby when someone forgets
about your email at 4AM and "fixes" the system. 

My preference is always to put a message in the MOTD telling them about this.
Let's say I have stopped httpd on a system for a few days & I've acked the
alert in Nagios - I will also add this to the MOTD:

    ***************************************************
    NOTE: This system has httpd stopped for maintenance
    We are resolving some network problems on this host
    contact anichols@example.com if you have questions. 
    Time of this message: 2011-12-06 13:55:01Z

### If a script shouldn't be run - break it

In the above example we had httpd turned off because we were resolving some
issues. If you are in an environment where enabling httpd would cause a service
impacting event - make that harder to do.

If I want a script to stop running, and this includes init scripts or others, I
will typically disable the script with an exit along with a message to let the
user know:

    start() {
            # SCRIPT DISABLED - anichols 2011/11/11
            # See http://wiki/why-I-disabled-httpd-on-this-host for more info
            echo "This script is disabled, see http://wiki/why-I-disabled-httpd-on-this-host for more detail"
            exit

So when someone tries to use it they see this:

    [~]$ sudo /etc/init.d/httpd start
    This script is disabled, see http://wiki/why-I-disabled-httpd-on-this-host for more detail

You can do fancy stuff like conditionals so certain users can run the script
even, but the point is: Communicate what's going on and do it where the user
will come in contact with the change.

### If you have migrated to using a new tool, put a header on the old one

As an example, you are moving some graphing from cacti to Graphite, and you
want users to know about it. You want to keep the old cacti instance up because
it has valuable historical data you haven't moved yet, but you want folks to
stop asking you why the cacti graphs aren't accurate. 

At the top of cacti, in the header, put something like this:

    <font color=red>
    <strong>This cacti data is no longer updated</strong><br>
    This data is here for archival purposes, for current data visit
    http://awesome-graphite-url
    </font>

It's simple and people will see it. If they don't - you can safely ignore their
pleas of ignorance. 

## You get the point, the point is...

When you are working on systems and making changes, think about the other
people who will come in contact with your change and how you can make it
painfully obvious to them what is going on. Think about your own thoughtless
patterns when you are bleary eyed at 3am: what would make it easy for you to
know what is going on? 

## Further Reading

Like the example of car engine documentation being near the related area. There
are many lessons we, as sysadmins and operations folks, can learn from other
industries.

* [John Allspaw on "Systems
Engineering"](http://www.kitchensoap.com/2011/07/18/systems-engineering-great-definition/)
which links to a [NASA
Handbook](http://education.ksc.nasa.gov/esmdspacegrant/Documents/NASA%20SP-2007-6105%20Rev%201%20Final%2031Dec2007.pdf)
on the subject.
* [Matt Simmons on "Redundancy"](http://sysadvent.blogspot.com/2009/12/day-13-redundancy.html)
wisdom we can learn from the airline industry, from SysAdvent 2009.

