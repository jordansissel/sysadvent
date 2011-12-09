# Day 6 - Always Be Hacking

This was written by [John Vincent](https://twitter.com/lusis)
([blog.lusis.org](http://blog.lusis.org/)).

I got my start in computers a long time ago. Our school library had, if I
recall correctly, a few Apple IIe systems in a room off to the side. I remember
pretty clearly the first time I wrote something in BASIC. It was so awesome
watching this machine do exactly what I told it to do. I was in second or third
grade at the time.

The only computer I ever had at home as a kid was a Mattel Aquarius; thankfully
it had the cassette add-on.

I dabbled in some form of 'programming' over the years from typing code using
edlin out of Byte magazine and writing little gui apps in Tk to do most of the
system administration related stuff I write today.

Evidently, I've always been hacking, and you should be, too.

## Sysadmins of the Future

[Adam Fletcher](http://www.thesimplelogic.com/) did an open space at [DevOps
Days](http://devopsdays.org/) Boston this year about what system administrators
would look like ten years from now. The truth is that sysadmins in the future
will look a lot like they did twenty or thirty years ago - programmers.

It wasn't too long ago that the same guy who ran the system also wrote the code
that ran on the system.

That's what sysadmins need to get back to, today, if they have any hope of being
employable in the future. I'm not necessarily talking about writing the
application code that runs your business, but I'm not ruling it out either. Of
course, you might be thinking, "I'm not a programmer! I can't do that stuff".
In the words of [Stephen Nelson-Smith](http://agilesysadmin.net/), "With all
due respect, I call bullshit".

## You Already Program

When someone tells me that they can't program, I ask them to show me the last
shell script they wrote. Look back over the scripts you've taken from company
to company (you know you've done it). Look at the hyperconvoluted pipelines of
awk, sed, grep, sort, cut and uniq. Look at the command-line argument handling.
Look at the bash functions. Look at the loop constructs. Look at the subprocess
you spawn.

I want you to listen to something. It's a talk that Uncle Bob Martin gave at
RailsConf 2010. It's called ["Twenty Five
Zeros"](http://itc.conversationsnetwork.org/shows/detail4566.html). Once you
do, come back and reread this. If you weren't convinced before, you will be
after listening. Bob Martin talks mainly about traditional programming languages
and history in, but also talks about interpreted languages and the ever-common
ground of sequence (assignment), selection (conditionals), and iteration
(loops) - you think you don't do all of those in a shell script?

The fact is that, as a system administrator, you probably know more about the
inner workings of the systems you manage than anyone at your company. Not only
do you understand the details of what happens at the OS level but more often
than not, you're the one person with the most holistic view of how all the
components fit together, probably because you or your team were the ones to glue
all those components together.

## But Why?

There are several reasons _WHY_ you should learn to program, but here are the
three main ones in my mind.

## So That You're Self-Sufficient

Remember the first time you found a newsgroup post or web site that told you
the exact solution to the problem you were having and how to solve it? 

No? Me either. 

That's not to say it hasn't happened, but what is MORE common is that you found
a solution that ALMOST fit, and you munged it until it worked.

Then you left it there hoping that it never stopped working. Just to be sure
you could always find it again you bookmarked the page, printed a copy and also
ran a `wget -m` (because there might be pictures) and saved that somewhere. In
fact, I probably still have most of [Ben
Rockwood](http://cuddletech.com/blog://twitter.com/benr)'s
[Solaris](http://cuddletech.com/blog/?category_name=solaris) articles from
[Cuddletech](http://cuddletech.com/blog/) saved off somewhere on a dead hard drive.

But really, wouldn't it be more awesome if you could be the person who WROTE the
solution that someone else found? Adding Epic to Awesome, imagine if you could
just write it yourself from SCRATCH?

## So you'll have a job in the next five years

This one is probably the most painful for folks. The fact of the matter is that
sysadmins who CAN'T program and contribute more than just keeping the lights on
are going to find themselves less and less employable. The times, they are a
changing. Fish or cut bait. Insert other random phrase here. You aren't likely to
have a choice in the matter. This isn't a DevOps thing. It's just the reality
of the situation. The 'new' crop of operations folk are already ahead of you.

You might disagree with the above, and the future might prove it wrong, but
what if you find you like writing code? What if having programming skills
improves your business value and thus reflects positively upon your salary and
benefits?

## Career Flexiblity

I wish I had someone tell me the stuff I'm telling you years ago. Interests
change. People change. Economies change. You may discover that you enjoy
programming more and want to make a career shift. Better to learn that now than
when you're unable to switch financially or you find yourself out of work in
your originally chosen field.

## Learning To Program

We've already established that you can program and why you should learn more,
so how do you go about it? I'm going to make some assumptions, here, based on my
experience and how I learn.

## Tight Feedback Loop

I was never formally educated in computer science, and I find myself missing
quite a bit. One thing that made learning to program easier was using a
language with very quick feedback - how quickly can you try something?
How many steps does it take? I don't care what the language is that you start
with, but my personal preference is either Python or Ruby.

Both of these languages can work in the style you're familiar with in shell
scripts, but also ease you into both functional and object-oriented programming
concepts. They're very easy to get started with on any modern distro and have
amazingly rich REPLs (Read-Eval-Print Loop, an interactive shell for Ruby, 
Python, etc). I'm not ashamed to say that I learned what I know about both
languages more via [IPython](http://ipython.org/) and
[irb](http://en.wikipedia.org/wiki/Interactive_Ruby_Shell) respectively than
ever cracking open [vim](http://www.vim.org/). REPLs also provide instant
gratification when you do something right. This provides encouragement to keep
going.

## Scratch an Itch

Regardless of which language you pick, don't start theoretical. Find a problem
you have or recently had and solve it using that language. I like to credit the
phrase 'Hate Driven Development' to [Jordan
Sissel](https://twitter.com/jordansissel), but really sysadmins are more
likely to practice NDD: Neccessity driven development. We don't typically sit
down and write an application just to write one (not that you shouldn't do
that).

Once you've solved the problem, rewrite it to be a bit more flexible. Throw in
some parameterization and configurability. Try and make it a little more
generic.

Don't just write one-offs.

I know for a fact that a few scripts that I thought were one-offs are still
being used, today, to keep some core business functionality running.

Don't screw yourself with bad solutions. Don't screw the person who comes after
you.

## Practice

Rewriting and [refactoring](http://en.wikipedia.org/wiki/Code_refactoring) also
helps you practice the language. The next time you have a problem, don't
immediately reach for bash. Take a few minutes and think about possibly writing
it in your new language. If you have to solve the problem immediately, go back
and rewrite the solution to be less fragile.

## Publish and Share

Create public repo on [Github](https://github.com/) or
[Bitbucket](https://bitbucket.org/) and start putting what you write there.
Share it with the world. 

Don't let ego get in the way. 

You never know who you'll be helping down the road, and you never know who will
be helping you in the future.

## Next Steps

Remember, you should always be hacking. Here are a few things that I think we
as sysadmins need to know beyond the basics

* Perl

Every sysadmin should know some Perl. It's on every system. You might not be
able to get the latest and greatest dynamic language on the system, but Perl
will always be there.

* At least one functional language

Don't know what 'functional' means? [This might
help](http://www.haskell.org/haskellwiki/Functional_programming)

Functional programming concepts provide a new way to look at problems and often
can be a better way to solve them. If you're an emacs user and you've ever
modified your config, there's no reason you shouldn't go learn
[Clojure](http://clojure.org/) right now. Otherwise, it probably doesn't matter
which language you use.

* Learn to read Java

You don't have to learn to WRITE Java, but you should be able to navigate your
way through the basics of a Java program. Additionally, the JVM is becoming a
popular platform outside of Java with projects like Scala, JRuby, Clojure and
others. Those languages will often be coupled with leveraging the existing Java
ecosystem. Quite honestly, you should be able to at least read whatever
language your company writes its applications in. 

The dirty secret is this: once you learn one language, the others become easier.

* C

Yes, you should learn C at some point. It's not going anywhere.

These things won't happen overnight, and I don't know all of these languages,
either, but if we can manage to keep track of the differences between 5
different Linux distros and 3 flavors of Unix, we can handle learning a few
different languages.

Remember that inside your head is the most amazing computer ever. Use it to the
fullest and remember:

Always Be Hacking.

## Futher Reading

* [Learn Python the Hard Way](http://learnpythonthehardway.org/) - Free online; teaches you how to program in Python
* [Learn Ruby the Hard Way](http://ruby.learncodethehardway.org/) - Same as above, but with Ruby.
* [Learn C the Hard Way](http://c.learncodethehardway.org/) - Same as above, but with C.
