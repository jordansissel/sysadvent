## The Future of Pastebin

_This article was written by [Phil Hollenback](www.hollenback.net) ([@philiph](http://www.twitter.com/philiph))_

I assume everyone is familiar with the idea of a [pastebin][pastebin] - a website for
sharing text fragments with an emphasis on code fragments. Pastebins have been
around since 2002, according to Wikipedia. They're an incredibly useful
resource for sharing textual data and are something we, as sysadmins, need to do
on an almost continual basis. However, there are several problems with some
existing pastebin implementations:

* lack of command-line integration
* no version control
* no privacy settings

I recently came across a new (to me, anyway) alternative to the traditional
pastebin: [github][github] _gists_.  The following is a description of how gists work
and how they differ from traditional pastebin clippings.  I'll also describe
some ways you can collaboratively edit gists with one or more people.

### What's a Gist?

A gist is simply a text clipping with optional syntax highlighting, the same as
you would find in any other pastebin. You can go [look at some right
now](https://gist.github.com/gists) to get the idea.

So, why would you want to use this instead of a traditional pastebin? Pick a
file (say, a perl script) and hold on to your socks:

    $ gist test.pl
    https://gist.github.com/737292

That's it! You just created a syntax-highlighted text clipping anyone on the
internet can view.

Unfortunately, there is some up-front work to get this all set up. You can't
just post anonymous gists to github.com like you can with some pastebins.  I'll
detail that setup info below.  And, here's the really exciting part: there's an
emacs script to automate all of this!

## Initial Setup

As I mentioned, you have to have a github account to create gists (or to
comment on existing gists).  The good news is that's free and just takes a
moment to set up.  Once you have your account created, go to [your account
page](https://github.com/account) and click on `Account Admin`.  You will find
your API token on this page.  Take a moment to copy that down as you will need
it to set up your command-line gist client.

You should also click on `SSH Public Keys` in the account settings page and
upload your ssh public key.  you're going to need this to edit gists shortly.
Did I mention that gists are version controlled with git?

I'm assuming you have the git client installed for your linux or mac box
already, if you don't have that go get it now as you will be using git a lot
for all this. One thing that was not clear to me, initially, was how to set up
your local git config for gist access. This is controlled by your
`~/.gitconfig` file, which will look something like this:

    [user]
        name = <your name>
        email = <your email>
    [github]
        user = <your github username>
        token = <your api token>

You can actually read and write from this file via `git config` on the command-line, like this:

    git config --global github.user username
    git config --global github.token blah

the gist command-line and emacs clients use this mechanism to read from your `~/.gitconfig`.

Once you have this all configured, download and install the [gist command-line
client](https://github.com/defunkt/gist). I used the `gem install gist` install
method which worked just fine. Verify your setup works by creating a gist, as
above.

## Now What?

At this point you've got a simple, command-line pastebin client which
is a pretty useful thing.  For example, suppose you want to demonstrate some
code to someone on twitter. Instead of mucking with pasting your code into a
regular pastebin website, feed your script directly to the commandcommand-st
client.  Right here you've got an url you can paste into your tweet.  If the
viewer of your gist goes through the small hoop of creating their own github
account, they can leave comments about your gist too.

Don't worry, though - there's lots of other ways to use gists. For example,
there's an emacs interface to gists!

### Emacs Mode

The emacs interface for gists is gist.el.  It supports mostly the same options
as the regular command-line client with a few twists.  For example, you can use
`gist-list` to select from and open one of you public gists.

I've been using the emacs gist interface quite heavily to share gists with
others.  For example, if someone tells me 'check out my gist 741773', I can
just hit `<Meta>-x gist-fetch<RET>741773` to pop that gist right into an emacs
buffer.

Unfortunately the emacs mode suffers from some glitches due to problems with
ssl access in emacs.  I had to [hack on
gist.el](https://github.com/tels7ar/gist.el) somewhat myself to get it working
with Aquamacs on my mac. Thus while I'm pretty excited about gist.el, it's not
really ready for primetime.

### Markdown

In addition to plain text and programming language markup, gists also support
[Markdown](http://daringfireball.net/projects/markdown/syntax).  Actually they
support [Github Flavored
Markdown](http://github.github.com/github-flavored-markdown/), which includes a
few small tweaks of the original Markdown language.

I assume most readers are familiar with Markdown, but if you aren't, it's a
simple way to write structured ASCII text that can be easily turned into HTML
or other document formats.  The beauty of Markdown is it's completely readable
as straight ASCII as well as HTML.

To force interpretation of your gists as markdown, use the `.md` file extension
on the file you upload to create a gist.  When you view your gist on github you
will see it all dressed up with headers and bullets and everything.

### Private Gists

By default, gists are public.  This is the standard convention for pastebins -
everyone can see what you post.  This usually works just fine.  However, if you
want to protect your information, you can create a *private gist*.  There are
two differences between private and public gists:

1. public gists show up on the [gist main page](https://gist.github.com/gists).
1. public gists use easily guessable sequence numbers, private ones use hash identifiers.

For #2, public gists have incremented IDs like `73962` while private gists use
hashes like `d17b2652f7896c795723`.  In practice, this makes it difficult to
guess the ID (and URL) of a private gist.  Note there is no real security here
in the form of access controls - if someone obtains your private gist ID, they
can access it.  Thus, don't use private gists for passwords or other sensitive
information.

However, private gists work just great for information you want to protect but
isn't super critical.  I would feel fine pasting config files as private gists,
for example.

With the gist command-line client, use the *-p* switch to create a private
gist, or use  git-config to set your default gist posting mechanism to private.
If you are going to use gist as a pastebin to share system information such as
config files and scripts, you should probably use private gists by default.
The emacs interface supports similar functionality.

### Using git for Gists

As I mentioned earlier, gists are stored in a git repository on github.  That
means you can use them to collaborate on a documentation project.  Here's the
workflow:

1. Create a gist through web interface, cli, etc.
2. Give your friend Joe the url to that gist on github.
3. Joe visits that url and clicks 'fork' to get his own repository
4. Joe makes edits to his forked copy of your gist
4. Joe commits his changes to his repo, gives you his private clone url
5. cd into your local repository on your computer
6. Merge Joe's changes into yours with `git pull <Joe's private clone url> master`
7. commit your merged changes to your repo with `git commit -a` and `git push`

That's it! You're now collaborating with someone on a shared script, config
file, markdown document, or whatever.  Also, since this is a distributed
version control service, your collaborator can always fork your gist and start
modifying their own copy.

Remember that the gist web interface supports comments, so if you don't want to
do a full collaboration with someone, they can always just leave gist comments
instead (although commenters do need github accounts). Note that comments
don't seem to be exposed in the git repository, unfortunately.

I've focused on single-file gists in this description, but note that gists can
contain multiple files.  You can add additional files via the web interface or
by creating additional files in your local git repository.  This is another
important difference from traditional pastebins.

## Why Should I Care About This?

As a sysadmin, I'm excited about this tool for a number of reasons. Mainly, I
have a need to share scripts, config files, and the like with other sysadmins.
Currently, that involves emails or traditional cut-n-paste pastebins. Neither
of these solutions are very satisfactory.

What I want is a way to create public and private pastebins from the
command-line and share those via a URL.  I also want a way to mark up and
collaborate on text files.  Finally, it would be pretty handy if those files
were automatically version-controlled and stored somewhere out on the internet
for me.

Oh, also, that tool better not cost me anything, because I'm cheap and/or poor.
Hey look, github gists support all those features!  That's why I've started
using gists instead of the old pastebins.  The command-line and emacs
integration are the real power of gists.  Gists are a direct interface between
your terminal and the cloud, all wrapped up in a sysadmin-friendly package.

## Further Reading

* A good [blog writeup about gists](http://zerokspot.com/weblog/2008/07/22/github-presents-gist/).
* The [gist api][gistapi].
* The [gist homepage](http:/www.github.com/gists).

[github]: http://www.github.com
[pastebin]: http://www.wikimedia.org/wikipedia/en/wiki/Pastebin
[gistapi]: http://develop.github.com/p/gist.html
