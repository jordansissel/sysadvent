# Day 10 - Analyzing Logs with Pig and Elastic MapReduce

This was written by [Grig Gheorghiu](http://agiletesting.blogspot.com)

## Why Pig

Parsing and analyzing individual log files can be done fairly easily with
standard Unix tools such as find, grep, sed, awk, wc etc. The difficult part is
doing this at scale when you are dealing with large quantities of logs.
[Hadoop](http://http://hadoop.apache.org/) is a suite of technology that has
proven itself to be capable of scaling well as you are throwing more and more
data at it. What makes it even better is the large ecosystem that has grown
around it with tools such as Hive and Pig which offer high-level programming
constructs that make your life easier as a "data analyst." I chose Pig for this
article because I find it a bit more friendly for programmers, whereas Hive is
more appropriate for SQL die-hards.

Pig is an Apache project which, as the [official
documentation](http://pig.apache.org) says, “is a platform for analyzing large
data sets that consists of a high-level language for expressing data analysis
programs, coupled with infrastructure for evaluating these programs. The
salient property of Pig programs is that their structure is amenable to
substantial parallelization, which in turns enables them to handle very large
data sets.”

Pig runs on top of Hadoop. You could build out your own Hadoop cluster, but for
quick experimentation you would be advised to choose a platform like Amazon’s
[Elastic MapReduce](http://aws.amazon.com/elasticmapreduce/) (EMR) which
abstracts away the operational details of a Hadoop cluster and lets you focus
on writing your data analysis scripts. In the rest of the article, I’ll show you
how to launch an EMR cluster running Pig, how to use Pig to analyze sendmail
log files, and how to terminate the cluster once your data analysis is
finished. 

A major help in my experiments with Pig was an AWS article called [Parsing Logs
with Apache Pig and Elastic
MapReduce](http://aws.amazon.com/articles/2729). Although the article deals
with Apache logs and not mail logs, the techniques it presents are the same.

## Launching an EMR cluster with Pig interactively

In the examples that follow, I’ll use the `elastic-mapreduce` Ruby command-line
tool. Here are the steps you need to install and configure this tool:

## Installing the EMR Ruby CLI

Download the zip file from
[here](http://aws.amazon.com/developertools/Elastic-MapReduce/2264), then unzip
it somewhere on an EC2 instance where you can store your AWS credentials (a
management-type instance usually). I installed in /opt/emr on one of our EC2
instances. At this point, it's also a good idea to become familiar with the [EMR
Developer
Guide](http://docs.amazonwebservices.com/ElasticMapReduce/latest/DeveloperGuide/),
which has examples of various elastic-mapreduce use cases. I also found a good
[README](https://github.com/tc/elastic-mapreduce-ruby) on GitHub.
,
Next, create a `credentials.json` file containing some information about your AWS
credentials and the keypair that will be used when launching the EMR cluster.
The format of this JSON file is:

    {
      "access-id": "YOUR_AWS_ACCESS_ID",
      "private-key": "YOUR_AWS_SECRET_KEY",
      "key-pair": "YOUR_EC2_KEYPAIR_NAME",
      "key-pair-file": "PATH_TO_PRIVATE_SSH_KEY_CORRESPONDING_TO_KEYPAIR",
      "region": "us-east-1",
      "log-uri": "s3://somebucket.yourcompany.com/logs"
    }

## Launching an EMR Cluster Running Pig

Here’s a script that will launch an EMR cluster with 1 master instance and 2
slave instances, all m1.large, and will install Hadoop 0.20 and Pig. The
cluster can be accessed interactively via ssh because `--pig-interactive` is
specified as an option to elastic-mapreduce:

    #!/bin/bash
    # File name: run_emr_pig.sh

    TIMESTAMP=`date "+%Y%m%d%H%M"`
    EMR_DIR=/opt/emr
    LOG_FILE=$EMR_DIR/run_emr_pig.log.$TIMESTAMP
    
    START=`date "+%Y-%m-%d %H:%M"`
    
    echo $START > $LOG_FILE

    SSH_KEY=/root/.ssh/emrdw.pem
    NAME=piggish
    CREDENTIALS=/opt/emr/credentials.json
    NUM_INSTANCES=3
    MASTER_INSTANCE_TYPE=m1.large
    SLAVE_INSTANCE_TYPE=m1.large

    CMD="$EMR_DIR/elastic-mapreduce -c $CREDENTIALS --create --name "$NAME" --alive --num-instances $NUM_INSTANCES --master-instance-type $MASTER_INSTANCE_TYPE --slave-instance-type $SLAVE_INSTANCE_TYPE --hadoop-version 0.20 --pig-interactive"

    echo Launching EMR cluster with command $CMD >> $LOG_FILE

    JOBID=`$CMD| egrep 'j-.*' -o`
    echo JOBID: $JOBID >> $LOG_FILE
    while true;  do
       $EMR_DIR/elastic-mapreduce --list | grep $JOBID | grep WAITING
       if [ $? = 0 ]; then
           break
       fi
       sleep 10
    done

    $EMR_DIR/elastic-mapreduce --list | grep $JOBID >> $LOG_FILE

    MASTER=`$EMR_DIR/elastic-mapreduce --jobflow $JOBID --describe | grep MasterPublicDnsName | egrep 'ec2.*com' -o`
    echo Master node: $MASTER
    echo Master node: $MASTER >> $LOG_FILE

## Accessing the EMR cluster and running Pig interactively

To ssh into the EMR master node, you can do:

    $ ssh -i $SSH_KEY hadoop@$MASTER

One note: the version of Pig available in EMR currently is 0.6.

Once on the master node, you have the option to run pig in either local mode
(which will not go against Hadoop/HDFS) or in Hadoop mode. The local mode is
recommended for trying out your scripts against small data sets. In my case, I
wanted to analyze gzipped log files stored in S3, and there’s a bug in Pig
which prevents copying files from S3 to the local file system. The only way I
could test my scripts was to run Pig in regular Hadoop mode, and point it to
files in S3.

    $ pig

    grunt> RAW_LOGS = LOAD 's3://pig.mycompany.com/mail/test.maillog.gz' as (line:chararray);
    grunt> DUMP RAW_LOGS;

The above lines load a gzipped mail log file stored in S3 into what is called a
Pig relation (a collection of tuples) which I named `RAW_LOGS`. Then the `DUMP`
statement prints the relation to standard out. Each element of the relation is
a tuple with 1 element called line:

    (Nov  8 18:39:58 mail1 sendmail[18842]: pA8Ndwvm018842: from=<sender@example.com>, size=9549, class=0, nrcpts=1, msgid=<201111082339.pA8Ndwvm018842@mail1.example.com>, proto=ESMTP, daemon=MTA, relay=relay1 [10.10.10.152])
    (Nov  8 18:39:58 mail2 sendmail[18784]: pA8Ndtvm018781: to=<recipient@somedomain.net>, delay=00:00:03, xdelay=00:00:03, mailer=esmtp, pri=107011, relay=relay.somedomain.net. [A.B.C.D], dsn=2.0.0, stat=Sent (pA8NduK8032663 Message accepted for delivery))

Note that the file test.maillog.gz contains just a small subset of a regular
mail log file. This is the recommended way of experimenting with your data
before analysing it at scale: **start small, understand the structure of your
data, play with it**.

There is not much analysis we can do at this point unless we refine the
parsing of the log file. Pig supports regular expressions, so we’ll use that.
Before I go into more detailed examples, let me say that I advise you to become
familiar with the [Pig
tutorial](https://cwiki.apache.org/PIG/pigtutorial.html) and the Pig Latin
reference manuals, ([manual
1](http://pig.apache.org/docs/r0.7.0/piglatin_ref1.html) and [manual
2](http://pig.apache.org/docs/r0.7.0/piglatin_ref2.html)).

We first register the "piggybank", which is a collection of useful Pig
functions exposed via a jar file which gets installed automatically with Pig in
EMR. We import the `EXTRACT` function which allows us to use regular expressions
for parsing the Pig relation. We then go through each tuple of the relation
(with the `FOREACH` statement) and split it into fields by means of a
threatening-looking regular expression which will match all lines that contain
a destination email address (a "to" field).

Note that you need to escape the backslash everywhere. We save the result of
this processing into another relation called `LOGS_BASE`.

    grunt> REGISTER file:/home/hadoop/lib/pig/piggybank.jar;
    grunt> DEFINE EXTRACT org.apache.pig.piggybank.evaluation.string.EXTRACT();
    grunt> LOGS_BASE = FOREACH RAW_LOGS GENERATE
    >> FLATTEN(
    >> 	EXTRACT(line, '(\\S+)\\s+(\\d+)\\s+(\\S+)\\s+(\\S+)\\s+sendmail\\[(\\d+)\\]:\\s+(\\w+):\\s+to=<([^@]+)\\@([^>]+)>,\\s+delay=([^,]+),\\s+xdelay=([^,]+),.*relay=(\\S+)\\s+\\[\\S+\\],\\s+dsn=\\S+,\\s+stat=(.*)')
    >> )
    >> AS (
    >> 	month: chararray,
    >> 	day: chararray,
    >> 	time: chararray,
    >> 	mailserver: chararray,
    >> 	pid: chararray,
    >> 	sendmailid: chararray,
    >> 	dest_user: chararray,
    >> 	dest_domain: chararray,
    >> 	delay: chararray,
    >> 	xdelay: chararray,
    >> 	relay: chararray,
    >> 	stat: chararray
    >> );

If we dump the LOGS_BASE relation to stdout (via the `DUMP` statement), we see
something like this:

    (Nov,8,18:39:58,mail2,18817,pA8Ndvvm018807,user1,yahoo.com,00:00:00,00:00:00,mta6.am0.yahoodns.net.,Sent (ok dirdel))
    ()
    ()
    ()
    ()
    (Nov,8,18:39:58,mail1,13466,pA8NdvaN013451,user2,gmail.com,00:00:00,00:00:00,gmail-smtp-in.l.google.com.,Sent (OK 1320795598 v8si2644603yhm.107))
    (Nov,8,18:39:58,mail1,13389,pA8NdtaN013380,user3,me.com,00:00:02,00:00:02,mx.me.com.akadns.net.,Sent (Ok, envelope id 	0LUD00A9Q8EK4BQ0@smtpin135.mac.com))

Each tuple of the relation is either empty (if the regular expresssion doesn’t
match the line) or contains the elements we specified in the `EXTRACT` statement
(month, day, time, mailserver etc).

Now that we have the lines split into individual fields, we can start thinking
about analysing the data. One thing that you’ll find when doing data analysis
is that often one of the hardest things to do is to ask meaningful questions.
There may be wonderful stories waiting to be told by the data, but you need to
be able to extract those stories.

In the example that follows, I want to see the most common scenarios where mail
did not get sent correctly. I will be looking for a status that does not start
with "Sent," and I will want to see the top mail domains that were involved in
non-successful mail delivery.

First we select only the mail domain and the status from the `LOGS_BASE` relation:

    grunt> DOMAIN_STAT = FOREACH LOGS_BASE GENERATE dest_domain, stat;

We filter out the empty tuples:

    grunt> NOT_NULL = FILTER DOMAIN_STAT BY NOT $0 IS NULL;

We also filter out tuples with the ‘stat’ field not starting with "Sent":

    grunt> NOT_SENT = FILTER NOT_NULL BY NOT stat MATCHES 'Sent.*';

We now group the remaining tuples by domain and status, which are indicated by
their position in the NOT_SENT tuple (0 and 1 respectively):

    grunt> GROUPED = GROUP NOT_SENT by ($0, $1);

The `GROUPED` relation contains tuples of this form:

    ((alumni.myuniversity.edu,Deferred: 451 Requested mail action not taken: mailbox unavailable),{(alumni.myuniversity.edu,Deferred: 451 Requested mail action not taken: mailbox unavailable),(alumni.myuniversity.edu,Deferred: 451 Requested mail action not taken: mailbox unavailable)})

The first element of a tuple in the `GROUPED` relation is the tuple we grouped
by containing the original fields `$0` and `$1`. The second element is what is
called a "bag of tuples" which is a set of tuples denoted by `{}` bracketing. This
bag contains as many instances of the group as were found in the `GROUPED`
relation. This allows us to count those instances, sort by count in decreasing
order and mail domain in increasing order (as specified by ‘ORDER COUNT BY num
DESC, $0’), then limit to the top 50 results:

    grunt> COUNT = FOREACH GROUPED GENERATE FLATTEN(group), COUNT($1) as num;
    grunt> SORTED = LIMIT(ORDER COUNT BY num DESC, $0) 50;

The result looks something like this:

    (austin.rr.com,User unknown,2L)
    (comcast.net,User unknown,2L)
    (aol.com,User unknown,1L)
    (earthinlink.net,Deferred: Connection timed out with earthinlink.net.,1L)

## Putting it together in a parameterized script

After experimenting with the `grunt` command line tool, it’s time to put together
a script. You can find the statements you ran from the command line in the
`~/.pig_history file` on the master node. You can simply copy and paste them
into a script. I called mine `mail_domain_stat.pig`. I also parameterized the
input and output of the script by including the variables `$INPUT` and
`$OUTPUT` which will be passed to the script when it will be called. Here’s
the script:

    REGISTER file:/home/hadoop/lib/pig/piggybank.jar;
    DEFINE EXTRACT org.apache.pig.piggybank.evaluation.string.EXTRACT();
    RAW_LOGS = LOAD '$INPUT' as (line:chararray);
    LOGS_BASE = FOREACH RAW_LOGS GENERATE
    FLATTEN(
    	EXTRACT(line, '(\\S+)\\s+(\\d+)\\s+(\\S+)\\s+(\\S+)\\s+sendmail\\[(\\d+)\\]:\\s+(\\w+):\\s+to=<([^@]+)\\@([^>]+)>,\\s+delay=([^,]+),\\s+xdelay=([^,]+),.*relay=(\\S+)\\s+\\[\\S+\\],\\s+dsn=\\S+,\\s+stat=(.*)')
    )
    AS (
    	month: chararray,
    	day: chararray,
    	time: chararray,
    	mailserver: chararray,
    	pid: chararray,
    	sendmailid: chararray,
    	dest_user: chararray,
    	dest_domain: chararray,
    	delay: chararray,
    	xdelay: chararray,
    	relay: chararray,
    	stat: chararray
    );
    DOMAIN_STAT = FOREACH LOGS_BASE GENERATE dest_domain, stat;
    NOT_NULL = FILTER DOMAIN_STAT BY NOT $0 IS NULL;
    NOT_SENT = FILTER NOT_NULL BY NOT stat MATCHES 'Sent.*';
    GROUPED = GROUP NOT_SENT by ($0, $1);
    COUNT = FOREACH GROUPED GENERATE FLATTEN(group), COUNT($1) as num;
    SORTED = LIMIT(ORDER COUNT BY num DESC, $0) 50;
    STORE SORTED INTO '$OUTPUT';

Now I can call the script from the command line like this:

    $ TIMESTAMP=`date "+%Y%m%d%H%M"`
    $ pig -p INPUT="s3://pig.mycompany.com/mail/test.maillog.gz" -p OUTPUT="s3://pig.mycompany.com/mail/output/run_$TIMESTAMP" mail_domain_stat.pig

The output will consist of a series of files called `part-NN` (00, 01, etc.)
stored in the S3 bucket specified as the `OUTPUT` parameter. To get back the
final result, download the partial files and concatenate them.

Note that `INPUT` can be an expression such as
`INPUT="s3://pig.mycompany.com/mail/2011*.maillog.gz"` which would
automatically read in all files in S3 matching the expression
`2011*.maillog.gz`. As a matter of curiosity, when I ran the above Pig script
against all our mail logs for 2011, the most common errors where of the form
`"someisp.com     User unknown"` followed by `"Some mail server     Connection
timed out"`.

## Asking more questions of the data

Here are some more questions you can ask from a mail log, together with short
Pig examples:

Who are the top mail recipients?

    RAW_LOGS = LOAD '$INPUT' as (line:chararray);
    LOGS_BASE = FOREACH RAW_LOGS GENERATE
    FLATTEN(
    	EXTRACT(line, '(\\S+)\\s+(\\d+)\\s+(\\S+)\\s+(\\S+)\\s+sendmail\\[(\\d+)\\]:\\s+(\\w+):\\s+to=<([^>]+)>,\\s+delay=([^,]+),\\s+xdelay=([^,]+),.*relay=(\\S+)\\s+\\[\\S+\\],\\s+dsn=\\S+,\\s+stat=(.*)')
    )
    AS (
    	month: chararray,
    	day: chararray,
    	time: chararray,
    	mailserver: chararray,
    	pid: chararray,
    	sendmailid: chararray,
    	dest: chararray,
    	delay: chararray,
    	xdelay: chararray,
    	relay: chararray,
    	stat: chararray
    );
    DEST = FOREACH LOGS_BASE GENERATE dest;
    DEST_FILTERED = FILTER DEST BY NOT $0 IS NULL;
    DEST_COUNT = FOREACH (GROUP DEST_FILTERED BY $0) GENERATE $0, COUNT($1) as num;
    DEST_COUNT_SORTED = LIMIT(ORDER DEST_COUNT BY num DESC) 50;
    STORE DEST_COUNT_SORTED INTO ‘$OUTPUT’;

At what hours of the day do we send the most mail?

    RAW_LOGS = LOAD '$INPUT' as (line:chararray);
    LOGS_BASE = FOREACH RAW_LOGS GENERATE
    FLATTEN(
    	EXTRACT(line, '(\\S+)\\s+(\\d+)\\s+(\\d+):(\\d+):(\\d+)\\s+\\S+\\s+sendmail\\[\\d+\\]:\\s+\\w+:\\s+\\S+=<[^>]+>')
    )
    AS (
    	month: chararray,
    	day: chararray,
    	hour: chararray,
    	minute: chararray,
    	second: chararray
    );
    HOUR = FOREACH LOGS_BASE GENERATE hour;
    HOUR_FILTERED = FILTER HOUR BY NOT $0 IS NULL;
    HOUR_COUNT = FOREACH (GROUP HOUR_FILTERED BY $0) GENERATE $0, COUNT($1) as num;
    HOUR_COUNT_SORTED = ORDER HOUR_COUNT BY num DESC;
    STORE HOUR_COUNT_SORTED INTO '$OUTPUT';

Which mail servers are sending the most email (they should be almost equal if
you are using a round-robin mechanism):

    RAW_LOGS = LOAD '$INPUT' as (line:chararray);
    LOGS_BASE = FOREACH RAW_LOGS GENERATE
    FLATTEN(
    	EXTRACT(line, '(\\S+)\\s+(\\d+)\\s+(\\S+)\\s+(\\S+)\\s+sendmail\\[(\\d+)\\]:\\s+(\\w+):\\s+from=<([^>]+)>,\\s+size=(\\d+),\\s+class=(\\d+),\\s+nrcpts=(\\d+),\\s+msgid=<([^>]+)>.*relay=(\\S+)')
    )
    AS (
    	month: chararray,
    	day: chararray,
    	time: chararray,
    	mailserver: chararray,
    	pid: chararray,
    	sendmailid: chararray,
    	src: chararray,
    	size: chararray,
    	classnumber: chararray,
    	nrcpts: chararray,
    	msgid: chararray,
    	relay: chararray
    );
    RELAY = FOREACH LOGS_BASE GENERATE relay;
    RELAY_FILTERED = FILTER RELAY BY NOT $0 IS NULL;
    RELAY_COUNT = FOREACH (GROUP RELAY_FILTERED BY $0) GENERATE $0, COUNT($1) as num;
    RELAY_COUNT_SORTED = LIMIT(ORDER RELAY_COUNT BY num DESC) 50;
    STORE RELAY_COUNT_SORTED INTO '$OUTPUT';

One other interesting question I am working on is finding out how fast we
deliver a given piece of mail. This will involve defining two relations, one for
lines containing mail sources and one for lines containing mail destinations,
then joining them together based on the sendmail ID.

## Taking advantage of the elasticity of EMR

One of the nice things about using EMR is that you can launch an EMR cluster at
night, process your data, then terminate the cluster, thus paying only for the
period of time the cluster was in use. Here’s a script that does that. 

It launches a cluster, it copies your Pig scripts to the master node, then it
runs a Pig script. When that finishes, it terminates the cluster. The results
of the Pig script will have been stored in S3 at that point.

    #!/bin/bash

    TIMESTAMP=`date "+%Y%m%d%H%M"`
    EMR_DIR=/opt/emr
    LOG_FILE=$EMR_DIR/run_emr_pig.log.$TIMESTAMP

    START=`date "+%Y-%m-%d %H:%M"`
    
    echo $START > $LOG_FILE
    
    SSH_KEY=/root/.ssh/emrdw.pem
    NAME=piggish
    CREDENTIALS=/opt/emr/credentials.json
    NUM_INSTANCES=5
    MASTER_INSTANCE_TYPE=m1.large
    SLAVE_INSTANCE_TYPE=m1.xlarge
    
    CMD="$EMR_DIR/elastic-mapreduce -c $CREDENTIALS --create --name "$NAME" --alive --num-instances $NUM_INSTANCES --master-instance-type $MASTER_INSTANCE_TYPE --slave-instance-type $SLAVE_INSTANCE_TYPE --hadoop-version 0.20 --pig-interactive"

    echo Launching EMR cluster with command $CMD >> $LOG_FILE

    JOBID=`$CMD| egrep 'j-.*' -o`
    echo JOBID: $JOBID >> $LOG_FILE
    while true;  do
       $EMR_DIR/elastic-mapreduce --list | grep $JOBID | grep WAITING
       if [ $? = 0 ]; then
           break
       fi
       sleep 10
    done
    
    $EMR_DIR/elastic-mapreduce --list | grep $JOBID >> $LOG_FILE

    MASTER=`$EMR_DIR/elastic-mapreduce --jobflow $JOBID --describe | grep MasterPublicDnsName | egrep 'ec2.*com' -o`
    echo Master node: $MASTER
    echo Master node: $MASTER >> $LOG_FILE
    
    scp -i $SSH_KEY -r $EMR_DIR/pigscripts hadoop@$MASTER:
    ssh -i $SSH_KEY hadoop@$MASTER "cd pigscripts; ./mail_domain_stat.sh" >& /tmp/emr_pig.log

    cat /tmp/emr_pig.log  >> $LOG_FILE
    $EMR_DIR/elastic-mapreduce --jobflow $JOBID --terminate
    STOP=`date "+%Y-%m-%d %H:%M"`
    echo $STOP >> $LOG_FILE

Using this script (which launches 1 m1.large master node and 4 m1.xlarge slave
nodes) I was able to process 100 GB worth of compressed mail logs in a little
under 4 hours.

## Conclusion

The combination Apache Pig + Elastic MapReduce is a pretty powerful one when it
comes to doing large-scale data analysis. The learning curve for doing simple,
but useful, data analysis with Pig Latin is not very steep. Elastic MapReduce
has the advantage of abstracting away the operational details of a Hadoop
cluster, and it also makes sense financially if you only use it a few hours per
day.

## Resources

* [Apache Pig Wiki](https://cwiki.apache.org/confluence/display/PIG/Index)
* [Elastic MapReduce Developer Guide](http://docs.amazonwebservices.com/ElasticMapReduce/latest/DeveloperGuide/)
* [Programming Pig](http://ofps.oreilly.com/titles/9781449302641/) - O’Reilly book by Alan Gates
