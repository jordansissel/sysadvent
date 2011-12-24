# Wikis and Documentation...they all suck! #

## Intro ##

This article is part one of a two part series and is a collaboration between
[Brandon Burton][solarce] and [Philip J. Hollenback][philiph] where they
explore the problems with Wikis, the challenges of writing good documentation
with today's tools, improvements to [Mediawiki][mediawiki] that
[Brandon][solarce] has implemented, and ideas for further improvements.

Part one focuses on the problems and challenges.

## The problem(s) with Wikis is... ##

It's a wiki!  Wikis are a slightly less-worse alternative to all other
documentation and publishing mechanisms. What's the worst thing about
wikis?  Well...

Here it is, 2010, and guess what? Every wiki works pretty much exactly
the same as they did back in 2001 (or, for that matter, back in 1995
when WikiWiki was invented).  Why has absolutely no real development
happened in the world of wikis?  I realize that there may be amazing
commercial wikis out there like Microsoft Sharepoint or Confluence,
but who uses them? Instead we all blindly set up our own Mediawiki
installations over and over again, with all the same annoyances and
problems. We are all unquestioning worshippers at the altar of the
wiki.

Let's get down to business: here are some of the numerous things
wrong with wikis, in no particular order:

### CamelCase

This seemed amazing back in 2001 because it allowed you to create your
own web pages on the fly. Amazing! However, the really cool thing was
the autocreation of web pages, not the mechanism of CamelCase.
Camel case was just an easy way to tell early wiki syntax parsers to
create a link to a new page. Nine years later, camel case is faintly
embarrassing.  It's like those pictures from the early 80s where guys
all had perms - seemed a good idea at the time.  Every single time
you try to explain wikis to someone, you have to apologize for how
camel case works.

### Markup Languages

Wiki markup languages must be amazing and precious, because we have
dozens of them to choose from.  Seriously? I have to remember whether
to write

    [[www.hollenback.net][http://www.hollenback.net]]

or

    [www.hollenback.net|http://www.hollenback.net]

or

    [http://www.hollenback.net www.hollenback.net]

based on which wiki I'm using?  That's awesome.

### Tables

If you ask 99% of office workers how to create a table, the answer is
*fire up Excel*.  Wikis actually manage to make that worse due to the
pain of creating tables.  The canonical table representation in wikis
is vertical bars and spaces, and you better not accidentally add an
additional column unless you want to spend 15 minutes tracking down
that one extra vertical bar somewhere.

    | *this* | *is an* | *awesome table* |
    | there | are | many like it | but this one | is mine |

### Attaching Images and Documents

Looking for a standard way to drop images into a document?  Good luck
with that. If you are lucky you can attach an image to a page,
assuming you don't accidentally exceed the web server file upload
size.  Wait, did you also say you want to flow the text around your
image?  You just made milk come out of my nose. Next you will be
asking for the ability to right-justify your image on the page! What
is this, QuarkXpress?

Attaching documents to a wiki is just as bad, because most wiki
software uses the same horrible upload mechanism.  As a bonus, any
Excel spreadsheet you attach to a page becomes an inert lump of
no-displayable, non-searchable data.

### Organizational Structure

We all love really shallow document hierarchies, right?  Must be true
because that's how every wiki works. Oh sure we all pretend there is a
tree structure in wikis but nobody ever uses it.  We all end up
creating zillions of top-level documents.  Which then brings us to the
issue of wiki search, which is also essentially nonexistent.  Most
people cheat and use a domain-specific google search instead, but then
you surrender your site to the whims of the almighty google.  That
means your search mechanism doesn't have any domain-specific
optimizations.


## The problem with documentation is... ##

The problem with documentation is that it's a lot of effort to write clear,
correct, and usable documentation. It takes time, not just any time, but
concentrated, distraction free time. The sort of time that there is never
enough of. Further, it takes a plan - a design for serving your intended
audience reasonably. It does not help that most of the common tools that are
chosen as the _repository_ of the documentation are not very good. Bad tools
drain your time.  Sadly, this includes the most popular tool (in my
experience), wikis, particularly my
favorite tool for keeping documentation, [Mediawiki][mediawiki].

## Documentation + Mediawiki == Maybe better ##

Having said all that, wikis are still the best widely available documentation
solution out there.  

Of all the available wikis, Mediawiki is the wiki most commonly chosen, and
this is the one that Brandon has had the opportunity to make a number of
improvements to.

Since Mediawiki is open source software and just PHP + MySQL + Text +
CSS, it is relatively easy to improve how it can be used to keep more effective
documentation. I've had the opportunity to make a number of changes to the
Mediawiki installation at my [day job][reliam] and I'm going to take part two
of this article to share those with you. Additionally, I have some other ideas
on how Mediawiki could be improved even further, a number of which have come
from reading the [Mediawiki book][mediawiki book]

In part two, we'll explore some improvements that [Brandon Burton][solarce] has
implemented at his [work][reliam] and some ideas [Brandon][solarce] and
[Philip][philiph] have for further improvements.

[solarce]: http://www.twitter.com/solarce
[philiph]: http://www.twitter.com/philiph
[mediawiki]: http://www.mediawiki.org/
[reliam]: http:/www.reliam.com/
[mediawiki book]: http://oreilly.com/catalog/9780596519681
