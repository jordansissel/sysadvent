# Day 3 - Sharing skills and permissions with code

This was written by [Jordan Sissel](http://twitter.com/jordansissel)
([semicomplete.com](http://semicomplete.com)).

Last year, I said, ["Don't be a human
keyboard,"](http://sysadvent.blogspot.com/2010/12/day-13-dont-be-human-keyboard.html)
and recommended avoiding this situation by building a dashboard for others to
consume instead of consuming your time and energy. Going deeper, why not stem
'human keyboard' requests by providing a very simple terminal- or web-based
tool?

Before we dive into solutions, we need to go over some of the problems. What
are some common reasons someone might invoke you as their computer interface?
In general, you probably have something that this person does not, such as
skills or permissions. 

Both skills and permissions problems can be solved in the same way. You can
codify these things into a tool or application that someone other than yourself
can use: turn your knowledge and access into a tool usable by others!

The simplest of these tools could be a script in the terminal or a button in
the web browser. Buttons are an important interface element in this situation
because of exactly the skill mismatch that I mentioned above - not everyone has
the skill to use the terminal (ssh, ssh keys, the shell, etc).  Going with the
'button' idea, there are nice options for those in the terminal with tools like
[dialog](http://invisible-island.net/dialog/):

    #!/bin/sh

    dialog --yesno "Do you want to do this?" 0 0
    result=$?
    echo

    if [ $result -eq 0 ] ; then
      # Do your thing here...
      echo "Doing it."
    else
      echo "Cancelled"
      exit 1
    fi

Running this script will give you a nice simple terminal tool. This kind of
terminal interface is good for some situations, but not all. The
[dialog](http://invisible-island.net/dialog/) tool itself has many more
features I won't discuss here, but you will benefit from at least playing with
this tool. Anyway, despite this kind of visual interface in the terminal, the
permissions problem isn't solved since this script is targeted at users other
than you, and you might need to share your permissions.

Permissions are more easily shared over remote interfaces because many access
control models lack the detail to express what you want to allow. In a human
keyboard situation, the 'server' is you and the 'client' is the person asking
for action, which maps pretty well to something like HTTP, so how about
exposing permissions _and_ skills through the web browser?

One caveat with doing this with the web is the number of technologies required
to make it happen. In the terminal, a button was as easy as a simple `dialog`
invocation, but you'll need a web server, html, and some code to make it
happen. Luckily there's lots of open source tools available to make building
this quicker.

I'll start with a simple example that has a button restart Apache. I'll use Ruby,
[Sinatra](http://www.sinatrarb.com/) and
[Bootstrap](http://twitter.github.com/bootstrap/) for this, but you can use any
tool that helps you get the job done.

    require "rubygems"
    require "sinatra"
    require "logger"

    logger = Logger.new(STDOUT)

    # The main page
    get "/" do
      haml :index
    end

    # Handle form submission
    post "/" do
      logger.info("Bouncing apache by request from #{request.ip}")

      # Should use Ruby's Open3 here, but let's keep it simple.
      @output = system("sudo apachectl graceful 2>&1")
      exitcode = $?.exitstatus
      @status = (exitcode == 0) ? "success" : "error"

      # Render it.
      haml :result
    end

There are [support
files](https://github.com/jordansissel/sysadvent/tree/master/2011/03/code/bounce-it)
(the templates and such) for this available
[here](https://github.com/jordansissel/sysadvent/tree/master/2011/03/code/bounce-it).

The above is pretty short in terms of code. Serve up the button (get "/") and
handle the form submission (post "/"). The deployment scenario for this is that
since your permissions are what are needed, it should run as your user (or as
something with appropriate permissions if you are shipping it to production).

The results look something like this:

![Main page](https://github.com/jordansissel/sysadvent/raw/master/2011/03/media/main-page.png)

---

![A success after clicking the button](https://github.com/jordansissel/sysadvent/raw/master/2011/03/media/success.png)

---

![A failure after clicking the button](https://github.com/jordansissel/sysadvent/raw/master/2011/03/media/failure.png)

Keep in mind the point of all of this is to code your way out of the human
keyboard situation. Don't know ruby? There's hope! Ruby, Python, Perl, and
other communities have lots of ways to serve the web. Beyond that, you probably
have a friend who can help you build the parts you aren't able. Lastly, there's
lots of resource online for learning how to build simple web applications like
this.

Of course, a simple button is just the start. With slightly more effort, you
could build a simple interface that allows users to, for example, pick a
database backup to restore to their own dev database, or perhaps exposing a
one-click 'silence all active nagios alerts for 30 minutes' feature for your
on-call folks?

A complex, real-world example of a skills and permissions sharing tool is
[Etsy's Deployinator](https://github.com/etsy/deployinator). Deployment in
many organizations is a complex mixing of different teams, skills,
permissions, and goals. A tool like Deployinator allows the operations team
to expose deployment functionality outside the operations team while hiding
the necessary complexities of the infrastructure. This allows ops to share
its permissions and skills by putting those in code and exposing it in the web
browser. Because of this, deployments no longer require the full attention of
the operations team, development doesn't block on operations, and no one is
used as a human keyboard. 

Definitely a brilliant win-win situation for everyone.

Putting permissions proxying and embedding your skills into code allows other
people to act with your permissions and skills in a controlled and repeatable
way without the burden of knowledge or complex access controls. Reducing the
knowledge required to perform a task will greatly reduce the amount of
documentation you need to write, too, since you can reduce most things to "If
this, then click this button" instead of documenting the complicated orchestra
of steps and knowledge.

## Further Reading

* Simple web frameworks in Python: [Denied](http://denied.immersedcode.org/), [Flask](http://flask.pocoo.org/), [Bottle](http://bottlepy.org/docs/dev/)
* Simple web frameworks in Perl: [Dancer](http://perldancer.org/), [Mojolicious](http://www.mojolicious.org/)
* ["Code as Craft" by Etsy Engineering](http://codeascraft.etsy.com/)

