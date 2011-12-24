# Automated deployments with LittleChef
 
_Written by [Grig Gheorghiu](http://agiletesting.blogspot.com/)
([@griggheo](http://www.twitter.com/griggheo))_
 
## Prologue
 
**Sysadmin #1** (to Sysadmin #2): So...I need you to tell me....what is Devops?

**Syadmin #2**: Devops? I don't know....I didn't expect a kind of Devops
Inquisition!

_[JARRING CHORD]_

_[The door flies open and Senior Devops admin Ximinez of Spain enters, flanked
by two junior Devops admins]_

**Ximinez**: NOBODY expects the Devops Inquisition! Our chief weapon is
collaboration...collaboration and automated deployments... Our two weapons are
collaboration and automated deployments...and ruthless procrastination.... Our
*three* weapons are collaboration, automated deployments, and ruthless
procrastination...and an almost fanatical devotion to vi.... Our *four*...no...
*Amongst* our weapons.... Amongst our weaponry...are such elements as
collaboration, automated deployments.... I'll come in again.

## Automated deployment systems: push vs. pull

I don't need the Devops Inquisition to tell me that I need to use automated
deployment/configuration management systems. They are indeed a critical part of
a self-respecting sysadmin's weaponry. Without them, the activities of
deploying and configuring servers become haphazard and fraught with errors. 
 
I like to differentiate between two types of automated deployment tools. One
type is what can be called a `push' system: a centralized server 'pushes'
deployments by running commands via ssh on remote nodes. Examples of push
systems are [Fabric](http://docs.fabfile.org/0.9.3/) and
[Capistrano](http://www.capify.org/index.php/Capistrano). The other type is
what can be called 'pull' systems: remote nodes 'pull' commands and
configurations from a centralized 'master' server. Examples of pull systems are
[Chef](http://wiki.opscode.com/display/chef/Home) and [Puppet](http://docs.puppetlabs.com/).
 
To me, the main advantage of a push system is that you're under total control
of what gets deployed where and at what time. Its main disadvantage is that it
doesn't scale well when you have to control hundreds of servers, although you
could use parallel ssh tools to help you there. In contrast, a pull system is
inherently more scalable, because the nodes contact the 'master' asynchronously
and independent of each other (see this [blog post](http://agiletesting.blogspot.com/2010/03/automated-deployment-systems-push-vs.html) of mine for more details and
comments on this topic.) However, with a pull system you can lose some of the
control on the exact targets and timing of the deployments.
 
My personal philosophy on using push vs. pull systems is to use a pull system
when a node boots up (as an EC2 instance for example, or bootstrapped with
[cobbler](https://fedorahosted.org/cobbler/) as another example) and have the
node create required users, mount file
systems, install monitoring tools, install and configure pre-requisite packages
-- basically everything up to the level of the actual application. I prefer to
then use a 'push' system to actually deploy the application and its
configuration files. Why? Because I usually do it in small batches of servers
at a time, and I would be nervous to know that a bad configuration change can
propagate to all nodes if I were to deploy it via a 'pull' system. Note however
that I manage tens and not hundreds of servers, so in this latter case I would
definitely at least reconsider my options.
Introducing LittleChef
 
One drawback of 'pull' systems is their complexity. You usually need to
configure the 'master' server, then have nodes authenticate against it and ask
it for tasks to run. If you've ever configured [Chef Server](http://wiki.opscode.com/display/chef/Installation#Installation-InstallingChefServer) for example, you
know it's not exactly trivial. This is one reason why Chef provides a variant
called [Chef Solo](http://wiki.opscode.com/display/chef/Installation#Installation-InstallingChefServer)
which runs in isolation on a given node without requiring
communication with a master server. The nice thing about Chef Solo is that it
still uses all the other concepts of Chef (and Puppet for that matter):
cookbooks, recipes, attributes, roles, etc. 
 
The question becomes: how do you get Chef Solo installed on a node? Well, one
way of doing it is by using [LittleChef](https://github.com/tobami/littlechef), a package created by [Miquel Torres](http://tobami.wordpress.com/), who
is also the author of [Overmind](https://github.com/tobami/overmind).
LittleChef is written in Python and uses Fabric as the underlying mechanism of
getting Chef Solo installed on a remote node, then sending cookbooks and roles
to that node for further processing via Chef Solo. It's a bit ironic that a
Python-based package deals with configuring and running a Ruby-based tool such
as Chef Solo, but it also shows flexibility in the design of Chef, since many
of the configuration files inspected by Chef are in JSON format, easy to
interpret in any modern language.
 
Essentially, LittleChef is a push system, so it brings simplicity to the table.
The fact that deployments are done on the remote nodes via Chef Solo also
brings into play the full repertory of a solid configuration management tool.
It should be relatively easy to migrate the remote nodes from Chef Solo to a
full-blown Chef Client / Chef Server setup down the road.
 
Another nice thing about LittleChef is that it allows you to easily debug your
cookbooks and roles. In a typical Chef Client/Server setup, once you modify a
cookbook or a role, you need to upload to the Chef Server via the knife
utility, then wait for the Chef Client on the remote node to contact the
server, then inspect the Chef log file for any errors. With LittleChef, the
process is much simpler: you modify a cookbook and/or a role, then you push it
to the remote node and you see any errors in real time. Read on for details on
how exactly you do this.

## Working with LittleChef 

Here I am using Ubuntu Lucid 10.04 as my OS. A similar procedure can be
followed for RedHat-based systems.
 
First install some pre-requisites:
 
    # apt-get install build-essential python-dev python-pip python-setuptools git-core
 
Then install Fabric and LittleChef via pip (or you can use easy_install if you
prefer):
 
    # pip install fabric
    (this also installs pycrypto and paramiko)
 
    # pip install littlechef
    (this will install the latest version of LittleChef at the time of this
    writing, which is 0.4.0)

## Initial LittleChef Configuration
 
Create a directory where your cookbooks, roles and node information will be
located. I like to call this directory 'kitchen', as Miquel suggests in his
documentation:
 
    $ mkdir kitchen; cd kitchen
 
Now run the main LittleChef utility script, appropriately named 'cook', with
new_deployment as an argument. It will create some sub-directories and a file
called auth.cfg:
 
    $ cook new_deployment
    nodes/ directory created...
    cookbooks/ directory created...
    roles/ directory created...
    auth.cfg created...
 
Edit auth.cfg and specify an user name and a password used for ssh-ing to the
remote nodes (make sure this user has sudo access on the remote node.)
 
If you want to use some of the cookbooks already published by Opscode, you can
replace the cookbooks directory with a git clone of the Opsode cookbook
repository from GitHub:
 
    $ rm -rf cookbooks
    $ git clone https://github.com/opscode/cookbooks.git

## Installing Chef Solo on the remote node
 
In the following examples, I'll use a server named app1 as my target remote
node. All the 'cook' commands in these examples have 'kitchen' as the current
working directory. If you try to run the 'cook' command outside of the
'kitchen', you'll get an error message:
 
Fatal error: You are executing 'cook' outside of a deployment directory
To create a new deployment in the current directory type 'cook new_deployment'
 
The first step in actually doing deployments via LittleChef is to install Chef
Solo on the remote node. This is very easy with the 'cook' command again, this
time with the 'deploy_chef' argument:
 
$ cook node:app1 deploy_chef
 
The LittleChef documentation talks about other ways of installing Chef Solo on
the remote node, for example via gems, or without asking for a confirmation.
See the
[README](https://github.com/tobami/littlechef/blob/master/README.textile) for
more details.

## Deploying an Opscode cookbook on the remote node
 
As a first example, let's deploy memcached on the remote node. There already is
a cookbook for memcached in the Opscode repository. If you ran the git clone
command above, you're all set to go. Assuming you are OK with the default
values for memcached (which are set in the file
kitchen/cookbooks/memcached/attributes/default.rb), all  you need to do is run:
 
    $ cook node:app1 recipe:memcached
     
    == Executing recipe memcached on node app1 ==
    Uploading cookbooks... (memcached, runit)
    Uploading roles...
    Uploading node.json...
     
    == Cooking... ==
     
    [app1] out: [Tue, 07 Dec 2010 11:14:21 -0800] INFO: Setting the run_list to
    ["recipe[memcached]"] from JSON
    [app1] out: [Tue, 07 Dec 2010 11:14:21 -0800] INFO: Starting Chef Run (Version
    0.9.8)
    [app1] out: [Tue, 07 Dec 2010 11:14:22 -0800] INFO: Upgrading
    package[memcached] version from uninstalled to 1.4.2-1ubuntu3
    [app1] out: [Tue, 07 Dec 2010 11:14:27 -0800] INFO: Upgrading
    package[libmemcache-dev] version from uninstalled to 1.4.0.rc2-1
    [app1] out: [Tue, 07 Dec 2010 11:14:30 -0800] INFO: Writing updated content for
    template[/etc/memcached.conf] to /etc/memcached.conf
    [app1] out: [Tue, 07 Dec 2010 11:14:30 -0800] INFO: Backing up
    template[/etc/memcached.conf] to
    /var/chef/backup/etc/memcached.conf.chef-20101207111430
    [app1] out: [Tue, 07 Dec 2010 11:14:30 -0800] INFO:
    template[/etc/memcached.conf] sending restart action to service[memcached]
    (immediate)
    [app1] out: [Tue, 07 Dec 2010 11:14:31 -0800] INFO: service[memcached]:
    restarted successfully
    [app1] out: [Tue, 07 Dec 2010 11:14:31 -0800] INFO: Chef Run complete in
    9.569211 seconds
    [app1] out: [Tue, 07 Dec 2010 11:14:31 -0800] INFO: Running report handlers
    [app1] out: [Tue, 07 Dec 2010 11:14:31 -0800] INFO: Report handlers complete
     
    SUCCESS: Node correctly configured
     
    Done.
    Disconnecting from app1... done.
 
The cook command above will also create a file called app1.json in the
kitchen/nodes directory. Here is the file:
 
    $ cat nodes/app1.json
    {
       "run_list": [
           "recipe[memcached]"
       ]
    }
     
Now assume you want to override some of the default memcached attributes. Let's
say you want to use more 1 GB of RAM for memcached rather than the default 64
MB. You can just edit app1.json and add this stanza to override that attribute:
 
     "memcached": {
       "memory": "1024"
     }

(if you add it at the end of the JSON file, make sure you put a comma after the
previous “run_list” stanza, otherwise the JSON syntax is invalid; however, even
if you have an invalid JSON syntax, the cook command will let you know exactly
what the syntax error is, which is a nice touch)
 
Now run the cook command, this time telling it to just configure the node. This
will use whatever you specified in app1.json, so there is no need to specify
the recipe name again on the command line:
 
    $ cook node:app1 configure
     
    == Configuring app1 ==
    Uploading cookbooks... (memcached, runit)
    Uploading roles...
    Uploading node.json...
     
    == Cooking... ==
     
    [app1] out: [Tue, 07 Dec 2010 11:45:36 -0800] INFO: Setting the run_list to
    ["recipe[memcached]"] from JSON
    [app1] out: [Tue, 07 Dec 2010 11:45:36 -0800] INFO: Starting Chef Run (Version
    0.9.8)
    [app1] out: [Tue, 07 Dec 2010 11:45:37 -0800] INFO: Writing updated content for
    template[/etc/memcached.conf] to /etc/memcached.conf
    [app1] out: [Tue, 07 Dec 2010 11:45:37 -0800] INFO: Backing up
    template[/etc/memcached.conf] to
    /var/chef/backup/etc/memcached.conf.chef-20101207114537
    [app1] out: [Tue, 07 Dec 2010 11:45:37 -0800] INFO:
    template[/etc/memcached.conf] sending restart action to service[memcached]
    (immediate)
    [app1] out: [Tue, 07 Dec 2010 11:45:38 -0800] INFO: service[memcached]:
    restarted successfully
    [app1] out: [Tue, 07 Dec 2010 11:45:38 -0800] INFO: Chef Run complete in
    1.757141 seconds
    [app1] out: [Tue, 07 Dec 2010 11:45:38 -0800] INFO: Running report handlers
    [app1] out: [Tue, 07 Dec 2010 11:45:38 -0800] INFO: Report handlers complete
     
    SUCCESS: Node correctly configured
     
    Done.
    Disconnecting from app1... done.
 
At this point, the /etc/memcached.conf file on node app1 will contain the new
memory value 1024.

## Adding your own cookbooks and recipes
 
I won't go into much detail on what exactly you need to do in order to create
your own cookbook. It's a good idea to start from an existing one, and add your
own recipes. Assuming your company is ACME Corporation, it's a good idea to
create a cookbook called 'acme', so I will use that in my examples below.

First off, LittleChef expects the cookbook metadata file to be in JSON format.
Here's an example:
 
    $ cat cookbooks/acme/metadata.json 
    {
       "suggestions": {
       },
       "maintainer_email": "admin@acme.com",
       "description": "Installs required packages for ACME applications",
       "recipes": {
         "acme": "Installs required packages for ACME applications"
       },
       "conflicting": {
       },
       "attributes": {
       },
       "providing": {
       },
       "dependencies": {
         "screen": [
         ],
         "python": [
         ],
         "git": [
         ],
         "build-essential": [
         ],
         "ntp": [
         ]
       },
       "replacing": {
       },
       "platforms": {
         "debian": [
         ],
         "centos": [
         ],
         "fedora": [
         ],
         "ubuntu": [
         ],
         "redhat": [
         ]
       },
       "version": "0.1.0",
       "groupings": {
       },
       "license": "Apache 2.0",
       "long_description": "",
       "name": "acme",
       "recommendations": {
       },
       "maintainer": "ACME"
     }
 
Note that the metadata file above specifies that the acme cookbook has
dependencies on some other cookbooks: screen, python, git, build-essential and
ntp. These are all part of the Opscode cookbook repository. LittleChef will
figure out these dependencies and will transfer the main cookbook (acme) along
with all the cookbooks it depends on to the remote node, so they can be
processed by Chef Solo.
 
Here's an example of a recipe I use, located in
cookbooks/acme/recipes/nginx.rb:
 
    $ cat cookbooks/acme/recipes/nginx.rb
    # install nginx from source
    nginx = "nginx-#{node[:acme][:nginx_version]}"
    nginx_pkg = "#{nginx}.tar.gz"
    nginx_upstream = "nginx-upstream-fair.tar.gz"
     
    downloads = [
       "#{nginx_pkg}",
       "#{nginx_upstream}",
    ]
     
    downloads.each do |file|
       remote_file "/tmp/#{file}" do
           source "http://#{node[:acme][:web_server]}/download/nginx/#{file}"
       end
    end
     
    script "install_nginx_from_src" do
     interpreter "bash"
     user "root"
     cwd "/tmp"
     not_if "test -f /usr/local/nginx/conf/nginx.conf"
     code <<-EOH
       tar xvfz #{nginx_upstream} 
       cd /tmp
       tar xvfz #{nginx_pkg}; cd #{nginx}; ./configure --with-http_ssl_module
       --with-http_stub_status_module --add-module=/tmp/nginx-upstream-fair/; make;
       make install 
       EOH
    end
 
This recipe downloads an nginx tarball and installs it via make install. Note
that the recipe uses two attributes, referenced as node[:acme][:nginx_version]
and node[:acme][:web_server]. These attributes have default values set in
cookbooks/acme/attributes/default.rb:
 
    default[:acme][:web_server] = 'mywebserver.acme.com'
    default[:acme][:nginx_version] = '0.8.20'
 
I find it a good practice to use an attribute wherever I am tempted to use a
hardcoded value for a variable in my recipes. This makes it easy to override
the attribute at the node level or at the role level. 
 
My 'acme' cookbook also has a recipe called default.rb, where I do things such
as installing more pre-requisite Python packages, adding more users, etc.

## Configuring roles
 
Instead of configuring nodes based on individual recipes (like we did when we
configured node app1 with the memcached recipe), a better way is to define
roles that nodes can belong to. Roles are in my view the most critical concept
of any good deployment/configuration management system. In Chef, roles are the
glue that ties nodes to cookbooks and recipes. A given node can belong to
multiple roles. If you change any recipe that a given role includes, all nodes
belonging to that role will automatically get the updated recipe.
 
Let's define a role called 'appserver'. This is done via a JSON file located in
kitchen/roles:
 
    $ cat roles/appserver.json 
    {
       "name": "appserver",
       "json_class": "Chef::Role",
       "run_list": [
         "recipe[acme]",
         "recipe[acme::nginx]",
         "recipe[memcached]"
       ],
       "description": "Installs required packages and applications for an ACME app
       server",
       "chef_type": "role",
       "default_attributes": {
         "memcached": {
           "memory": "1024"
         }
       },
       "override_attributes": {
       }
     }
 
Several things to note in this role definition:

* the run_list stanza specifies the recipes that need to be executed by nodes
   belonging to this role (the order of the recipes is also preserved, which is
   nice); in this example, the recipe defined in default.rb in the acme
   cookbook will be executed, followed by the recipe defined in nginx.rb in the
   acme cookbook, followed by the recipe defined in default.rb in the memcached
   cookbook
* because the acme cookbook depends on other cookbooks listed in its metadata
   file (screen, python, git, build-essential and ntp), the default recipes in
   those cookbooks will be executed before the default acme cookbooks recipe
   gets executed
* we use the default_attributes stanza to override the memcached memory from
   the default value of 64 MB (set as we mentioned before in
   cookbooks/memcached/attributes/default.rb) to a value of 1024 MB; I refer
   the reader to the ["Attribute Type and
   Precedence"](http://wiki.opscode.com/display/chef/Attributes#Attributes-AttributeTypeandPrecedence)
   wiki page from the Opscode documentation for more details on how attributes
   can be set and overridden at various levels
 
Now we have to associate the node app1 with the role appserver. We can just
modify the file nodes/app1.json like this:
 
    $ cat nodes/app1.json
    {
       "run_list": [
           "role[appserver]"
       ]
    }
 
Finally, we can run the cook command and configure the node with its new role:
 
      $ cook node:app1 configure
       
      == Configuring app1 ==
      Uploading cookbooks... (acme, memcached, python, build-essential, screen, git,
      ntp, runit)
      Uploading roles...
      Uploading node.json...
       
      == Cooking... ==
       
      […... etc (more output here) ]
 
Note how littlechef figured out all the dependencies and uploaded the
respective cookbooks to the remote node.
 
## Querying for nodes, roles and recipes
 
A nice feature of LittleChef is that is allows you to query its inventory
(defined by the information contained in the cookbooks, roles and nodes
sub-directories of the 'kitchen' directory) for things such as 'nodes
pertaining to a given role' or 'nodes that apply a given recipe', or 'list of
all roles' or 'list of all recipes'.  You can run 'cook -l' to see the
available command-line options:
 
    $ cook -l
    LittleChef: Configuration Management using Chef without a Chef Server
     
    Available commands:
     
       configure               Configure node using existing config file
       debug                   Sets logging level to debug
       deploy_chef             Install Chef-solo on a node
       list_nodes              List all nodes
       list_nodes_with_recipe  Show all nodes which have asigned a given recipe
       list_nodes_with_role    Show all nodes which have asigned a given recipe
       list_recipes            Show all available recipes
       list_roles              Show all roles
       new_deployment          Create LittleChef directory structure (Kitchen)
       node                    Select a node
       recipe                  Execute the given recipe,ignores existing config
       role                    Execute the given role, ignores existing config
 
Here is an example of querying for all nodes pertaining to the 'appserver'
role:
 
    $ cook list_nodes_with_role:appserver
   
  app1
   Role: appserver
     default_attributes:
       memcached: {'memory': '1024'}
     override_attributes:
   Node attributes:
 
## Epilogue
 
**Ximinez** [with a cruel leer]: Now -- you will stay in the Comfy Aeron Chair
until lunch time, with only a cup of coffee at eleven. [aside, to Biggles] Is
that really all it is?

**Biggles**: Yes, lord.

**Ximinez**: I see. I suppose we make it worse by shouting a lot, do we? Confess,
Sysadmin. Confess! Confess! Confess! Confess!

**Biggles**: I confess!

**Ximinez**: Not you!
 
So, Sysadmin, if you don't have an automated deployment/configuration
management strategy yet, and if you want to avoid torture in the Comfy
Aeron Chair, then roll up your sleeves and roll out a deployment
system like LittleChef for your infrastructure TODAY!

 
Further reading
 
1. [Opscode Chef wiki](http://wiki.opscode.com/display/chef/Home)
2. Some blog posts of mine on ["Chef Installation and Minimal Configuration"](http://agiletesting.blogspot.com/2010/07/chef-installation-and-minimal.html),
   ["Working with Chef Cookbooks and Roles"](http://agiletesting.blogspot.com/2010/07/working-with-chef-cookbooks-and-roles.html),
   ["Bootstrapping EC2 Instances with Chef"](http://agiletesting.blogspot.com/2010/07/bootstrapping-ec2-instances-with-chef.html),
   ["Working with Chef Attributes"](http://agiletesting.blogspot.com/2010/11/working-with-chef-attributes.html)
3. A four-part blog post series on “Building a Django App Server with Chef” by
   Eric Holscher ([Part 1](http://ericholscher.com/blog/2010/nov/8/building-django-app-server-chef/), [Part 2](http://ericholscher.com/blog/2010/nov/9/building-django-app-server-chef-part-2/), [Part 3](http://ericholscher.com/blog/2010/nov/10/building-django-app-server-chef-part-3/), [Part 4](http://ericholscher.com/blog/2010/nov/11/building-django-app-server-chef-part-4/))
4. Collaboration, ruthless procrastination and an almost fanatical devotion to
   vi are exercises left to the reader
