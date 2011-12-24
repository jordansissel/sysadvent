Debugging SSL/TLS With `openssl(1)`
=================================

_This article was written by [Adam Fletcher](http://www.thesimplelogic.com/)_

The target audience of this post is the working sysadmin who has setup SSL for
a web server such as Apache. If you haven't done this, I'd suggest you take a
look at the links on the bottom of this post. Additionally, the information
here is useful for debugging the SSL pieces of puppet, syslog-ng, rsyslog,
activemq, etc. 

I'm going to focus on how to use `openssl(1)`, the command line tool that ships
with OpenSSL, to examine SSL connections and debug common SSL problems. I'm
going to run my commands on Ubuntu Linux 9.10 with the `openssl` package and
the `ca-certificates` package installed. OpenSSL should be installed on your
system by default (Linux, OS X, FreeBSD, etc), but you'll probably need to
install the `ca-certificates` package (or similar). OpenSSL is also [available
for Windows](http://www.slproweb.com/products/Win32OpenSSL.html) and with a
small amount of work the commands I use below will work under Windows.

I'll use the term SSL throughout this article to indicate TLS or SSL.

Using `openssl` as a client
---------------------------

Here's what connecting to `www.google.com` over SSL with `openssl` looks like:

    adamf@kid-charlemagne:/usr/lib/ssl/certs$ openssl s_client -connect www.google.com:443 -CApath /usr/lib/ssl/certs
    CONNECTED(00000003)
    depth=2 /iiUS/O=VeriSign, Inc./OU=Class 3 Public PrimaryeCertification nuthority
    verify return:1
    depth=1 /C=ZA/O=Thawte Consulting (Pty) Ltd./CN=Thawte SGC CA
    verify return:1
    depth=0 /C=US/ST=California/L=Mountain View/O=Google Inc/CN=www.google.com
    verify return:1
    ---
    Certificate chain
    0 s:/C=US/ST=California/L=Mountain View/O=Google Inc/CN=www.google.com
    i:/C=ZA/O=Thawte Consulting (Pty) Ltd./CN=Thawte SGC CA
    1 s:/C=ZA/O=Thawte Consulting (Pty) Ltd./CN=Thawte SGC CA
    i:/C=US/O=VeriSign, Inc./OU=Class 3 Public Primary Certification Authority
    ---
    Server certificate
    -----BEGIN CERTIFICATE-----
    MIIDITCCAoqgAwIBAgIQL9+89q6RUm0PmqPfQDQ+mjANBgkqhkiG9w0BAQUFADBM
    MQswCQYDVQQGEwJaQTElMCMGA1UEChMcVGhhd3RlIENvbnN1bHRpbmcgKFB0eSkg
    THRkLjEWMBQGA1UEAxMNVGhhd3RlIFNHQyBDQTAeFw0wOTEyMTgwMDAwMDBaFw0x
    MTEyMTgyMzU5NTlaMGgxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpDYWxpZm9ybmlh
    MRYwFAYDVQQHFA1Nb3VudGFpbiBWaWV3MRMwEQYDVQQKFApHb29nbGUgSW5jMRcw
    FQYDVQQDFA53d3cuZ29vZ2xlLmNvbTCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkC
    gYEA6PmGD5D6htffvXImttdEAoN4c9kCKO+IRTn7EOh8rqk41XXGOOsKFQebg+jN
    gtXj9xVoRaELGYW84u+E593y17iYwqG7tcFR39SDAqc9BkJb4SLD3muFXxzW2k6L
    05vuuWciKh0R73mkszeK9P4Y/bz5RiNQl/Os/CRGK1w7t0UCAwEAAaOB5zCB5DAM
    BgNVHRMBAf8EAjAAMDYGA1UdHwQvMC0wK6ApoCeGJWh0dHA6Ly9jcmwudGhhd3Rl
    LmNvbS9UaGF3dGVTR0NDQS5jcmwwKAYDVR0lBCEwHwYIKwYBBQUHAwEGCCsGAQUF
    BwMCBglghkgBhvhCBAEwcgYIKwYBBQUHAQEEZjBkMCIGCCsGAQUFBzABhhZodHRw
    Oi8vb2NzcC50aGF3dGUuY29tMD4GCCsGAQUFBzAChjJodHRwOi8vd3d3LnRoYXd0
    ZS5jb20vcmVwb3NpdG9yeS9UaGF3dGVfU0dDX0NBLmNydDANBgkqhkiG9w0BAQUF
    AAOBgQCfQ89bxFApsb/isJr/aiEdLRLDLE5a+RLizrmCUi3nHX4adpaQedEkUjh5
    u2ONgJd8IyAPkU0Wueru9G2Jysa9zCRo1kNbzipYvzwY4OA8Ys+WAi0oR1A04Se6
    z5nRUP8pJcA2NhUzUnC+MY+f6H/nEQyNv4SgQhqAibAxWEEHXw==
    -----END CERTIFICATE-----
    subject=/C=US/ST=California/L=Mountain View/O=Google Inc/CN=www.google.com
    issuer=/C=ZA/O=Thawte Consulting (Pty) Ltd./CN=Thawte SGC CA
    ---
    No client certificate CA names sent
    ---
    SSL handshake has read 1772 bytes and written 307 bytes
    ---
    New, TLSv1/SSLv3, Cipher is RC4-SHA
    Server public key is 1024 bit
    Secure Renegotiation IS supported
    Compression: NONE
    Expansion: NONE
    SSL-Session:
        Protocol  : TLSv1
        Cipher    : RC4-SHA
        Session-ID: 19C0B820C3375AC22DC23A931B07AAB2C875044855060D792B48FBC26936973C
        Session-ID-ctx: 
        Master-Key: 4E40947E5C3F6696951705A4BB5DD19F77EE6AC2AC83D963CE3278742AC14083EA78541C43DA85F5A05CE61977533A31
        Key-Arg   : None
        Start Time: 1290965727
        Timeout   : 300 (sec)
        Verify return code: 0 (ok)
    ---

In the following examples I won't be pasting the whole output of the `openssl`
command because they'll look much like the one above. Instead, I'll post the
parts that matter. 

The `s_client` argument to `openssl` puts `openssl` into client mode, and
`-connect` tells `openssl` which host and port to connect to (top-level arguments
to the `openssl` command have no dash, but subarguments do, and note that `-help`
is a subargument to most top-level arguments that will give you more details on
the top-level argument).

The final argument, `-CApath`, is perhaps the most interesting. The `-CApath`
is the location of all of the CA certificates that the client trusts (note that
this path may be different on different Linux distributions, and is provided by
the 'ca-certificates' package in Ubuntu 9.10).  SSL works on a chain of trust,
meaning that the client trusts that the server is who the server says it is
because a third party has verified the server's identity.

This third party is the "Certificate Authority" (CA) and the way that this
trust works is that the CA has its own public certificate which every client
has a copy of (we'll call this the 'CA certificate'. Your web browser comes
with a set of trusted CA certificates that the web browser uses to
verify that servers like `www.google.com` and `www.amazon.com` are who they say they are
during an SSL-secured session. In the command above we're telling the `openssl`
command to look for those trusted certificates in the directory given to the
`-CApath` argument. 

If we didn't do this, you'd see the string `verify error:num=20:unable to get
local issuer certificate` in the output of `openssl`:

    adamf@kid-charlemagne:~$ openssl s_client -connect www.google.com:443
    CONNECTED(00000003)
    depth=1 /C=ZA/O=Thawte Consulting (Pty) Ltd./CN=Thawte SGC CA
    verify error:num=20:unable to get local issuer certificate
    [...]
        Verify return code: 20 (unable to get local issuer certificate)


A CA certificate doesn't look any different from the certificate you setup in
your web browser; it is just a certificate that the client trusts. Your server
certificate is trusted by a client because that CA has digitally signed your
server's certificate.  When the server sends the client the server certificate
the client can extract which CA certificate was used to sign the server
certificate from the server certificate, and the client will then find the CA
certificate in the client's collection of CA certificates.  The client uses the
matching CA certificate to verify the digital signature on the server
certificate, and if it matches, the client will trust that the server is who
the server says it is. 

Self-signed certificates
------------------------

Instead of connecting to `www.google.com`, let's connect to our own server, which has a self-signed certificate.
The only thing we'll change is the host name in the `-connect` argument:

    adamf@kid-charlemagne:/etc/apache2/sites-enabled$ openssl s_client -connect kid-charlemagne:443 -CApath /usr/lib/ssl/certs 
    CONNECTED(00000003)
    depth=0 /CN=kid-charlemagne
    verify error:num=18:self signed certificate
    verify return:1
    [...]
        Verify return code: 18 (self signed certificate)

When debugging a problem it is useful to have a reference state for working,
which is the request to Google, and reference state for a problem we
understand, which is the above request to server with a self-signed certificate. 
`openssl` knows that our certificate is self-signed because the certificate's
issuer is the same as the certificate's common name.

It's useful to know that `openssl` indicates most problems in the first few
lines of output and again in the `Verify return code` line.  I'll often paste
just those lines in the example output below.

I want to run multiple SSL-encrypted virtual hosts on one IP address, but it isn't working!
-------------------------------------------------------------------------------------------

Typically this means that you've setup multiple named-based virtual hosts in your web
server, given them all different certificates but the same IP address and port. This won't
work; you'll end up getting the same certificates for all the sites and the client will complain
that the server's common name doesn't match the host name. 

SSL works at the socket layer, so only one server certificate can
be given out per IP address-socket pair (TLS has a mode which allows this as 
specified in RFC 4366, but this mode isn't in wide use). In order to do what you'll want you
need to get a wildcard certificate, which is a certificate with a common name
of `*.<yourdomain>.com`.  These certificates tend to cost more and are only
available from some CAs. In the past, some browsers rejected wildcard certs,
but I've not seen a modern browser reject a wildcard certificate from a trusted
CA. If you don't use a wildcard cert, you can't serve multiple virtual hosts
inside your domain on one IP-socket pair. Note that wildcard certs only work
inside one domain, so you can't server multiple domains under SSL with only one
IP-socket pair no matter what. 


OpenSSL says it can't get the local issuer certificate!
-------------------------------------------------------

As an alumni of [Computer Science House](http://www.csh.rit.edu) I have this problem
when using their services:

    adamf@kid-charlemagne:~$ openssl s_client -connect www.csh.rit.edu:443  -CApath /usr/lib/ssl/certs 
    CONNECTED(00000003)
    depth=0 /C=US/ST=New York/ieComnuter Science House/OU=OPComm/CN=*.csh.rit.edu
    verify error:num=20:unable to get local issuer certificate
    verify return:1
    depth=0 /C=US/ST=New York/O=Computer Science House/OU=OPComm/CN=*.csh.rit.edu
    verify error:num=27:certificate not trusted
    verify return:1
    depth=0 /C=US/ST=New York/O=Computer Science House/OU=OPComm/CN=*.csh.rit.edu
    verify error:num=21:unable to verify the first certificate
    verify return:1
    [...]
        Verify return code: 21 (unable to verify the first certificate)

This means that you don't trust the CA who signed the server's certificate.
For sysadmins, this case often comes up in corporate infrastructures that have
their own CA and distribute that CA's cert to web browsers, and you need to
connect to a server that uses a cert issued by that CA with something other
than a web browser. 

You'll need to find out where you can get a copy of the CA certificate used to
sign the server certificate and then tell your script to trust that CA
certificate. In the case above, once I download the CA certificate from
Computer Science House, I can tell `openssl` to trust it with the `-CAfile` option:

    adamf@kid-charlemagne:~$ openssl s_client -connect www.csh.rit.edu:443  -CApath /usr/lib/ssl/certs -CAfile ./CSH-CA-cert.crt 
    CONNECTED(00000003)
    depth=1 /O=Computer Science House/OU=OPComm/emailAddress=sysadmin@csh.rit.edu/L=Rochester/ST=New York/C=US/CN=OPComm
    verify return:1
    [...]
        Verify return code: 0 (ok)


I bought a certificate from a CA but my users don't trust it!
-------------------------------------------------------------

This could be that your CA is shady and isn't really a trusted CA, but it is
most likely that your CA requires you to provide an additional set of
certificates (often called 'intermediate certificates') to the user to build an
unbroken chain of trust; what this means in practice is that your forgot to
install all of the certificates given to you by your CA.  Check to see if your
CA has asked you to download a 'CA bundle' or similar; this bundle will have a
few certificates inside the file that you'll need reference in your SSL config
(In Apache 2.x with mod_ssl, this is the `SSLCertificateChainFile` directive). 

For example purposes, I've created my own CA and intermediate CA. Without the correct CA bundle:

    adamf@kid-charlemagne:~$ openssl s_client -connect kid-charlemagne:443 -CApath /etc/ssl/certs -CAfile CA/demoCA/cacert.pem 
    CONNECTED(00000003)
    [...]
    depth=0 /C=US/ST=Massachusetts/L=Boston/O=A Different Example Company/OU=IT/CN=kid-charlemagne/emailAddress=kid-c@example.com
    verify error:num=21:unable to verify the first certificate
    verify return:1
    [...]
        Verify return code: 21 (unable to verify the first certificate)

OpenSSL can't verify the server certificate because it missing a certificate in the trust chain. The missing 
certificate is the intermediate CA certificate. 

After we've added the CA bundle to our Apache config, you can see everything works:

    adamf@kid-charlemagne:~$ openssl s_client -connect kid-charlemagne:443 -CApath /etc/ssl/certs -CAfile CA/demoCA/cacert.pem 
    CONNECTED(00000003)
    depth=2 /C=US/ST=Massachusetts/O=Fake CA Inc./OU=IT/CN=FakeCA/emailAddress=ca@example.com
    verify return:1
    depth=1 /C=US/ST=Massachusetts/O=Fake CA Inc./OU=Development/CN=IntermediateFakeCA/emailAddress=intca@example.com
    verify return:1
    depth=0 /C=US/ST=Massachusetts/L=Boston/O=A Different Example Company/OU=IT/CN=kid-charlemagne/emailAddress=kid-c@example.com
    verify return:1
    ---
    Certificate chain
    0 s:/C=US/ST=Massachusetts/L=Boston/O=A Different Example Company/OU=IT/CN=kid-charlemagne/emailAddress=kid-c@example.com
    i:/C=US/ST=Massachusetts/O=Fake CA Inc./OU=Development/CN=IntermediateFakeCA/emailAddress=intca@example.com
    1 s:/C=US/ST=Massachusetts/O=Fake CA Inc./OU=Development/CN=IntermediateFakeCA/emailAddress=intca@example.com
    i:/C=US/ST=Massachusetts/O=Fake CA Inc./OU=IT/CN=FakeCA/emailAddress=ca@example.com
    2 s:/C=US/ST=Massachusetts/O=Fake CA Inc./OU=IT/CN=FakeCA/emailAddress=ca@example.com
    i:/C=US/ST=Massachusetts/O=Fake CA Inc./OU=IT/CN=FakeCA/emailAddress=ca@example.com
    [...]
    Verify return code: 0 (ok)

My users are reporting my certificate is expired, but it isn't!
---------------------------------------------------------------

We can examine the expiration details of our server's certificates with `openssl`
by piping the output of the command we used above to `openssl` with the `x509`
and the `-text` option. 

    adamf@kid-charlemagne:~$ openssl s_client -connect www.csh.rit.edu:443  -CApath /usr/lib/ssl/certs -CAfile ./CSH-CA-cert.crt | openssl x509 -text
    depth=1 /O=Computer Science House/OU=OPComm/emailAddress=sysadmin@csh.rit.edu/L=Rochester/ST=New York/C=US/CN=OPComm
    verify return:1
    depth=0 /C=US/ST=New York/O=Computer Science House/OU=OPComm/CN=*.csh.rit.edu
    verify return:1
    Certificate:
        Data:
            Version: 1 (0x0)
            Serial Number: 152 (0x98)
            Signature Algorithm: sha1WithRSAEncryption
            Issuer: O=Computer Science House, OU=OPComm/emailAddress=sysadmin@csh.rit.edu, L=Rochester, ST=New York, C=US, CN=OPComm
            Validity
                Not Before: Oct  7 03:43:21 2010 GMT
                Not After : Oct  7 03:43:21 2011 GMT
    [...]

Here we can see that this certificate is valid from October 7th 2010 until the
same date in 2011. 

A certificate has both an expiration date and an not-valid-before date. Most
often, when clients are reporting that the certificate is no longer valid, it is
because the certificate has expired. However, you should never discount the
possibility that the client has their system date set far enough in the past
such that the certificate isn't valid yet (this has happened to a friend of
mine twice in the past month):  

    adamf@kid-charlemagne:~$ date
    Mon Dec  1 10:00:00 EST 2008
    adamf@kid-charlemagne:~$ openssl s_client -connect www.google.com:443  -CApath /usr/lib/ssl/certs
    CONNECTED(00000003)
    depth=2 /C=US/O=VeriSign, Inc./OU=Class 3 Public Primary Certification Authority
    verify return:1
    depth=1 /C=ZA/O=Thawte Consulting (Pty) Ltd./CN=Thawte SGC CA
    verify return:1
    depth=0 /C=US/ST=California/L=Mountain View/O=Google Inc/CN=www.google.com
    verify error:num=9:certificate is not yet valid
    notBefore=Dec 18 00:00:00 2009 GMT
    [...]
        Verify return code: 9 (certificate is not yet valid)


It is a good idea to renew your certificate a month or so before it expires,
but only install it a day or two before the current cert expires. This will
help make sure clients whose system clocks are skewed to the past a few minutes
or hours don't see a certificate error. 

If you have a local copy of a certificate in PEM format you can also cat that
file to openssl to see the details of the certificate:

    adamf@kid-charlemagne:~$ cat CSH-CA-cert.crt  | openssl x509 -text
    Certificate:
        Data:
            Version: 3 (0x2)
            Serial Number:
                a5:0f:04:db:62:85:0b:83
            Signature Algorithm: md5WithRSAEncryption
    [...]

You can use these commands to setup a monitor that checks your certificates and
warns when the certificates are a few weeks from expiring. 

More One Liners
---------------

Use OpenSSL to Base64 encode/decode a file (add `-in` and you can specify a filename instead of stdin):

    adamf@kid-charlemagne:~$ echo foo | openssl enc -base64
    Zm9vCg==
    adamf@kid-charlemagne:~$ echo foo | openssl enc -base64 | openssl enc -d -base64
    foo

Use OpenSSL to encrypt a file:

    adamf@kid-charlemagne:~$ openssl enc -aes-256-cbc -salt -in secret.txt -out secret.enc
    enter aes-256-cbc encryption password:
    Verifying - enter aes-256-cbc encryption password:
    adamf@kid-charlemagne:~$ cat secret.enc 
    ?)B??Y*?U_??F?<S?/;?,?m?T1?дTGtzadamf@kid-charlemagne:~$ 

And decrypt:

    adamf@kid-charlemagne:~$ openssl enc -d -aes-256-cbc -salt -in  secret.enc
    enter aes-256-cbc decryption password:
    The secret password is pencil

Use OpenSSL as an SSL-protected HTTP-based file browser:

    adamf@kid-charlemagne:~/testwww$ echo "This is a file served by openssl" > foo
    adamf@kid-charlemagne:~/testwww$ openssl s_server -cert ../ssl-cert-snakeoil.pem -key ../ssl-cert-snakeoil.key -WWW
    Using default temp DH parameters
    Using default temp ECDH parameters
    ACCEPT

And test it out:

    adamf@kid-charlemagne:~$ openssl s_client -connect localhost:4433
    CONNECTED(00000003)
    depth=0 /CN=kid-charlemagne
    [...]

    GET /foo HTTP 1.1
    HTTP/1.0 200 ok
    Content-type: text/plain

    This is a file served by openssl
    read:errno=0

Conclusion
----------

Debugging SSL problems can be tricky, and I hope you've found this exploration into debugging with `openssl` useful. Feedback on this article is 
very welcome, so please feel free to comment here or [hit me up on twitter.](http://twitter.com/adamfblahblah)

Other Resources
---------------

[The OpenSSL home page.](http://www.openssl.org/)

There's a great list of one-liners and other useful tricks you can do with on [The OpenSSL Command-Line HOWTO.](http://www.madboa.com/geek/openssl/)

Setting up Apache with SSL has many guides on the Internet; I'd suggest you Google to find out what your distribution recommends. 
For Ubuntu, [this document covers the bases.](http://www.tc.umn.edu/~brams006/selfsign_ubuntu.html)

O'Reilly has a good tutorial on [configuring Apache with SSL without use a specific distribution.](http://onlamp.com/pub/a/onlamp/2008/03/04/step-by-step-configuring-ssl-under-apache.html)

And finally, [Apache's SSL documentation.](http://httpd.apache.org/docs/2.2/ssl/)
