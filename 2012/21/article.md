# Day 21 - The Double-Hop Nightmare

This was written by [Sam Cogan](https://twitter.com/samcogan).

Kerberos, the authentication protocol, is not something that usually needs to
be thought about - it usually just works, but when you move into the world of
impersonation, delegation, and the double hop, things start to get complicated.
There are many articles on the internet that explain the process to make double
hop delegation work, what they don’t explain is the many pitfalls that can
occur on the way that lead to you feeling like you’d rather be gouging your
eyes out with spoons.

What is this double hop of which we speak? The most common example is where
you have a client accessing a website and using Windows authentication which, in
turn, accesses a back-end database with that users credentials.

<img src="https://lh3.googleusercontent.com/-P-QpvAL7EQ0/UNQUBBXqavI/AAAAAAAAAKg/GZliwxJrfZM/s533/auth.png" style="border: 0">

If any old web server could delegate user credentials to another back-end
server, we would have the potential for security issues, so in the Windows
world we need to configure the system to allow this type of delegation in a
secure manner. This is where the problems start.

## SPN's

To be able to delegate a service, you need to create a Service Principal Name
for each service. In theory, this is a relatively trivial command to run:

    setspn -A <service name>/<machine name> <domain>\<account name>

However, there are a number of possible pitfalls to be aware off:

* You need to ensure you create an SPN for all possible names. This includes
  both FQDN and Netbios names, and any aliases, if you are going to access the
  service by something other than the machine name
* Duplicate SPN’s cause problems - make sure you don’t have other SPN’s for the
  same service but different user account name
* If your service is running as a system account, it will usually create the
  SPN for you, so check before you try and create another. SQL server for
  example does this
* Ensure the service account that you are creating the SPN for is in the same
  domain as the machine it is running on
* If the service is running on the non default port, make sure you include the
  port number

## Some Notes About SQL

Whilst creating SPN’s for most service’s is pretty straightforward, SQL can be
a bit of a nightmare. To try and avoid the issues, look to follow these tips.

* If you're going to create port based SPN’s, make sure you disable dynamic
  ports in SQL, else you might find delegation works fine until your first
  restart of SQL server.
* If your are using a named instance, make sure you include the instance name,
  or the port number in the SPN.
* Unless you have a very simple setup, run SQL as a designated service account,
  not the system account. Whilst running as the system account will create
  SPN’s for you, if you have clients in other domains or forests it can cause
  problems.


## Some Notes About IIS

If you're using a domain service account for running your application pool, you
need to set the option to “useAppPoolCredentials” to true, so that we use the
application pool account as part of the delegation process: 

1.       Open IIS Manager.
2.       Expand the server and then ‘Sites’, then select the application
3.       Under Management, select ‘Configuration Editor’.
4.       In the ‘From:’ section above the properties, select
   ‘ApplicationHost.config <location path=…’
5.       For the ‘Section:’ location, select system.webServer > security >
   authentication > windowsAuthentication.
6.       In the properties page, set useAppPoolCredentials to True, then click Apply

## Enabling Delegation

Once you’ve got all the SPN’s setup, it’s a simple step to enable constrained
delegation in Active directory, Microsoft explain the process quite clearly
here - http://technet.microsoft.com/en-us/library/cc756940(v=ws.10).aspx but as
always, there are things that can go wrong:

* If the service your select to allow constrained delegation to is running as a
  service account rather than system, make sure you select the service account
  when you are setting delegation up, not the machine.
* Where there are multiples of the same service, but on different ports - like
  SQL, make sure you pick the right one.

## Troubleshooting Tools

Ultimately, you might follow all these tips and still end up with delegation
not working, which can be a very frustrating experience. There are some tools
that can help diagnosing these issues easier:

* [__DelegConfig__](http://www.iis.net/downloads/community/2009/06/delegconfig-v2-beta-(delegation-kerberos-configuration-tool)) - Brian Booth’s tool for debugging 
  kerberos delegation when using IIS, will run you through a wizard and show
  you a report telling you what is and isn’t setup correctly and whether
  delegation will work. It can even fix some of your issues given the right
  permissions.
* __KList/Kerbtray__ - If you're using Server 2008 R2, the new Klist tool can be
  used to view kerberos tickets and diagnose what delegation is taking place.
  If you're using an older OS you’re stuck with Kerbtray, which can be found in
  the 2003 Server resource kit (this works on 2008 server as well).
* __Event Viewer__ - Use the security log in event viewer to get more detailed
  error messages on the delegation failures

## Final Thoughts

Whilst getting double hop delegation can seem a bit of an arduous process, so
long as you bear in mind it’s very strict requirements it can become less of a
dark art and more of a process to follow. Hopefully it’s not something you’ll
need to do too often, but if you do, I hope these tips make things a little
less painful.

## Further Reading

* [Kerberos Explained with Animation](http://www.youtube.com/watch?v=dDKuLMLOEb4)
* [Kerberos Explained](http://technet.microsoft.com/en-us/library/bb742516.aspx)
* [IIS and Windows Auth](http://weblogs.asp.net/owscott/archive/2008/08/22/iis-windows-authentication-and-the-double-hop-issue.aspx)
