# Day 4 - A Guide to Packaging Systems

This was written by [Jordan Sissel](http://twitter.com/jordansissel)
([semicomplete.com](http://semicomplete.com)).

Software packaging systems are a strange phenomenon. They all seem to aim at
solving the general problem of shipping some named, versioned collection of
files to the world. Yet, this common ground seems insufficient given the
overwhelming number of incompatible packaging systems in the wild.

The "overwhelming" part of above is what we need to talk about. Specifically,
despite having similar goals, one package system is rather unlikely to have
anything in common with another. Different terminologies, different tools,
different technologies, different distribution mechanisms, different policies.
The side effect with this phenomenon of "similar goal, nothing meaningful in
common" is that you get punished.

Know how to use Red Hat's package system? Knowledge of rpm and its world
doesn't help you much with the Solaris packaging system. Each solves roughly
the same problem but with fundamentally different tools, techniques, policies, and
terminology. Even package tools with historical ties like Gentoo Portage and
FreeBSD Ports have strong divergence in technology, policies, and distribution.

I've had enough frustration over the years in dealing with learning new packaging
systems, so today's post aims to give you a general guide to this strange
world of packaging. As a caveat, the information detailed here is to the best
of my knowledge and assisted with some googling. For the sake of brevity, I'm
going to leave out (for now) language or non-OS platform packaging systems like
Ruby's rubygems, Python's eggs, etc.

## Terminology

Terminology first, because knowing the right terms will help you find answers
in search engines faster.

* Tool terms:
  * Red Hat: rpm, rpmbuild, spec file, yum
  * Debian: dpkg, debuild, control file, dh_make, apt-get
  * FreeBSD: ports, make, pkg_add
  * Solaris: pkg, pkgadd, pkgmk, pkgtrans
* Versioning terms:
  * Red Hat: epoch, version, release
  * Debian: version
  * FreeBSD: epoch, version, revision
  * Solaris: version
* Relationship terms:
  * Red Hat: requires, obsoletes, provides
  * Debian: depends, conflicts, provides, replaces
  * FreeBSD: depends, requires
  * Solaris: _nothing as far as I can tell_
* Scripted action terms:
  * Red Hat: %pre, %post, %preun, %postun
  * Debian: preinst, postinst, prerm, postrm
  * FreeBSD: pkg-install, pkg-deinstall, pkg-req
  * Solaris: preinstall, postinstall, checkinstall
* Support or repo tools
  * Red Hat: mrepo, createrepo
  * Debian: apt-ftparchive, reprepro, apt-file
  * FreeBSD: portmaster, portupgrade, portsnap,
  * Solaris: pkgbuild

As you can see, some things have very similar terms, some do not. FreeBSD calls
'pkg-req' what Solaris calls 'checkinstall' but Red Hat and Debian lack this
specific feature (though it can be implemented in pre-installation scripts).
Red Hat and FreeBSD agree on 'epoch' in meaning but use 'release' and
'revision' to refer to the same feature.

In Solaris, to do dependency checking, you are supposed to do this in a [script
named
'checkinstall'](http://www.ibiblio.org/pub/packages/solaris/sparc/html/creating.solaris.packages.html)
and bail out if the dependencies are not installed.

## Distributing Packages

Many package systems support network installation and dependency resolution. It
is these two features that makes 'yum install foo' fetch and install all
dependencies of 'foo,' possibly aborting due to dependency conflicts, version
mismatches, or other relationship problems.

A common practice here is to mirror packages locally in your infrastructure.
This enables you to survive upstream failures (like package corruption,
outages, etc). Tools like mrepo (for rpm) and rsync will help you here as most
package repositories support rsync.

## Building Packages

Have you ever needed a piece of software (or specific version) not available in
your upstream package repository?  You don't want to be at the mercy and whims
of upstream. Your own software policies and needs are likely to be different
(and even in conflict) with Debian or Ubuntu's packaging policies and culture.

Given this likely mismatch in your needs and upstream's available software, it
is worth your time learning how to build packages and how to host them internally
in your own package repository.

Learning to build packages can be a frustrating experience and, at least for
me, has resulted in many [shaved
yaks](http://en.wiktionary.org/wiki/yak_shaving) and [lost
hours](http://xkcd.com/349/), but there are resources available to help you
out: 

* [Maximum RPM](http://www.rpm.org/max-rpm/)
* [Debian New Maintainer's Guide](http://www.debian.org/doc/manuals/maint-guide/)
* [FreeBSD Porter's Handbook](http://www.freebsd.org/doc/en_US.ISO8859-1/books/porters-handbook/)
* [Creating Solaris Packages](http://www.ibiblio.org/pub/packages/solaris/sparc/html/creating.solaris.packages.html)

## Converting Packages

Using multiple package systems on the same platform can make for a confusing
array of moving parts. For example, using both rpms and rubygems. The confusion
stems largely from the huge differences already described - it's yet another
learning curve you must ascend. What if you converted those rubygems packages
you needed to rpms? Your team and your tools could then manage ruby libraries
the same way as the rest of your software, and that sounds promising.

This idea of converting package types is not new. The common ground between
package systems is common enough that there's often a tool available to help
translating one package type to another.

What package translating tools are there?

* FreeBSD has 'BSDPAN' for automatically registering perl modules installed
  with CPAN in the FreeBSD package system. This allows you to uninstall them
  later with standard FreeBSD tools.
* Python setuptools (the 'setup.py' stuff) usually responds nicely to 'python setup.py bdist_rpm'
* Ruby has [gem2rpm](http://rubygems.org/gems/gem2rpm) will help you build rpms from gems
* Perl has [cpan2rpm]http://perl.arix.com/cpan2rpm/

It's pretty lame needing one tool for every conversion method you want to use.
Further, the conversion tools don't often help you build the packages; for
example, gem2rpm emits an 'rpm spec' which requires you know how to turn that
into an rpm.

All of this sums up to a burden of knowledge I think is silly.

## Build Packages Easier

There are easier ways to build packages. Two projects, in particular, aim to solve exactly the 'how to I build a package of this thing?' question.

First, there is [CheckInstall](http://asic-linux.com.mx/~izto/checkinstall/)
(which bears no relation to the Solaris packaging term). This project tries
to make package creation a side effect of the normal "make install" task,
certainly a nice touch if you are looking to keep you software building
workflow the same.

Second, there is [fpm](https://github.com/jordansissel/fpm#readme). The goal of fpm
(caveat: I am the author) is to make a common tool for building packages
from any source to any target. For example, you can turn a directory into an
rpm, or a rubygem into a deb - both tasks can be done with very little
knowledge of how each source (rubygem, directory) or target (deb, rpm) work.

At this time, fpm can create Solaris, rpm, and deb packages. To show you the
simplicity, the following command lines will create a package of the 'boto' AWS
library for Python:

    % fpm -s python -t rpm boto
    % fpm -s python -t solaris boto

    # Example with 'deb' target:
    % fpm -s python -t deb boto
    Trying to download boto (using: easy_install)
    ...
    Downloading http://pypi.python.org/packages/source/b/boto/boto-2.1.1.tar.gz
    ...
    Created /tmp/z/python-boto_2.1.1_all.deb

Now you have a native deb, rpm, and solaris package of the python boto library
and you never had to learn how to build packages on each of those platforms.

## Conclusion

For any given platform I am operating, I've always had to learn the native
packaging system, build my own custom packages, and host my own package repo.
That's why I wrote fpm, after all, to [codify my knowledge and
skills](http://sysadvent.blogspot.com/2011/12/day-3-share-skills-and-permissions-with.html)
into a tool that I and others can reuse.

Hopefully this guide has shed some light on a confusing and frustrating area of
systems administration and given you the tools and terms to wield whatever
packaging systems you are using.

## Further Reading

* [rpmforge](http://dag.wieers.com/rpm/) - A 3rd party rpm repository that
  might save you from having to roll your own packages on Red Hat and related
  platforms.
* [EPEL](http://fedoraproject.org/wiki/EPEL) - A similar project to rpmforge but helps
  bridge packages from Fedora into distributions like CentOS and Scientific Linux.
* [pkgsrc](http://www.netbsd.org/docs/software/packages.html) - The NetBSD
  pkgsrc system is supported on many different platforms including Solaris and Linux.
* [Gentoo Prefix](http://www.gentoo.org/proj/en/gentoo-alt/prefix/) - The
  Gentoo Portage system but supported on other platforms (similar in idea to pkgsrc).
