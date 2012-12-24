# Day 24 - Twelve things you didn't know with Chef

This was written by [Joshua Timberman](https://twitter.com/jtimberman).

In this post, we will discuss a number of features that can be used in
managing systems with Chef, but may be overlooked by some users. We'll
also look at some features that are not so commonly used, and may
prove helpful.

Here's a table of contents:

1. [Resources are first class citizens](#item_1)
2. [In-place file editing](#item_2)
3. [File Checksum comparisons](#item_3)
4. [Version matching](#item_4)
5. [Encrypting Data for Chef's Use](#item_5)
6. [Chef has a REPL](#item_6)
7. [Working with the Resource Collection](#item_7)
8. [Extending the Recipe DSL with helpers](#item_8)
9. [Load and execute a single recipe](#item_9)
10. [Integrating Chef with Your Tools](#item_10)
11. [Sending information to various places](#item_11)
12. [Tagging nodes](#item_12)

<a name="item_1"></a>

# (1) Resources are first class citizens

This is probably something most readers who are familiar with Chef
already do know. However, we do encounter some uses of Chef that
indicate that the author didn't know this. For example, this is from an
**actual** recipe I have seen:

    execute "yum install foo" do
      not_if "rpm -qa | grep '^foo'"
    end

    execute "/etc/init.d/food start" do
      not_if "ps awux | grep /usr/sbin/food"
    end

This totally works, assuming that the grep doesn't turn up a false
positive (someone reading the 'food' man page?). However, there are
resources for this pattern kind of thing, so it's best to use them instead:

    package "foo" do
      action :install
    end

    service "food" do
      action :start
    end

## Core Chef Resources

Chef comes with a
[great many resources](http://docs.opscode.com/essentials_cookbook_resources_platform.html).
These are for managing common components of operating systems, but
also primitives that can be used to use on their own, or compose new
resources.

Some common resources:

- [package](http://docs.opscode.com/resource_package.html)
- [service](http://docs.opscode.com/resource_service.html)
- [user](http://docs.opscode.com/resource_user.html)
- [group](http://docs.opscode.com/resource_group.html)
- [file](http://docs.opscode.com/resource_file.html), [template](http://docs.opscode.com/resource_template.html), [remote\_file](http://docs.opscode.com/resource_remote_file.html), [cookbook\_file](http://docs.opscode.com/resource_cookbook_file.html)
- [execute](http://docs.opscode.com/resource_execute.html), [script](http://docs.opscode.com/resource_script.html), [ruby\_block](http://docs.opscode.com/resource_ruby_block.html)

These actually make up probably 80% or more of the resources people
will use. However, Chef comes with a few other resources that are less
commonly used but still highly useful.

- [scm, git, subversion](http://docs.opscode.com/resource_scm.html)
- [ohai](http://docs.opscode.com/resource_ohai.html)
- [http\_request](http://docs.opscode.com/resource_http_request.html)
- [erlang\_call](http://docs.opscode.com/resource_erlang_call.html)

The `scm` resource has two providers, `git` and `subversion`, which can be
used as the resource type. These are useful if a source repository
must be checked out. For example, myproject is in subversion, and your
project is in git.

    subversion "myproject" do
      repository "svn://code.example.com/repos/myproject/trunk"
      destination "/opt/share/myproject"
      revision "HEAD"
      action :checkout
    end

    git "yourproject" do
      repository "git://github.com/you/yourproject.git"
      destination "/usr/local/src/yourproject"
      reference "1.2.3" # some tag
      action :checkout
    end

This is used under the covers in the
[deploy](http://docs.opscode.com/resource_deploy.html) resource.

The `ohai` resource can be used to reload attributes on the node that
come from Ohai plugins.

For example, we can create a user, and then tell ohai to reload the
plugin that has all user and group information.

    ohai "reload_passwd" do
      action :nothing
      plugin "passwd"
    end

    user "daemonuser" do
      home "/dev/null"
      shell "/sbin/nologin"
      system true
      notifies :reload, "ohai[reload_passwd]", :immediately
    end

Or, we can drop off a new plugin as a template, and then load that
plugin.

    ohai "reload_nginx" do
      action :nothing
      plugin "nginx"
    end

    template "#{node['ohai']['plugin_path']}/nginx.rb" do
      source "plugins/nginx.rb.erb"
      owner "root"
      group "root"
      mode 00755
      notifies :reload, 'ohai[reload_nginx]', :immediately
    end

If your recipe(s) manipulate system state that future resources need
to be aware of, this can be quite helpful.

The `http_request` resource makes... an HTTP request. This can be used
to send (or receive) data via an API.

For example, we can send a request to retrieve some information:

    http_request "some_message" do
      url "http://api.example.com/check_in"
    end

But more usefully, we can send a POST request. For example, on a Chef
Server with CouchDB (Chef 10 and earlier), we can compact the
database:

    http_request "compact chef couchDB" do
      url "http://localhost:5984/chef/_compact"
      action :post
    end

If you're building a custom lightweight resource/provider for an API
service like a monitoring system, this could be a helpful primitive to
build upon.

## Opscode Cookbooks

Aside from the resources built into Chef, Opscode publishes a number
of cookbooks that contain custom resources, or "LWRPs". See the README
for these cookbooks for examples.

- [apt_repository](http://ckbk.it/apt) - manage APT repos
  (sources.list.d entries)
- [cron_d](http://ckbk.it/cron) - manage cron.d crontabs
- [sudo](http://ckbk.it/sudo) - add sudoers.d entries
- [yum_repository](http://ckbk.it/yum) - manage YUM repos

There's many more, and documentation for them is on the
[Opscode Chef docs site](http://docs.opscode.com/lwrp.html).

<a name="item_2"></a>

# (2) In-place file editing

For a number of reasons, people may need to manage the content of
files by replacing or adding specific lines. The common use case is
something like sysctl.conf, which may have different tuning
requirements from different applications on a single server.

### This is an anti-pattern

Many folks who practice configuration management see this as an
anti-pattern, and recommend managing the whole file instead. While
that is ideal, it may not make sense for everyone's environment.

### But if you really must...

The Chef source has a handy utility library to provide this
functionality,
[Chef::Util::FileEdit](http://rubydoc.info/gems/chef/10.16.2/Chef/Util/FileEdit).
This provides a number of methods that can be used to manipulate file
contents. These are used inside a `ruby_block` resource so that the
Ruby code is done during the "execution phase" of the
[Chef run](http://docs.opscode.com/essentials_nodes_chef_run.html).

    ruby_block "edit etc hosts" do
      block do
        rc = Chef::Util::FileEdit.new("/etc/hosts")
        rc.search_file_replace_line(
          /^127\.0\.0\.1 localhost$/,
          "127.0.0.1 #{new_fqdn} #{new_hostname} localhost"
        )
        rc.write_file
      end
    end

For another example, [Sean OMeara](http://twitter.com/someara) has
written a [line](http://ckbk.it/line) that includes a
resource/provider to append a line in a file if it doesn't exist.

<a name="item_3"></a>

# (3) File Checksum comparisons

In managing file content with the `file`, `template`, `cookbook_file`,
and `remote_file` resources, Chef compares the content using a
[SHA256 checksum](http://tickets.opscode.com/browse/CHEF-27). This
class can be used in your own Ruby programs or libraries too. Sure,
you can use the "sha256sum" command, but this is native Ruby instead
of shelling out.

The class to use is
[Chef::ChecksumCache](http://rubydoc.info/gems/chef/10.16.2/Chef/ChecksumCache)
and the method is `#checksum_for_file`.

    require 'chef/checksum_cache'
    sha256 = Chef::ChecksumCache.checksum_for_file("/path/to/file")

<a name="item_4"></a>

# (4) Version matching

It is quite common to need version string comparison checks in
recipes. Perhaps we want to match the version of the platform this
node is running on. Often we can simply use a numeric comparison
between floating point numbers or strings:

    if node['platform_version'].to_f == 10.04
    if node['platform_version'] == "6.3"

However, sometimes we have versions that use three points, and
matching on the third portion is relevant. This would get lost in
`#to_f`, and greater/less than comparisons may not match with strings.

### Chef::VersionConstraint

The
`[Chef::VersionConstraint](http://rubydoc.info/gems/chef/10.16.2/Chef/VersionConstraint)`
class can be used for version comparisons. It is modeled after the
[version constraints](http://docs.opscode.com/essentials_cookbook_versions_constraints.html)
in Chef cookbooks themselves.

First we initialize the `Chef::VersionConstraint` with an argument
containing the
[comparison operator](http://docs.opscode.com/essentials_cookbook_versions_operators.html)
and the version as a string. Then, we send the `#include?` method with
the version to compare as an argument. For example, we might be
checking that the version of OS X is 10.7 or higher (Lion).

    require 'chef/version_constraint'
    Chef::VersionConstraint.new(">= 10.7.0").include?("10.6.0") #=> false
    Chef::VersionConstraint.new(">= 10.7.0").include?("10.7.3") #=> true
    Chef::VersionConstraint.new(">= 10.7.0").include?("10.8.2") #=> true

Or, in a Chef recipe we can use the node's platform version attribute.
For example, on a CentOS 5.8 system:

    Chef::VersionConstraint.new("~> 6.0").include?(node['platform_version']) # false

But on a CentOS 6.3 system:

    Chef::VersionConstraint.new("~> 6.0").include?(node['platform_version']) # true

Chef's version number is stored as a node attribute
(node['chef_packages']['chef']['version']) that can be used in
recipes. Perhaps we want to check for a particular version because
we're going to use a feature in the recipe only available in newer
versions.

    version_checker = Chef::VersionConstraint.new(">= 0.10.10")
    mac_service_supported = version_checker.include?(node['chef_packages']['chef']['version'])

    if mac_service_supported
      # do mac service is supported so do these things
    end

<a name="item_5"></a>

# (5) Encrypting Data for Chef's Use

By default, the data stored on the Chef Server is not encrypted. Node
attributes, while containing useful data, are plaintext for anyone
that has a private key authorized to the Chef Server. However,
sometimes it is desirable to store encrypted data, and Data Bags
(stores of arbitrary JSON data) can be encrypted.

You'll need a secret key. This can be a phrase or a file. The key
needs to be available on any system that will need to decrypt the
data. A cryptographically strong secret key is best, and can be
generated with OpenSSL:

    openssl rand -base64 512 > ~/.chef/encrypted_data_bag_secret

Next, create the data bag that will contain encrypted items. For
example, I'll use `secrets`.

    knife data bag create secrets

Next, create the items in the bag that will be encrypted.

    knife data bag create secrets credentials --secret-file ~/.chef/encrypted_data_bag_secret
    {
      "id": "credentials",
      "user": "joshua",
      "password": "dirty_secrets"
    }

Then, view the content of the data bag item:

    knife data bag show secrets credentials
    id:        credentials
    password:  cKZgOISOE+lmRiqf9j5LlRegtcILqvVw6XRft11T7Pg=

    user:      mBf1UDwAGq0N0Ohqugabfg==

Naturally, this is encrypted using the secret file. Decrypt it:

    knife data bag show secrets credentials --secret-file ~/.chef/encrypted_data_bag_secret
    id:        credentials
    password:  dirty_secrets
    user:      joshua

To use this data in a recipe, the secret file must be copied and its
location configured in Chef. The `knife bootstrap` command can do this
automatically if your knife.rb contains the
`encrypted_data_bag_secret` configuration. Presuming that the .chef
directory contains the knife.rb and the above secret file:

    encrypted_data_bag_secret "./encrypted_data_bag_secret"

## In a Recipe, Chef::EncryptedDataBagItem

Nodes bootstrapped using the
[default bootstrap template](https://github.com/opscode/chef/blob/10-stable/chef/lib/chef/knife/bootstrap/chef-full.erb#L34-L39)
will have the secret key file copied to
`/etc/chef/encrypted_data_bag_secret`, and available for Chef. This is
a constant in the `Chef::EncryptedDataBagItem` class,
`DEFAULT_SECRET_FILE`. To use this in a recipe, use the `#load_secret`
method, then pass that as an argument to the `#load` method for the
data bag item. Finally, access various keys from the item like a Ruby
Hash. Example below:

    secret = Chef::EncryptedDataBagItem.load_secret(Chef::EncryptedDataBagItem::DEFAULT_SECRET_FILE))
    user_creds = Chef::EncryptedDataBagItem.load("secrets","credentials", secret)
    user_creds['id'] # => "credentials"
    user_creds['user'] # => "joshua"
    user_creds['password'] # => "dirty_secrets"

<a name="item_6"></a>

# (6) Chef has a REPL

Chef comes with a built-in "REPL" or shell, called `shef`. A REPL is
"Read, Eval, Print, Loop" or "read what I typed in, evaluate it, print
out the results, and do it again." Other examples of REPLs are
Python's `python` w/ no arguments, a Unix shell, or Ruby's `irb`.

### shef (chef-shell in Chef 11)

In Chef 10 and earlier, the Chef REPL is invoked as a binary named
`shef`. In Chef 11 and later, it is renamed to `chef-shell`.
Additional options can be passed to the command-line, including a
config file to use, or an over all mode to use (solo or
client/server). See `shef --help` for options.

Once invoked, `shef` has multiple run-time contexts that can be used:

- main
- recipe (recipe_mode in Chef 11)
- attributes (attributes_mode in Chef 11)

At any time, you can type "help" to get context specific help. The
"main" context provides a number of API helper methods. The
"attributes" context functions as a cookbook's attributes file. The
"recipe" context is in the Chef recipe DSL context, where resources
can be created and run. For example:

    chef:recipe > package "zsh" do
    chef:recipe >   action :install
    chef:recipe ?> end
     => <package[zsh] @name: "zsh" @package_name: "zsh" @resource_name: :package >

(the output is trimmed for brevity, try it on your own system)

This works similar to how Chef actually works when processing recipes.
It has recognized the input as a Chef Resource and added it to the
resource collection. This doesn't actually manage the resource until
we enter the execution phase, similar to a Chef run. We can do that
with the shef method `run_chef`:

    chef:recipe > run_chef
    [2012-12-23T12:32:27-07:00] INFO: Processing package[zsh] action install ((irb#1) line 1)
    [2012-12-23T12:32:27-07:00] DEBUG: package[zsh] checking package status for zsh
    zsh:
      Installed: 4.3.17-1ubuntu1
      Candidate: 4.3.17-1ubuntu1
      Version table:
     *** 4.3.17-1ubuntu1 0
            500 http://us.archive.ubuntu.com/ubuntu/ precise/main amd64 Packages
            100 /var/lib/dpkg/status
    [2012-12-23T12:32:27-07:00] DEBUG: package[zsh] current version is 4.3.17-1ubuntu1
    [2012-12-23T12:32:27-07:00] DEBUG: package[zsh] candidate version is 4.3.17-1ubuntu1
    [2012-12-23T12:32:27-07:00] DEBUG: package[zsh] is already installed - nothing to do
     => true

There are many possibilities for debugging and exploring with this
tool. For example, use it to test the examples that are presented in
this post.

### chef/shef/ext (renamed in Chef 11)

The methods available in the "main" context of Shef are also available
to your own scripts and plugins by requiring `Chef::Shef::Ext`. In
Chef 11, this will be `Chef::Shell::Ext`, though the old one is
present for compatibility.

    require 'chef/shef/ext'
    Shef::Extensions.extend_context_object(self)
    nodes.all # => [node[doppelbock], node[cask], node[ipa]]

<a name="item_7"></a>

# (7) Working with the Resource Collection

One of the features of Chef is that Recipes are pure Ruby. As such, we
can manipulate things that are in the Object Space, such as other Chef
objects. One of these is the Resource Collection, the data structure
that contains all the resources that have been seen as Chef processes
recipes. Using `shef`, or any Chef recipe, we can work with the
resource collection for a variety of reasons.

## Look Up Another Resource

The `#resources` method will return an array of all the resources.
From our `shef` session earlier, we have a single resource:

    chef:recipe > resources
    ["package[zsh]"]

We can add others.

    chef:recipe > service "food"
    chef:recipe > file "/tmp/food-zsh-completion"

Now when we look at the resource collection, we'll see the new
resources:

    chef:recipe > resources
    ["package[zsh]", "service[food]", "file[/tmp/food-zsh-completion]"]

We can use the resources method to open a specific resource.

## "Re-Open" Resources to Modify/Override

If we look at the `service[food]` resource that was created (using all
default parameters), we'll see:

    chef:recipe > resources("service[food]")
    <service[food] @name: "food" @noop: nil @before: nil @params: {} @provider: nil @allowed_actions: [:nothing, :enable, :disable, :start, :stop, :restart, :reload] @action: "nothing" @updated: false @updated_by_last_action: false @supports: {:restart=>false, :reload=>false, :status=>false} @ignore_failure: false @retries: 0 @retry_delay: 2 @source_line: "(irb#1):2:in `irb_binding'" @elapsed_time: 0 @resource_name: :service @service_name: "food" @enabled: nil @running: nil @parameters: nil @pattern: "food" @start_command: nil @stop_command: nil @status_command: nil @restart_command: nil @reload_command: nil @priority: nil @startup_type: :automatic @cookbook_name: nil @recipe_name: nil>

To work with this, it is easier to assign to a local variable.

    chef:recipe > f = resources("service[food]")

Then, we can call the various parameters as accessor methods.

    chef:recipe > f.supports
     => {:restart=>false, :reload=>false, :status=>false}

We can modify this by sending the `supports` method to `f` with
additional arguments. For example, maybe the `food` service supports
restart and status commands, but not reload:

    chef: recipe > f.supports({:restart => true, :status => true})
     => {:restart=>true, :status=>true}

As a more practical example, perhaps you want to use a cookbook from
the Chef Community Site that manages a couple services on Ubuntu. However, the
author of the cookbook hasn't updated the cookbook in a while, and
those services are managed by upstart instead of being init.d scripts.
You could create a custom cookbook that "wraps" the upstream cookbook
with a recipe like this to modify those service resources:

    if platform?("ubuntu")
      ["service_one, "service_two].each do |s|
        srv = resource("service[#{s}]")
        srv.provider Chef::Provider::Service::Upstart
        srv.start_command "/usr/bin/service #{s} start"
      end
    end

Then in the node's run list, you'd have the upstream cookbook's recipe
and your custom recipe:

    {
      "run_list": [
        "their_upstream",
        "your_custom"
      ]
    }

This is a pattern that has become popular with the idea of "Library"
vs. "Application" cookbooks, and Bryan Berry has a [RubyGem to provider
a helper for it](https://rubygems.org/gems/chef-rewind).

<a name="item_8"></a>

# (8) Extending the Recipe DSL with helpers

One of the features of a Chef cookbook is that it can contain a
"libraries" directory with files containing helper libraries. These
can be new Chef Resources/Providers, ways of interacting with third
party services, or simply extending the
[Chef Recipe DSL](http://docs.opscode.com/chef/dsl_recipe.html).

Let's just have a simple method that shortcuts the Chef version
attribute so we don't have to type the whole thing in our recipes.

First, create a cookbook named "my_helpers".

    knife cookbook create my_helpers

Then create the library file. This can be anything you want, all
library files are loaded by Chef.

    touch cookbooks/my_helpers/libraries/default.rb

Then, since we are extending the Chef Recipe DSL, add this method to its
class, `Chef::Recipe`.

    class Chef
      class Recipe
        def chef_version
          node['chef_packages']['chef']['version']
        end
      end
    end

To use this in a recipe, simply call that method. From the earlier example:

    mac_service_supported = version_checker.include?(chef_version)

Next, I'll use a helper library for the Encrypted Data Bag example from
earlier to demonstrate this. I created a separate library file.

    touch cookbooks/my_helpers/libraries/encrypted_data_bag_item.rb

It contains:

    class Chef
      class Recipe
        def encrypted_data_bag_item(bag, item, secret_file = Chef::EncryptedDataBagItem::DEFAULT_SECRET_FILE)
          DataBag.validate_name!(bag.to_s)
          DataBagItem.validate_id!(item)
          secret = EncryptedDataBagItem.load_secret(secret_file)
          EncryptedDataBagItem.load(bag, item, secret)
        rescue Exception
          Log.error("Failed to load data bag item: #{bag.inspect} #{item.inspect}")
          raise
        end
      end
    end

Now, when I want to use it in a recipe, I can:

    user_creds = encrypted_data_bag_item("secrets", "credentials)

<a name="item_9"></a>

# (9) Load and execute a single recipe

In default operation, Chef loads cookbooks and recipes from their
directories on disk. It is actually possible to load a single recipe
file by composing a new binary program from Chef's built-in classes.
This is helpful for simple use cases or as a general example. Dan
DeLeo of Opscode wrote this as a gist awhile back, which I've updated
here:

<https://gist.github.com//4366061>

It's only 45 lines counting whitespace. Simply save that to a file,
and then create a recipe file, and run it with the filename as an
argument.

    root@virt1test:~# wget https://gist.github.com/raw/4366061/68125dcf8767e1f5436e506c2d2a9697605d9802/chef-apply.rb
    --2012-12-23 13:56:32--  https://gist.github.com/raw/4366061/68125dcf8767e1f5436e506c2d2a9697605d9802/chef-apply.rb
    2012-12-23 13:56:32 (137 MB/s) - `chef-apply.rb' saved [848]

    root@virt1test:~# chmod +x chef-apply.rb
    root@virt1test:~# ./chef-apply.rb recipe.rb
    [2012-12-23T13:56:54-07:00] INFO: Run List is []
    [2012-12-23T13:56:54-07:00] INFO: Run List expands to []
    [2012-12-23T13:56:54-07:00] INFO: Processing package[zsh] action install ((chef-apply cookbook)::(chef-apply recipe) line 1)
    [2012-12-23T13:56:54-07:00] INFO: Processing package[vim] action install ((chef-apply cookbook)::(chef-apply recipe) line 2)
    [2012-12-23T13:56:54-07:00] INFO: Processing file[/tmp/stuff] action create ((chef-apply cookbook)::(chef-apply recipe) line 3)

This is the simple recipe:

    package "zsh"
    package "vim"

    file "/tmp/stuff" do
      content "I have some stuff I'm stashing in here."
    end

This functionality is quite useful for example purposes, and a
[ticket (CHEF-3571)](http://tickets.opscode.com/browse/CHEF-3571) was
created to track its addition for core Chef.

<a name="item_10"></a>

# (10) Integrating Chef with Your Tools

There's a rising ecosystem of tools surrounding chef. Many of them use the Chef
REST API to expose cool functionality and let you build your own tooling on
top.

## spice and ridley (ruby)

[spice](https://github.com/danryan/spice) and
[ridley](https://github.com/reset/ridley) provide ruby APIs that talk to Chef.

## jclouds (java/clojure

[jclouds](http://www.jclouds.org/documentation/gettingstarted/what-is-jclouds/)
has a chef component to let you use the Chef REST api from [Java and
Clojure](https://github.com/jclouds/jclouds-chef). Learn more
[here](https://github.com/jclouds/jclouds-chef/wiki/Quick-Start)

<a name="item_11"></a>

# (11) Sending information to various places

Chef has the ability to send output to a variety of places. By
default, it will output to standard out. This is managed through the
Chef logger, a class called `Chef::Log`.

## The Chef::Log Configuration

The `Chef::Log` logger has three main configuration options:

- `log_level`: the amount of log output to display. Default is "info",
  but "debug" is common.
- `log_location`: where the log output should go. Default is standard
  out.
- `verbose_logging`: whether to display "Processing:" messages for
  each resource Chef processes. Default is true.

The first two are configurable with command-line options, or in the
configuration file. The level is the `-l` (small ell) option, and the
location is the `-L` (big ell) option.

    chef-client -l debug -L debug-output.log

In the configuration file, the level should be specified as a symbol
(preceding colon), and the location as a string or constant (if using
standard out).

    log_level :info
    log_location STDOUT

Or:

    log_level :debug
    log_location "/var/log/chef/debug-output.log"

The verbose output option is in the configuration file. To suppress
"Processing" lines, set it to false.

    verbose_logging false

## Output Formatters

A new feature for log output introduced in Chef 10.14 is "Output
Formatters". These can be set with the `-F` option, or the `formatter`
configuration option. There are some formatters included in Chef:

- base: the default
- doc: nicely presented "documentation" type output
- min: rspec style minimal output

For example, to use the `doc` style but only for one run:

    chef-client -F doc -l fatal

Use the log level fatal so normal logger messages aren't displayed. To
make this permenant for all runs, put it in the config file.

    log_level :fatal
    formatter "doc"

You can create your own formatters, too. An example of this is Andrea
Campi's
[nyan cat](https://github.com/andreacampi/nyan-cat-chef-formatter)
formatter. You can deploy this and use it with Sean OMeara's
[cookbook](http://ckbk.it/nyan-cat).

## Report/Exception Handlers

Chef has an API for running
[report/exception handlers](http://docs.opscode.com/chef/essentials_handlers.html)
at the end of a Chef run. These can display information about the
resources that were updated, any exception that occurred, or other
data about the run itself. The handlers themselves are Ruby classes
that inherit from `Chef::Handler`, and then override the report method
to perform the actual reporting work. Chef handlers can be distributed
as RubyGems, or single files.

### client.rb

Chef becomes aware of the report or exception handlers through the
configuration file. For example, if I wanted to use the
`updated_resources` handler that I wrote as a
[RubyGem](http://rubygems.org/gems/chef-handler-updated-resources), I
would install the gem on the system, and then put the following in my `/etc/chef/client.rb`.

    require "chef/handler/updated_resources"
    report_handlers << SimpleReport::UpdatedResources.new
    exception_handlers << SimpleReport::UpdatedResources.new

Then at the end of the run, the report would print out the resources
that were updated.

### chef_handler Cookbook

For handlers that are simply a single file, use Opscode's
[chef_handler](http://ckbk.it/chef_handler) cookbook. It will
automatically handle putting the handlers in place on the system, and
adding them to the configuration.

### Other Handlers

A number of Chef handlers are available from the community and many
are listed on the
[Exception and Report Handlers page](http://wiki.opscode.com/display/chef/Exception+and+Report+Handlers#ExceptionandReportHandlers-CommunityBasedHandlers).
Conventionally, authors often prepend `chef-handler` to their gem
names to make them easier to find. Some common ones you may find
useful:

- [chef-irc-snitch](https://rubygems.org/gems/chef-irc-snitch): send
  exceptions to an IRC channel
- [chef-handler-campfire](https://github.com/ampledata/chef-handler-campfire): send exceptions and reports to campfire
- [hipchat](https://rubygems.org/gems/hipchat): the hipchat gem itself
  includes a Chef report handler!
- [chef-handler-graphite](https://github.com/imeyer/chef-handler-graphite):
  send Chef run report data to graphite.

<a name="item_12"></a>

# (12) Tagging nodes

A feature that has existed in Chef since its initial release is "node
tagging". This is simply a node attribute built in where entries can be added
and removed, or queried easily.

## Use cases

One can certainly use other node attributes for storing data. Since
node attributes can be any JSON object type, arrays are easily
available. Howeer, "tags" have some special helpers available, and
semantic uses that may make more sense than plain attributes.

Part of the idea is that tags may be added or removed, flipping the
node to various states as far as the Chef Server is concerned.
For example, one might only want to monitor nodes that have a certain
tag, or run data base migrations on a node tagged to do so.

## Tags in Chef Recipes

In Chef recipes, we can search for nodes that have a particular tag.
Perhaps nodes tagged "`decommissioned`" shouldn't be monitored.

    decommissioned_nodes = search(:node, "tags:decommissioned")

The recipe DSL itself has some
[tag-specific helper methods](http://docs.opscode.com/chef/dsl_recipe.html#tag-tagged-and-untag),
too.

Use `tagged?` to see if the node running Chef has a specific tag:

    if tagged?("decommissioned")
      raise "Why am I running Chef if I'm decommissioned?"
    end

Perhaps more usefully:

    if tagged?("run_migrations")
      execute "rake db:migrate" do
        cwd "/srv/myapp/current"
      end
    end

If the tags of the node need to be modified during a run, that can be
done with the `tag` and `untag` methods.

    tag("deployed")
    log "I'm printed if the tag deployed is set." do
      only_if { tagged?("deployed") }
    end

Or perhaps more usefully, untag the node after the migrations from
earlier are run:

    if tagged?("run_migrations")
      execute "rake db:migrate" do
        cwd "/srv/myapp/current"
        notifies :create, "ruby_block[untag-run-migrations]", :immediately
      end
    end

    ruby_block "untag-run-migrations" do
      block do
        untag("run_migrations")
      end
      only_if { tagged?("run_migrations") }
    end

## Knife Commands

There are knife commands for viewing and manipulating node tags.

View the tags of a node:

    knife tag list web23.example.com
    decommissioned

Add a tag to a node:

    knife tag create web23.example.com powered_off
    Created tags powered_off for node web23.example.com.

Remove a tag from a node:

    knife tag delete web23.example.com powered_off
    Deleted tags powered_off for node web23.example.com.

# Conclusion

Hopefully this post contains a number of things you didn't know were
available to Chef, and will be useful in your Chef environment.
