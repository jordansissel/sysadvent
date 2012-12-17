# Diving into Alert Streams

This was written by [Alexis Lê-Quôc](https://twitter.com/alq)

As engineers, we pride ourselves in understanding our infrastructure. As we
spend time designing, building, and replacing its parts, we learn its quirks. We
discover
[coupling](http://en.wikipedia.org/wiki/Coupling_(computer_programming))
between areas we thought independent of each other. We are
often reminded that these beasts are complex systems and observing reality
often shatters our assumptions about how they *should* behave.

To tame this complexity and still keep operations running, we build a web of
sensors and checks to get humans notified when things go wrong. Alerts
become an integral part of our lives. They interrupt our work and our
conversations. They wake us up from deep sleep. We diligently respond, engage
in investigations, fix what need to be fixed, and move on with our lives until
the next check fails, etc.

Sound familiar? Let's do a little exercise. Out of the following alerts, which
are the ones you are most likely to fix? Alerts that:

* occurred the most often over the past 6 months?
* occurred the most often last month?
* were the most visible to the rest of the organization?
* woke us up yesterday at 3AM for the second night in a row?

Clearly, the last one is going to get your attention, even if only happened
twice during an entire year. It’s also the one that will be on top of your mind
when asked about the most pressing work that has to get done. The bias of
hindsight is very strong and loss of sleep justifies the work priorities, right?

Are all biases that obvious? How can we protect ourselves from drifting away
into a continuous string of “low-hanging fruits” and top-of-mind fixes? The
answer is easy to find and not that hard to get. It’s in the alerting stream
itself. It’s “in the computer”.

<img src="https://lh4.googleusercontent.com/-8objuGY3msQ/UM7F9b9caKI/AAAAAAAAAJ0/dAcRqjHja9E/s666/in-the-computer.jpg">

## Diving into the Alert Stream

To illustrate my point I have chosen to dive into our alerting stream from
Nagios. It’s a tool we (and a number of our customers) happen to use
internally. It is an objective source, it is reliable and it does not care if
it must wake us up in the middle of the night. It’s not a perfect view into
what’s working or not in our infrastructure, but it’s an early warning system as
shown in the following example.

<img src="https://lh4.googleusercontent.com/-l-UTObZF9bQ/UM7F-PkZwvI/AAAAAAAAAKI/fpavEHzND6Y/s720/nagios-stream-notes.png">

Nagios is also easy to analyze. All that we need is in /var/log/nagios3/nagios.log.

In this particular case, the data is parsed on the nagios server with a simple
bit of python code, sent over to a SQL database for storage, and rolled up into
a set of csv files.

nagios.log ---> a few sql tables ---> csv files ---> analysis

CSV are an ideal format for data that simple: easy-to-write, easy-to-read, well-supported by tools like [numpy](http://www.scipy.org/), [pandas](http://pandas.pydata.org/) and [R](http://www.r-project.org/).

R provides me with a nice platform to explore my Nagios data set and answer a
few basic questions.

## Asking Questions of the Data

What are the trends?

Having consolidated alerts by day of the year, split between notifying alerts and non-notifying failing checks in by_day.csv according the the following structure:

    day_of_year,notifying,daily
    1,1,12
    1,0,426
    2,0,1158
    2,1,2
    3,0,630
    3,1,48
    4,0,1398
    4,1,76
    5,1,8
    5,0,834

R provides an easy way to plot data fairly cleanly with the ggplot2 package.
You can get similar results via d3.js (which we use to produce similar reports
on the web).

    alerts_by_day <- read.csv(‘by_day.csv’)
    ggplot(alerts_by_day, aes(day_of_year, daily, color=factor(notifying))) + geom_line()
    + xlab("Day of year")
    + ylab("Service Alerts")
    + ggtitle("Notifying v. silent alerts per day")
    + geom_smooth()

<img src="https://lh5.googleusercontent.com/-VbW0w7jazmI/UM7F9Vb5e2I/AAAAAAAAAJw/WD61ZIeb6jY/s500/daily-alert-count.png">

We can clearly see the trend in non-notifying failures. It could be anything
from machines not getting package updates (something for which I don’t want to
be waken up in the middle of the night) to checks that have been disabled (i.e.
technical debt).

Now focusing on notifying alerts (in that greenish tint), I can easy get a read
of the situation as the year progresses. Here is the graph with just the
notifying alerts.

<img src="https://lh5.googleusercontent.com/-9NwkRQS7PS0/UM7F9WxhrnI/AAAAAAAAAJ4/MrW-FkOaH3I/s500/daily-count-notifying.png">

There was obviously a big spike 3-4 months into 2012 but overall things are
stabilizing. I may still consider that the number of notifications is too high
but I know at least where I’m starting from.

## A Case of the Fridays

Is there a worst day to be on-call? That’s another easy one to answer once the
data is properly extracted. Fridays are not the best day to go to the
movies, while Tuesdays see a lot of variability (is it because we release more
code on Tuesdays?)

    ggplot(dd_by_hod, aes(occurrence_dow, daily, group=occurrence_dow))
    + geom_boxplot()
    + scale_x_discrete(breaks=seq(0, 6),
                       labels=c("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"))
    + xlab("Day of the week")
    + ylab("Number of alerts")
    + ggtitle("Daily distribution")

<img src="https://lh3.googleusercontent.com/-KzWVFUBn_ys/UM7F-K7IlJI/AAAAAAAAAKE/uVyaYHZGosU/s400/notifying-by-dow.png">

## The More (Data) The Merrier

Once you start digging, it’s damn hard to stop. The company I work
for consumes and analyzes this kind of data for a living, so it was tempting to
run a few queries against a larger data set of independent Nagios streams to
ask more questions, to name a (tiny) few:

* Does the size of the infrastructure have an effect on the ratio between
  notifying and silent alerts? Little, the ratio remains between 1 and 3%.
* Does the size of the infrastructure have an effect on the distribution of
  alerts across hosts? Surprisingly little, the distribution is close to a
  power law. Regardless of the size, a few number of hosts will concentrate
  most of the alerts.

## Lessons Learned

Having spent a number of hours looking into Nagios streams I walked away with a
few conclusions.

First, presentation matters. The data is there. With a bit of love, we can make
data more usable. The real leap comes with turning them into
digestible-at-a-glance bits. Tools like ggplot2 and d3.js are your friends.

Second, it’s easy to visualize trends. Visuals are a great conversation
starter, and having hard data anchors the conversation. The harder part
is to explain and ultimately control the trends. At least our brains are freed
from looking at tedious logs!

Finally, it’s a lot of fun. Tools like R, pandas, d3.js, matplotlib, to name a
few, make this kind of exercise a great weekend project. It won’t necessarily
scale (otherwise I’d be out of a job), but you’ll come out with a fresh
perspective on your monitoring chatter.

## Further Reading

* [matplotlib gallery](http://matplotlib.org/gallery.html)
* [d3.js gallery](https://github.com/mbostock/d3/wiki/Gallery)
* [R gallery](http://gallery.r-enthusiasts.com/)
