# Day 2 - Strategies for Java Deployment

This article was written by [Kris Buytaert](https://twitter.com/krisbuytaert)
([www.krisbuytaert.be/blog](http://www.krisbuytaert.be/blog/)).

After years of working in Java-based environments, there are a number of
things that I like to implement together with the teams I\`m working
with - the application doesn't matter much, whether it's plain java, Tomcat,
JBoss, etc, these deployment strategies will help your ops and dev teams
build more managable services.

## Packaging

The first step is to have the native operating system packages as build
artifacts rolling out of your [continuous
integration](http://martinfowler.com/articles/continuousIntegration.html)
server - No .ear, .war or .jar files: I want to have rpms or debs. With things
like [fpm](https://github.com/jordansissel/fpm#readme) or the [maven
rpm](http://mojo.codehaus.org/rpm-maven-plugin/) plugin this should not be an
extra hassle, and the advantages you get from doing this are priceless. 

What advantages? Most native package systems support dependency resolution,
file verification, and upgrades (or downgrades). These are things you would
have to implement yourself or cobble together from multiple tools. As a bonus,
your fellow sysadmins are likely already comfortable with the native package
tool used on your systems, so why not do it?

## Proxied, not running as root

_Shaken, not stirred_

Just like any other daemon, for security reasons, I prefer to run
run Tomcat or JBoss as its own user, rather than as root. In most cases,
however, only root can bind to ports below 1024, so you need to put a proxy
in front. This is a convenient requirement because proxying (with something
like Apache) can be used to terminate SSL connections, give improved logging
(access logs, etc), and provides the ability to run multiple java
application server instances on the same infrastructure.

## Service Management

Lots of Java application servers have a semi functional shell script that
allows you to start the service. Often, these services don't daemonize in a
clean way, so that's why I prefer to use the [Java Service
wrapper](http://wrapper.tanukisoftware.com/doc/english/download.jsp) from
Tanuki to manage most Java based services. With a small config file, you get a
clean way to stop and start java as a service and even the possibility to add
some more monitoring to it.

However, there are some problems the Java Service wrapper leaves unsolved.
For example, after launching the service, the wrapper can return back with a
successful exit code while your service is not ready yet. The application
server might be ready, but your applications themselves are still starting up.
If you are monitoring these applications (e.g for High Availability), you
really only want to treat them as 'active' when the application is ready, so
you don't want your wrapper script to return, "OK," before the application has
been deployed and ready. Otherwise, you end up with false positives or
nodes that failover before the application has ever started. It's pretty easy
to create a ping-pong service flapping scenario on a cluster this way.

## One application per host

I prefer to deploy one application per host even though you can easily
deploy multiple applications within a single Java VM. With one-per-host,
management becomes much easier. Given the availability and popularity of
good virtualization, the overhead of launching multiple Linux VM's for
different applications is so low that there are more benefits than
disadvantages.

## Configuration

What about configuration of the application? Where should remote API urls,
database settings, and other tunables go?  A good approach is to create a
standard location for all your applications, like `/etc/$vendor/app/`, where you
place the appropriate configuration files. Volatile application configuration
must be outside the artifact that comes out the build (.ear , .jar, .war,
.rpm). The content of these files should be managed by a configuration
management tool such as puppet, chef, or cfengine. The developers should be
given a basic training so they can provide the systems team with the
appropriate configuration templates.

# Logs

Logs are pretty important too, and very easy to neglect.  There are plenty of
alternative tools around to log from a Java application: Log4j, Logback, etc ..
Use them and make sure that they are configured to log to syslog, then they
can be collected centrally and parsed by tools much easier than if they were
spread all over the filesystem.

# Monitoring

You also want your application to have some ways to monitor it besides
just checking if it is running - it is usually insufficient to simply check if
a tcp server is listening. A nice solution is to have a simple plain text page
with a list of critical services and whether they are OK or not (true/false),
for example:

~~~~ {.PROGRAMLISTING}
someService: true
otherService: false
~~~~

This benefits humans as well as machines. Tools like
[mon](https://mon.wiki.kernel.org/),
[heartbeat](http://linux-ha.org/wiki/Heartbeat) or loadbalancers can just grep
for "false" in the file. If the file contains false, it reports a failure and fails
over. This page should live on a standard location for all your applications,
maybe a pattern like this
http://$host/$servicename/health.html and an example
"http://10.0.129.10:8080/mrs-controller/health.html". The page should be
accessible as soon as the app is deployed. 

This true/false health report should not be a static HTML file; it should be a
dynamically generated page. Text means that you can also use curl, wget, or any
command-line tool or browser to check the status of your service.

The 'health.html' page should report honestly about health, executing any code
necessary to compute 'health' before yielding a result. For example, if your
app is a simple calculator, it should verify health by doing tests internally like
adding up some numbers before sharing 'myCalculator:true' in the health report.

The 'health.html' page should report honestly about health, executing any code
necessary to compute 'health' before yielding a result. For example, if your 
app is a simple calculator, then before reporting health it should put two and
two together and get four.

This kind of approach could also be used to provide you with metrics you
can't learn from the JVM, such as number of concurrent users or other
valid application metadata for measurement and trending purposes.

## Conclusion

If you can't convince your developers, then maybe more data can help: Check out
Martin Jackson's (presentation on java
deployments)[http://www.slideshare.net/actionjackx/automated-java-deployments-with-rpm]

With good strategies in packaging, deployment, logging, and monitoring, you are
in a good position to have an easily manageable, reproducible, and scalable
environment. You'll give your developers the opportunity to focus on writing
the application, they can use the same setup on
their local development boxes (e.g. by using vagrant) as you are using on
production.

By the way, I will be giving a talk titled [DevOps: The past and future are
here. It's just not evenly distributed
(yet)](http://www.usenix.org/events/lisa11/tech/tech.html#Buytaert). at this
year's LISA in Boston!

## Further Reading

* [Jenkins CI Server](http://jenkins-ci.org/)
* [Simple configuration files in Java with Properties](http://docs.oracle.com/javase/6/docs/api/java/util/Properties.html)
