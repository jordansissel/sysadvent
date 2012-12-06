# Watching out for Vendor Lock-In

This was written by [Matt Simmons](https://twitter.com/standaloneSA) ([blog](http://www.standalone-sysadmin.com/blog/))

Welcome to the dystopia your parents warned you about.

Vendor lock-in used to mean that your data was stuck in a proprietary
format, requiring you to buy expensive services to migrate to another
provider. With [[PS]aaS](http://en.wikipedia.org/wiki/Software_as_a_service), it
means that your [entire company can
disappear](http://www.nbcnews.com/technology/technolog/amazon-web-services-outage-takes-down-netflix-other-sites-1C6611522)
in a puff of smoke if you weren't careful about your choices. 

Lets figure out how to avoid that outcome.

System Administrators are a combination of maintenance staff, standing
army, and [consigliere](http://en.wikipedia.org/wiki/Consigliere). Not only do
we keep things running smoothly, we guard against invaders, and we act as
trusted advisors to the people who make corporate policies. It's unavoidable
that at some point we will need to advise our organizations to rely on outside
sources for IT services, and when we do that, the onus is on us for ensuring
our company's data can out-survive the service provider we choose.

Here are some rules to take into consideration when choosing a provider:

##  No Roach Motel

There can never be the scenario where data checks in, but it doesn't
check out. Data needs to be able to be programmatically extracted from
the remote service. If raw data dumps aren't available, make sure that
there's an API that can be utilized which provides a way to access all
of the data that you entered, including any important metadata.

For example, I had a load balancer (actually several, because who just buys one
load balancer?) that worked perfectly well. It had all kinds of interfaces to
allow me to do everything I needed. I enjoyed using it because it was
especially helpful with regard to generating Certificate Signing Requests
(CSRs) and doing certificate management. The downside was that if you used the
key that it generated to sign the CSRs, you couldn't actually *export* the key.
It's not like it advertised that fact - it just didn't give you the option to
do it.  The "certificate backup and recovery" process used encrypted tarballs,
and you could import into another of the company's load balancers, but you
couldn't do anything else with the certificate. Talk about annoying...

## Authentication, Access Control, and Accounting

You use centralized authentication to maintain your users. Use a cloud
service that will allow you to automate Moves, Adds, and Changes
(MACs) of accounts on their end. Also, ensure that the service uses
sufficiently-finely-grained control to company resources, and ensure
that when people make changes, those changes are recorded. Too many
cloud providers don't offer field-level logging of data, and when a
user changes a field maliciously or by accident, it can be difficult
or impossible to investigate using their tools.

Do you like running email servers? Me neither. Between spam, defense
from blacklisting, and half a dozen other irritants, plus the fact
that our existing software of choice couldn't do the advanced
calendaring that our users wanted to use led to us considering the
possibility of building an Exchange infrastructure. After fully
considering things, we determined that a combination of the fact that
we were a primarily-Linux shop plus the license fees of building an
Exchange infrastructure meant that we would be better off to outsource
our email services. Because user complaints had risen to a clamor by
that time, we assented to their demands and went with an affordable
Exchange provider.

Unfortunately, we didn't warrant enough users to have our own
dedicated server, so we were stuck in a shared environment. That also
led to us having to administer our users through a broken, under-featured,
over-complex web interface that had little or nothing to do
with the underlying Exchange server. Plus, the company didn't support
importing Active Directory users and groups, nor was there an API that
would allow us to "pretend". It was a miserable experience for
everyone involved.

## Be Aware of Provider Limitations

Don't rely on a service provider with a lesser infrastructure than your own. A
chain's only as strong as its weakest link. You use multiple AWS regions. Or
maybe multiple data sites. But a bad choice of a SaaS provider can ruin all of
your carefully laid plans. Investigate and decide accordingly.

You know exactly how much work and effort you spent on developing a
solid, stable infrastructure. You know that you have disaster recovery
plans, and that you test your fail saves and fail overs. You *don't
know* about the SaaS provider's infrastructure until you ask. One of
the first things I did with companies I was evaluating for hosted
services was have an in-depth discussion with an engineer from their
side who could talk with me about things like infrastructure and
service uptime, SLAs, and so on.

Essentially, I interviewed the companies like I interviewed potential
employees, because there are a lot of similarities. Both are working
for you, both can screw up and cost you uptime, and firing both is
harder than you'd like it to be. On the other hand, the right company
(and the right employee) can both make your life immeasurably easier,
too. Good service is rare, so when you find it, treasure it.

## Further Reading

* [Are you a responsible owner of your availability?](http://www.somic.org/2010/07/06/are-you-a-responsible-owner-of-your-availability/)
* [Own your availability](http://cwebber.ucr.edu/2011/08/own-your-availability/)
* [Examples of vendor lock-in](http://en.wikipedia.org/wiki/Vendor_lock-in)
