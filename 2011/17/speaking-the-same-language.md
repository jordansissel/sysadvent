# Speaking the Same Language

Language is important.

You've probably had disagreements or confusions that, during or after, you
realized were caused by miscommunication or misinterpretation. Something got
lost in translation, right?

Language is important, so do you resolve these issues? Lawyers do it by
dedicating great lengths of text to defining terms to eliminate confusion.
What was the last legal document you read? Perhaps the constantly-changing
iTunes EULA? Did you read it? Did you skip reading it because it was 70 pages
long? Was it readable? Was it plain english?

What was the last legal document you saw that seemed approachable? Can you even
read [this document](http://images.apple.com/legal/sla/docs/iphone4.pdf) at the
default font size?

Legal documents are long for many reasons, but the main reason I believe is to
reduce loopholes or confusion by defining and using a common language and
vocabulary. Vocabulary is important. Most documents have embedded definitions
of just about every major term used. Look at your current employment contract -
how much of it is simply defining words?

Centrally defining all words allows two parties who speak different languages
to speak on a common ground. Look at the
[GPL3](http://www.gnu.org/licenses/gpl-3.0.html) and [Apache
2](http://www.apache.org/licenses/LICENSE-2.0.html) licenses compared to the
[MIT](http://www.opensource.org/licenses/mit-license.php) license. Both the
GPL3 and Apache 2 licenses specify more requirements or allowances than the
MIT one, but my point is that much of the raw text in both GPL3 and Apache 2
are definitions. Compare this to the MIT license which has practically no
definitions embedded.

## Verbal Communication

In your average day, it is unlikely you have the time or energy to spend
defining terms in the middle of every conversation. Trying to do this flow very
well in speech, does it?  Most of the time you might assume the other person
(or people) know what you mean when you say it.

I propose that the likelihood of one person understanding your words is in
inversely related to their distance from your context, job role, and other
factors you could have (or have not) in common.

Explaining something job-related to a fellow sysadmin will require a different
set of terminology, a different language, than doing the same to your manager,
someone outside your engineering group, someone in marketing, etc. The
knee-jerk reaction is often to assume the other person is stupid. They aren't
understanding you! It sucks. It increases tension and distrust.

Like I said, you probably don't have time to work with each person (or group)
to design a common terminology. You have stuff to do.

My best recommendation here is to study everyone. Watch what they say, how they
say it, and what you think they mean. Study their reactions when you say things.
If they appear confused, ask and clarify. Don't treat them like they're an idiot.
Speaking loudly and slowly doesn't help anyone, ask what is confusing, ask what 
needs clarification and definition.

Know your audience.

Avoid analogies. Analogies are you translating your words into other words you hope
the audience will understand. Bad analogies are very easy to make, and you can
accidentally increase confusion and distrust like the famous ["the internet is
not a truck"](http://en.wikipedia.org/wiki/Series_of_tubes) failure. If you have
bidirectional communication with a person, instead of making an analogy, why
not ask for clarification and definition? 

Pictures can help, too. Bought anything from Ikea recently? All the Ikea
furniture assembly manuals I've seen are only pictures. No words.

Study your audience.

If you study and interact with a given set of folks frequently enough, you should
more easily speak a language they understand. Marketing and PR folks probably
don't care about disks being full, but they care about the external impact of
that problem. Try to understand what a person knows and what they care about
and frame your words accordingly.

## Software Similarity and Language Problems

Language problems affect even groups with small distances between them.  Look
at logging tools: You'll see terms like facility, severity, log level, debug
level, source, and more all referring to pretty much the same things.  What
about monitoring? Nagios calls it a 'service'; Zabbix calls it an 'item' and
sometimes a 'check'; Xymon calls it a 'service'; Sensu calls it a 'plugin'.

All of monitoring term examples above mean pretty much the same thing, and
before you disagree, consider that I say they mean the same thing because they
look like the same thing from a distance. Knowing Nagios and learning a new
monitoring tool requires learning new term definitions as well as new software,
and overloaded terms (like 'service') can have different meanings in different
projects. It trips up the brain!

Look at features provided by similar tools, and each feature is likely to have
a different name for the same thing. Intentional or otherwise, this is a
language-equivalent of [vendor
lock-in](http://en.wikipedia.org/wiki/Vendor_lock-in), and it sucks.

Puppet calls it a module and manifest; Chef calls it a cookbook and recipe.
You can reduce learning curves if you use a common language in your systems and
projects. 

## When to Define Terms

It is worth defining terms if you need to have a long-lived common ground.
You want defined common terms and features of a project that stay defined
through out the project's life cycle.

As an example, there's a small group of folks who say, "[Monitoring
sucks](http://lusislog.blogspot.com/2011/06/why-monitoring-sucks.html)," myself
included. We got together to discuss ways to solve crappy monitoring problems,
and one of the tasks was to define a common set of terms - we went the route
lawyers go because having a common terminology ground would strengthen the
[#monitoringsucks](https://twitter.com/#!/search/%23monitoringsucks) movement.
Agree or disagree with the [definitions we came up
with](http://lusislog.blogspot.com/2011/07/monitoring-sucks-watch-your-language.html),
the point was to lay a path for discussion that could avoid religious wars over
confused terminology. The common terms were also chosen to help steer any new projects
to use the same terms and reduce the learning curve as a result.

## Parting Thoughts

Much of technical writing education focuses on knowing the audience. While
'technical writing' leans towards one-way communication (writer communicating
with readers), the ideas are important in general communication. 

Who are you talking to? What are their interests? What are the boundaries of
their knowledge?

## Further Reading

* [This page](http://www.prismnet.com/~hcexres/textbook/aud.html) gives a
  reasonable overview of audience analysis.
