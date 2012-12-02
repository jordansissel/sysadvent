# Day 5 - ZooKeeper for Locking

The company I work for has a large high-performance compute cluster (20 PB/day the last time I checked), and I’m one of the people responsible for maintaining it. When one of the servers in that cluster is performing poorly or needs maintenance, we put it through a decommissioning process that salvages any data that can be recovered safely to minimize the risk of data loss in the filesystem. Although we can decommission several servers simultaneously, if too many are going out of business at the same time it slows down the rest of the cluster.

A while back, I wanted to make this process a little easier for us. My goal was to build a “fire-and-forget” mechanism where we could queue up a bunch of servers for decommissioning and let them work it out themselves without impacting the cluster.

Constraints
As I said before, having too many servers decommissioning at the same time will overload the cluster, as other healthy servers have to both try to copy data down from the broken servers and pick up their compute-processing slack. Also, I had an eye on someday setting up a watchdog-type system, where servers could regularly insepect their own performance metrics and automatically decommission themselves (and file a ticket to let us know) if they were getting too badly broken. In that event, I had to make 100% sure that there was no possible bug or other case that could cause every server in the cluster to decide to decommission itself at the same time, since that would completely stop all work on the cluster.

These constraints led me to the solution of using Apache Zookeeper to store a small pool of distributed lockfiles as decommissioning slots, which the servers could fight over for their turn to decommission themselves.

Zookeeper
In case you’re not familiar with Zookeeper, I’ll let them explain themselves:

ZooKeeper is a centralized service for maintaining configuration information, naming, providing distributed synchronization, and providing group services. All of these kinds of services are used in some form or another by distributed applications. Each time they are implemented there is a lot of work that goes into fixing the bugs and race conditions that are inevitable. Because of the difficulty of implementing these kinds of services, applications initially usually skimp on them, which make them brittle in the presence of change and difficult to manage. Even when done correctly, different implementations of these services lead to management complexity when the applications are deployed.
Basically, Zookeeper is a hierarchical key-value data store that has some very useful properties:

You can store most any reasonable data in the nodes
Most common operations are completely atomic
For instance, if two processes try to create the same node at the same time, it’s guaranteed that only one of them will succeed (and both of them will know about the outcome)
Hosts can register “watchers” and callback functions that subscribe to a node; when that node changes, the watches are notified and their callbacks are run (without polling)
It automatically and transparently spans multiple service hosts, so it’s very highly-available and fault-tolerant
It has bindings for many languages
Our Solution
As it turned out, we already had a ZooKeeper service operating on our cluster for a different purpose; I appropriated a small corner of the hierarchy for this project and went to town.

First, I wrote some simple scripts to create and delete the Zookeeper nodes I wanted to use as lock files; to keep it simple, we’ll call them /lock1, /lock2, and /lock3. Then I adapted our cluster maintenance tools to use those scripts for potentially destructive processes like decommissioning.

The Workflow
The workflow looks like this:

Hosts A, B, C, D, E, and F all decide that they need to be decommissioned at the same time.
Each host tries to create the Zookeeper node /lock1, populating the node with its own hostname for future reference.
In this example, we’ll say Host E wins the race and gets to create the node. Its decommissioning script begins to run.
Having failed to create /lock1, the remaining five hosts all attempt to create /lock2 in the same fashion.
Let’s say Host B wins this time; it starts decommissioning itself alongside Host E.
Repeat this process for /lock3, which Host A wins.
For the remaining three hosts that didn’t get a lock, sleep for a while and then start trying again with /lock1.
At this point, hosts A, B, and E are all chugging along. The other three hosts are patiently waiting their turn, and they will continue doing so until one of the other machines finishes and its decommissioning job deletes the lockfile Zookeeper node it was holding. When that happens, for instance if E finishes its work:

Host E‘s decommissioning script deletes the Zookeeper node /lock1. Host E is now officially out of service and will do no other work at all until somebody investigates, fixes it, and brings it back to life.
The decommissioning script has been hanging out on Hosts C, D, and F this whole time. On their next passes through the loop, each tries to create /lock1.
Say Host F wins; it starts decommissioning itself and the other two hosts keep cooling their heels in fervent anticipation of the day they might too get to start their work.
Other Integration
Since this process is so hands-off, I wanted to make sure we didn’t wind up in a situation where we had several nodes that were stuck decommissioning and keeping everybody else out of the party. I wrote a Nagios check plugin that would read an arbitrary Zookeeper node and report its existince (and the node’s contents, if any). This is where storing the hostname in the node when it’s created comes in handy: our Nagios checks against this plugin look at the age of the node and report if it’s more than a few days old, and the output of the check plugin includes the hostname of the machine that’s stuck so it’s easy to investigate.

This check plugin has come in handy for other people too, so it was well worth my time to have written even aside from its use in this project.
