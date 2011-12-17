# Day 16 - Shipping Some Logs

This was written by [Jordan Sissel](http://twitter.com/jordansissel)
([semicomplete.com](http://semicomplete.com)).

Logging is messy. Ever have logs fill up your disk and crash services as a
result? Me too, and that sucks.

You can solve the disk-filling problem by rotation logs and expiring old ones,
but there's a better solution that solves more problems: ship your logs
somewhere else. Shipping logs somewhere centralized helps you more quickly
access those logs later when you need to debug or do analytics.

There are plenty of tools in this area to help you solve log transport
problems. Common syslog servers like [rsyslog](http://rsyslog.com/) and
[syslog-ng](http://www.balabit.com/network-security/syslog-ng/opensource-logging-system/overview)
are useful if syslog is your preferred transport. Other tools like [Apache
Flume](https://cwiki.apache.org/FLUME/), [Facebook's
Scribe](https://github.com/facebook/scribe/wiki), and
[logstash](http://logstash.net) provide an infrastructure for reliable and
robust log transport. Many tools that help solve log transportation problems
also solve other problems, for example, rsyslog can do more than simply moving
a log event to another server.

## Starting with Log Files

For all of these systems, one pleasant feature is that in most cases, you don't
need to make any application-level changes to start shipping your logs
elsewhere: If you already log to files, these tools can read those files and
ship them out to your central log repository.

Files are a great common ground. Can you 'tail -F' to read your logs? Perfect.

Even rsyslog and syslog-ng, while generally a syslog server, can both follow
files and stream out logs as they are written to disk. In rsyslog, you use
the [`imfile` module](http://rsyslog.com/doc/imfile.html). In syslog-ng, you
use the [file()
driver](http://www.balabit.com/sites/default/files/documents/syslog-ng-v3.0-guide-admin-en.html/index.html-single.html#configuring_sources_file).
In Flume, you use the [`tail()
source`](http://archive.cloudera.com/cdh/3/flume/UserGuide/index.html#_tailing_a_file_name_literal_tail_literal_and_literal_multitail_literal).
In logstash, you use the [`file` input
plugin](http://logstash.net/docs/1.0.17/inputs/file).

## Filtering Logs

Most of the tools mentioned here support some kind of filtering, whether it's
dropping certain logs or modifying them in-flight.

[Logstash](http://logstash.net/), for example supports dropping events matched
by a certain pattern, parsing events into a structured piece of data like JSON,
normalizing timestamps, and figuring out what events are single-line and what
events are multi-line (like java stack traces). [Flume]() lets you do similar
filter behaviors in
[`decorators`](http://archive.cloudera.com/cdh/3/flume/UserGuide/#_custom_metadata_extraction)

In rsyslog, you can use [filter
conditions](http://rsyslog.com/doc/rsyslog_conf_filter.html) and
[templates](http://rsyslog.com/doc/rsyslog_conf_templates.html) to selectively
drop and modify events before they are output. Similarly, in syslog-ng,
[filters](http://www.balabit.com/sites/default/files/documents/syslog-ng-v3.0-guide-admin-en.html/index.html-single.html#filters)
let you drop events and
[templates](http://www.balabit.com/sites/default/files/documents/syslog-ng-v3.0-guide-admin-en.html/index.html-single.html#configuring_macros)
let you reshape the output event.

## Final Destination

Where are you putting logs?

You could put them on a large disk server for backups and archival, but logs
have valuable data in them and are worth mining.

Recall [Sysadvent Day
10](http://sysadvent.blogspot.com/2011/12/day-10-analyzing-logs-with-pig-and.html)
which covered how to analyze logs stored in S3 using Pig on Amazon EC2.
"Logs stored in S3" - how do you get your logs into S3? Flume supports S3 out
of the box allowing you to ship your logs up to Amazon for later processing.
Check out [this blog
post](http://eric.lubow.org/2011/system-administration/distributed-flume-setup-with-an-s3-sink/)
for an example of doing exactly this.

If you're looking for awesome log analytics and debugging, there are a few
tools out there to help you do that without strong learning curves.
Some open source tools include [Graylog2](http://graylog2.org/) and
[logstash](http://logstash.net/) are both popular and have active communities.
Hadoop's Hive and Pig can help, but may have slightly steeper learning curves.
If you're looking for a hosted log searching service, there's
[papertrail](https://papertrailapp.com/). Hosted options also vary in features
and scope; for example, [Airbrake](http://airbrake.io/pages/home) (previously
called 'hoptoad') focuses on helping you analyze logged errors.

## And then?

Companies like Splunk have figured out that there is money to be made from your
logs, and web advertising companies log everything because logs are money, so
don't just treat your logs like they're a painful artifact that can only be
managed with aggressive log rotation policies.

Centralize your logs somewhere and build some tools around them. You'll get
faster at debugging problems and be able to better answer business and
operations questions.

## Further Reading

* Log4j has a cool feature called
[MDC](http://logging.apache.org/log4j/1.2/apidocs/org/apache/log4j/MDC.html)
and
[NDC](http://logging.apache.org/log4j/1.2/apidocs/org/apache/log4j/NDC.html)
that lets you log more than just a text message.
* [logrotate](https://fedorahosted.org/logrotate/)
