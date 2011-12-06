# Always Be Hacking

This was written by [John Vincent](https://twitter.com/lusis) ([blog.lusis.org](http://blog.lusis.org/))

I got my start in computers a long time ago. Our school library had, if I recall correctly, a few Apple IIe systems in a room off to the side. I remember pretty clearly the first time I wrote something in BASIC. It was so awesome watching this machine do exactly what I told it to do. I was in second or third grade at the time.

Up until I became an adult (I use that term loosely) and bought my first 486, the only computer I ever had at home was a Mattel Aquarius; thankfully it had the casette add-on.

I dabbled in some form of 'programming' over the years from typing code using edlin out of Byte magazine and writing little gui apps in Tk to most of the system administration related stuff I write today.

Evidently, I've always been hacking and you should be too.

# The sysadmin of the future

Adam Fletcher did an open space at DevOps Days Boston this year about what system administrators would look like ten years from now. The truth is that sysadmins in the future will look a lot like they did twenty or thirty years ago - programmers.

It wasn't too long ago that the same guy who ran the system also wrote the code that ran on the system.

That's what sysadmins need to get back to today if they have any hope of being employable in the future. I'm not neccesarilly talking about writing the application code that runs your business but I'm not ruling it out either. Of course, you might be thinking "I'm not a programmer! I can't do that stuff". In the words of Stephen Nelson-Smith, "I call bullshit".

# You can program because you've been doing it already

When someone tells me that they can't program, I ask them to show me the last shell script they wrote. Look back over the scripts you've taken from company to company (you know you've done it). Look at the hyperconvoluted pipelines of awk, sed, grep, sort, cut and uniq. Look at the command-line argument handling. Look at the bash functions. Look at the loop constructs. Look at the subprocess you spawn.

You want to tell me that you can't learn a language that makes that shit **EASIER**?

I want you to listen to something. It's a talk that Uncle Bob Martin gave at RailsConf 2010. It's called ["Twenty Five Zeros"](http://itc.conversationsnetwork.org/shows/detail4566.html). Once you do, come back and reread this. If you aren't convinced the first time around, you will be after that.

The fact is that, as a system administrator, you know more about the inner workings of the systems you manage than anyone at your company. Not only do you understand the details of what happens at the OS level but more often than not, you're the one person with the most holistic view of how all the components fit together.

# But why?

There are several reasons _WHY_ you should learn to program but here are the three main ones in my mind.

## So that you're self-sufficient

Remember the first time you found a newsgroup post or web site that told you the exact solution to the problem you were having and how to solve it? Me either.
That's not to say it hasn't happened but what is MORE common is that you found a solution that ALMOST fit and you munged it until it worked.

Then you left it there and you hoped it never stopped working. Just to be sure you could always find it again you bookmarked the page, printed a copy and also ran a `wget -m` (because there might be pictures) and saved that somewhere. In fact, I probably still have most of Ben Rockwood's Solaris articles from Cuddletech saved off somewhere on a dead hard drive.

But really wouldn't it be more awesome if you could be the person who WROTE the solution that someone else found? Adding Epic to Awesome, imagine if you could just write it yourself from SCRATCH?

## So you'll have a job in the next five years

This one is probably the most painful for folks. The fact of the matter is that sysadmins who CAN'T program and contribute more than just keeping the lights on are going to find themselves less and less employable. The times, they are a changing. Fish or cut bait. Insert other random phrase here. You aren't going to have a choice in the matter. This isn't a DevOps thing. It's just the reality of the situation. The 'new' crop of operations folk are already ahead of you.

## Career Flexiblity

I wish I had someone tell me the stuff I'm telling you years ago. Interests change. People change. Economies change. You may discover that you enjoy programming more and want to make a career shift. Better to learn that now than when you're unable to switch financially or you find yourself out of work in your originally chosen field.

# Learning to program

We've already established that you can program and why you should learn how. So how do you go about it? I'm going to make some assumptions here based on my experience and how I learn.

## Tight feedback loop
Not having been formally educated in computer science, I find myself missing quite a bit. One thing that made learning to program eaiser was using a language with very quick feedback. I don't care what the language is that you start with but my personal preference is either Python or Ruby.

Both of these languages can work in the style you're familiar with in shell scripts but also ease you into both functional and object-oriented programming concepts. They're very easy to get started with on any modern distro and have amazingly rich REPLs (Read-Eval-Print Loop). I'm not ashamed to say that I learned what I know about both languages more via ipython and irb respectively than ever cracking open vim. REPLs also provide instant gratification when you do something right. That provides encouragement to keep going.

## Stratch an itch
Regardless of which language you pick, don't start theoretical. Find a problem you have or recently had and solve it using that language. I like to credit the phrase 'Hate Driven Development' to Jordan Sissel but really sysadmins are more likely to practice NDD, neccessity driven development. We don't typically sit down and write an application just to write one (not that you shouldn't do that).

Once you've solved the problem, rewrite it to be a bit more flexible. Throw in some parameterization. Try and make it a little more generic. Don't just write one-offs. I know for a fact that a few scripts that I thought were one-offs are still being used today to keep core business functionality running at a few places. Don't screw the person who comes after you.

## Practice
Rewriting also helps you practice the language. The next time you have a problem, don't immediately reach for bash. Take a few minutes and think about possibly writing it in your new language. If you have to solve the problem right then, go back and rewrite the solution to be less fragile.

## Publish and Share
Create public repo on Github or Bitbucket and start putting what you write there. Share it with the world. Don't let ego get in the way. You never know who you'll be helping down the road.

# Next steps
Remember you should always be hacking. Here are a few things that I think we as sysadmins need to know beyond the basics

* Perl

Every sysadmin should know Perl. It's on every system. You might not be able to get the latest and greatest dynamic language on the system but Perl will always be there.

* At least one functional language

I don't care which one but you should. Functional programming concepts provide a new way to look at problems and often can be a better way to solve them. If you're an emacs user and you've ever modified your config, there's no reason you shouldn't go learn Clojure right now.

* Learn to read Java

You don't have to learn to WRITE Java but you should be able to navigate your way through the basics of a Java program. Additionally, the JVM is becoming a popular platform outside of Java via Scala, JRuby, Clojure and others. Those languages will often be coupled with leveraging the existing Java ecosystem. Quite honestly, you should be able to at least read whatever language your company writes its applications in. The dirty secret is that once you learn one, the rest become easier.

* C

Yes, you should learn C at some point. It's not going anywhere.

These things won't happen overnight and I don't know all of them either. But if we can manage to keep track of the differences between 5 different Linux distros and 3 flavors of Unix, we can handle learning a few different languages.
Remember that inside your head is the most amazing computer ever. Use it to the fullest and remember "Always Be Hacking".
