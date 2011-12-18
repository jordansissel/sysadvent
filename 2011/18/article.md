# Why are we doing this?

Imagine your whole professional career as a sysadmin and you never understood
the OSI model. Those seven simple layers that allow you to build an effective
internal framework of network communications. Without this model how would you
even begin to understand larger and more complex systems or the complex
interactions between multiple systems?

You might get by for a time; hard work and dedication can take you a long way.
But you would never be able to progress beyond a certain point. The problem
space becomes to complex to brute force.

Now imagine that successfully managing and running a business is at least as
complex as managing a network. Managing a 1000 computers is much easier than
managing a business of 1000 people. I'd like to take you into the shallow end
of business management and show you how the services that we sysadmins maintain
are viewed from a business perspective.

Fortunately this framework is simple and avoids any hand waving. We just need
this three word phrase, "differentiation and neutralization."

Differentiation builds services that create competitive advantage.
Neutralization builds services that seek to maintain competitive equilibrium.
This interplay is the heart of what drives business and directs the supporting
activities of enterprise level IT.  Working DNS is needed for almost all
aspects of modern enterprise IT infrastructure, and it will serve as a
technical example for this discussion.

Building services that neutralize competitive advantage usually involves buying
solutions; these are often disguised as "industry best practices", and have
many accompanying white papers offered as proof. More often than not this niche
is filled by Microsoft or other large software vendors. You can buy your way
out of a problem.

When building a DNS service it is most often thought of as a way to neutralize
the advantage of other organizations. Seldom is thought given to how an
organization might run DNS 30% "better" (not necessarily faster or any
particular quality) than its competitors. In most cases, "better" would not
matter at all.

"Better" does not create an advantage with a neutralizing service. Instead, it
in fact creates a disadvantage. Time, attention, and resources are being
funneled into a project that creates no value from a business standpoint. The
business does not (and should not) care about innovating in services that they
consider neutralizing.*

Building services that create competitive differentiation is much different
than neutralization as most of these services are built rather than bought.
These tend to be very custom to the environment. The prime consideration for
these services is adaptability. You must be able to extend the software
providing the service as this allows you to out maneuver your competition. You
are able to think your way out of a problem.

## Turning Neutralizing into Differentiating

OpenDNS took a service that was neutralizing and rebuilt it from the ground up
and adding many other services such as anti-phishing, content filtering (based on
domain), and reporting. These services created a differentiation in their
business model and offered something new to the market. OpenDNS created a
reason to build "better" DNS services, as this is their core business model and
their competitive advantage.

As it turns out, setting security and content filtering at the DNS level works
equally well across all devices all the time and requires no client
installation. Now other businesses must appear to neutralize the differential
advantage by creating their own services to match. Norton, for example, has
followed suit with their Norton Everywhere product offering DNS services that
largely mirror OpenDNS.**

OpenDNS must now continue to differentiate their services from their
competitors. OpenDNS recently started offering DNSCrypt, which creates an
encrypted channel for DNS queries between the client and the DNS server.
Consider it to be SSL for DNS. No doubt, there will be other service providers
that follow suit, creating their own DNSCrypt implementations.***

Why do businesses seemingly chase the tail of their competiors? This is
because if organization declines the opportunity to neutralize the advantage of
their competition, they will be excluded from further innovation in this field
and may be locked out of the market entirely. A technical term for this is a
"feature". As the differentiation of services increases, the cost to enter the
market (the table stakes) increases accordingly. 

Senior sysadmins and engineers need to not only understand how to build a
service, we must understand why we are building it and what the business
requires from this deployment. Understanding the complete picture, we will
understand what technology is required, how it needs to be implemented, and how
much effort we should put into a project.

Both the engineer and the business get something valuable from this
understanding - keeping time and attention focused on important projects. The
next time you are asked to deploy a new service ask yourself (and your
management) one simple question:

"Is this a service that neutralizes or differentiates?"

* Why do you think sharepoint is so popular? It's not because it does
  everything well ...

** In the light of Windows 8 coming preloaded with Anti-Virus
   software, Norton is facing an almost complete lockout of their
   traditional market.

*** The great thing about standards, there are so many to choose from.
