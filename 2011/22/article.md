# Day 22 - Load Balancing Solutions on EC2

This was written by [Grig Gheorghiu](http://agiletesting.blogspot.com).

Before Amazon introduced the [Elastic Load
Balancing](http://aws.amazon.com/elasticloadbalancing/) (ELB) service, the only
way to do load balancing in EC2 was to use one of the software-based solutions
such as [HAProxy](http://haproxy.1wt.eu/) or
[Pound](http://www.apsis.ch/pound). 

Having just one EC2 instance running a software-based load balancer would
obviously be a single point of failure, so a popular technique was to do DNS
Round-Robin and have the domain name corresponding to your Web site point to
several IP addresses via separate A records. Each IP address would be an
Elastic IP associated to an EC2 instance running the load balancer software.
This was still not perfect, because if one of these instances would go down,
users pointed to that instance via DNS Round-Robin would still get an error
until another instance would be launched.

Another issue that comes up all the time in the context of load balancing is
SSL termination. Ideally you would like the load balancer to act as an SSL
end-point, in order to offload the SSL computations from your Web servers, and
also for easier management of the SSL certificates. HAProxy does not support
SSL termination, but Pound does (note: that you can still pass SSL traffic
through HAProxy by using its TCP mode, you just cannot terminate SSL traffic
there.)

In short, if Elastic Load Balancing weren’t available, you could still cobble
together a load balancing solution in EC2. There is no reason to ‘roll your
own’ anymore however now that you can use the ELB service. Note that HAProxy is
still the king of load balancers when it comes to the different algorithms you
can use (and to a myriad of other features), so if you want the best of both
worlds, you can have an ELB upfront, pointing to one or more EC2 instances
running HAProxy, which in turn delegate traffic to your Web server farm.

## Elastic Load Balancing and the DNS Root Domain

One other issue that comes up all the time is that an ELB is only available as
a CNAME (this is due to the fact that Amazon needs to scale the ELB service in
the background depending on the traffic that hits it, so they cannot simply
provide an IP address). A CNAME is fine if you want to load balance traffic to
www.yourdomain.com, since that name can be mapped to a CNAME. However, the root
or apex of your DNS zone, yourdomain.com, can only be mapped to an A record, so
for yourdomain.com you could not use an ELB in theory. In practice, however,
there are DNS providers that allow you to specify an alias for your root domain
(I know [Dynect](http://dyn.com/dns/dynect-managed-dns/) does this, and
Amazon’s own [Route 53](http://aws.amazon.com/route53/) DNS service).

## Elastic Load Balancing and SSL ####

The [AWS console](https://console.aws.amazon.com) makes it easy to associate an
SSL certificate with an ELB instance, at ELB creation time. You do need to add
an SSL line to the HTTP protocol table when you create the ELB. Note that even
though you terminate the SSL traffic at the ELB, you have a choice of using
either unencrypted HTTP traffic or encrypted SSL traffic between the ELB and
the Web servers behind it. If you want to offload the SSL processing from your
Web servers, you can choose HTTP between the ELB and the Web server instances.

If however you want to associate an existing ELB instance with a different SSL
certificate (say for instance you initially associated it with a self-signed
SSL cert, and now you want to use a real SSL cert), you can’t do that with the
AWS console anymore. You need to use command-line tools. Here’s how.

Before you install the command-line tools, a caveat: you need Java 1.6. If you
use Java 1.5 you will most likely get errors such as
java.lang.NoClassDefFoundError when trying to run the tools.

1) Install and configure the AWS Elastic Load Balancing command-line tools

    * download [ElasticLoadBalancing.zip](http://aws.amazon.com/developertools/2536)
    * unzip `ElasticLoadBalancing.zip`; this will create a directory named
      ElasticLoadBalancing-version (latest version at the time of this writing is
      1.0.15.1)
    * set environment variable
      `AWS_ELB_HOME=/path/to/ElasticLoadBalancing-1.0.15.1` (in .bashrc) 
    * add `$AWS_ELB_HOME/bin` to your `$PATH` (in `.bashrc`)

2) Install and configure the AWS Identity and Access Management (IAMCli) tools

    * download [`IAMCli.zip`](http://aws.amazon.com/developertools/AWS-Identity-and-Access-Management/4143)
    * unzip `IAMCli.zip`; this will create a directory named IAMCli-version
      (latest version at the time of this writing is 1.3.0)
    * set environment variable `AWS_IAM_HOME=/path/to/IAMCli-1.3.0` (in `.bashrc`)
    * add `$AWS_IAM_HOME/bin` to your `$PATH` (in `.bashrc`)

3) Create AWS credentials file

    * create file with following content
            AWSAccessKeyId=your_aws_access_key
            AWSSecretKey=your_aws_secret_key
    * if you named this file `aws_credentials`, set environment variable
      `AWS_CREDENTIAL_FILE=/path/to/aws_credentials` (in .bashrc)

4) Get DNS name for ELB instance you want to modify

    We will use the ElasticLoadBalancing tool called elb-describe-lbs:

        # elb-describe-lbs
        LOAD_BALANCER  mysite-prod  mysite-prod-2639879155.us-east-1.elb.amazonaws.com  2011-05-24T22:38:31.690Z
        LOAD_BALANCER  mysite-stage   mysite-stage-714225413.us-east-1.elb.amazonaws.com    2011-09-16T18:01:16.180Z

    In our case, we will modify the ELB instance named mysite-stage.

5) Upload SSL certificate to AWS

    I assume you have 3 files:

    * the SSL private key in a file called `stage.mysite.com.key`
    * the SSL certificate in a file called `stage.mysite.com.crt`
    * an intermediate certificate from the SSL vendor, in a file called `stage.mysite.com.intermediate.crt`

    We will use the IAMCli tool called `iam-servercertupload`:

        # iam-servercertupload -b stage.mysite.com.crt -c stage.mysite.com.intermediate.crt -k stage.mysite.com.key -s stage.mysite.com

6) List the SSL certificates you have uploaded to AWS

    We will use the IAMCli tool called `iam-servercertlistbypath`:

        # iam-servercertlistbypath
        arn:aws:iam::YOUR_IAM_ID:server-certificate/stage.mysite.com
        arn:aws:iam::YOUR_IAM_ID:server-certificate/www.mysite.com

7) Associate the ELB instance with the desired SSL certificate

    We will use the ElasticLoadBalancing tool called `elb-set-lb-listener-ssl-cert`:

        # elb-set-lb-listener-ssl-cert mysite-stage --lb-port 443 --cert-id arn:aws:iam::YOUR_IAM_ID:server-certificate/stage.mysite.com
        OK-Setting SSL Certificate

That's it! At this point, the SSL certificate for stage.mysite.com will be
associated with the ELB instance handling HTTP and SSL traffic for
stage.mysite.com. Not rocket science, but not trivial to put together all these
bits of information either.

## Further Reading

* [Elastic Load Balancing Developer
  Guide](http://docs.amazonwebservices.com/ElasticLoadBalancing/latest/DeveloperGuide/)
* [AWS Identity and Access Management User
  Guide](http://docs.amazonwebservices.com/IAM/latest/UserGuide/)
* Blog post by Werner Vogels on [New Route 53 and ELB
  features](http://www.allthingsdistributed.com/2011/05/aws_ipv6.html)
