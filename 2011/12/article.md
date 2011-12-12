# Day 12 - Reverse-engineer servers with Blueprint

This was written by [Richard Crowley](https://twitter.com/rcrowley)
([rcrowley.org](http://rcrowley.org/))

The benefits of using a configuration management tool can be felt by even the
smallest of teams, yet most still rely on wiki pages and handwritten shell
scripts to keep things straight because the barriers to entry in traditional
configuration management tools are too high, both mentally and technically. 

You could be comfortable with how to configure a server by hand, but you don't
know how to use the right tools to automate that configuration.
[We](http://devstructure.com/) set out to build a configuration management tool
that addresses common problems in an approachable way.

[Blueprint](https://github.com/devstructure/blueprint) is a simple
configuration management tool that reverse-engineers servers.  It figures out
what you've done manually, stores it locally in a Git repository, generates
code that's able to recreate your efforts, and helps you deploy those changes
to production.

Once you get it
[installed](http://devstructure.github.com/blueprint/#installation), creating
a blueprint takes but a single command:

    blueprint create example

where 'example' is the name of your blueprint.  Blueprint will list packages
managed by APT, Yum, RubyGems, Python's `easy_install` and `pip`, PHP's PEAR
and PECL, and Node.js' NPM.  It will also determine which configuration files
in `/etc` have been added or modified from their packaged versions and also
collect files in `/usr/local` that are part of any software packages installed
from source.  Finally, it will build a list of conditions under which System V
init or Upstart services should be restarted, including package upgrades and
configuration changes.

Blueprints are stored in a local Git repository as JSON and tarballs and from
there you can turn them into shell scripts, Puppet modules, or Chef cookbooks.

Generate a shell script rendering of this blueprint as `example/bootstrap.sh`:

    blueprint show -S example

Generate a puppet module named 'example'; the main manifest will be
`example/manifests/init.pp`:

    blueprint show -P example

Generate a bit of chef with the recipe as `example/recipes/default.rb`:

    blueprint show -C example

The generated shell scripts can render
[`mustache.sh`](https://github.com/rcrowley/mustache.sh) templates to tailor
configuration to the hardware: `{{CORES}}` for the number of CPU cores in the
system, `{{MEM}}` for total memory, `{{FQDN}}` for the fully-qualified domain
name, and more.  See
[`blueprint-template(7)`](http://devstructure.github.com/blueprint/blueprint-template.7.html)
for the complete list and
[`blueprint-template`(1)](http://devstructure.github.com/blueprint/blueprint-template.1.html)
to learn how to add your own template data.

There will undoubtedly come a time when you want to use a bit more finesse in
configuration management than Blueprint's automatic reverse-engineering can
provide, even with hints in `/etc/blueprintignore`.  For that time, there are
rules files that enumerate only the resources you want included in the
blueprint.  Take, for example, `example.blueprint-rules` describing a tiny
Sinatra application:

    :source:/usr/local

    /etc/init/example.conf
    /etc/nginx/sites-*/example
    /etc/unicorn.conf.rb

    :package:apt/libmysqlclient-dev
    :package:apt/mysql-client-5.1
    :package:apt/nginx-common
    :package:apt/nginx-light
    :package:apt/ruby-dev
    :package:apt/rubygems
    :package:rubygems/*

    :service:sysvinit/nginx
    :service:upstart/example

Regardless of what else is installed on the system, _example_ will only contain
these resources:

    blueprint rules example.blueprint-rules

Blueprint still extracts file content and metadata, package versions, and
service dependencies from the system but instead of including everything and
the kitchen sink, stays focused only on the resources you declare.

There's much more detail in the newly-revamped
[documentation](http://devstructure.github.com/blueprint/) and copious [man
pages](http://devstructure.github.com/blueprint/#man).  Give Blueprint a spin
and send questions to <blueprint-users@googlegroups.com>.

## Further Reading

* Blueprint can generate [puppet](http://docs.puppetlabs.com/) modules and
  [chef](http://www.opscode.com/chef/) recipes and could be your gateway drug
  into learning more automation tools.
* [Vagrant](http://vagrantup.com/) could be used to help you automate testing
  of your blueprints.
