----
Welcome to the dystopia your parents warned you about. 



Vendor lock-in used to mean that your data was stuck in a proprietary format, requiring you to buy expensive services to migrate to another provider. With *aaS, it means that your entire company can disappear in a puff of smoke if you weren't careful about your choices. Lets figure out how to avoid that outcome. 



System Administrators are a combination of maintenance staff, standing army, and consigliere. Not only do we keep things running smoothly, we guard against invaders, and we act as trusted advisors to the people who make corporate policies. It's unavoidable that at some point we will need to advise our organizations to rely on outside sources for IT services, and when we do that, the onus is on us for ensuring our company's data can out-survive the service provider we choose. 



Here are some rules to take into consideration when choosing a provider: 



1. No Roach Motel

There can never be the scenario where data checks in, but it doesn't check out. Data needs to be able to be programmatically extracted from the remote service. If raw data dumps aren't available, make sure that there's an API that can be utilized which provides a way to access all of the data that you entered, including any important metadata.



2. There needs to be solid Authentication, Access Control, and Accounting 

You use centralized authentication to maintain your users. Use a cloud service that will allow you to automate Moves, Adds, and Changes (MACs) of accounts on their end. Also, ensure that the service uses sufficiently-finely-grained control to company resources, and ensure that when people make changes, those changes are recorded. Too many cloud providers don't offer field-level logging of data, and when a user changes a field maliciously or by accident, it can be difficult or impossible to investigate using their tools. 



3. Don't rely on a service provider with a lesser infrastructure than your own

A chain's only as strong as its weakest link. You use multiple AWS regions. Or maybe multiple data sites. But a bad choice of a SaaS provider can ruin all of your carefully laid plans. Investigate and decide accordingly. 



After finding a suitable service, make good on the requirements that you placed on them. Automate backing up your data from them. Verify that you can parse and use the local data. And develop a disaster recovery plan which involves using that data, then test the plan. The greatest benefit that cloud computing has given us is the near-elimination of the expense of running a disaster recovery site. If you only need to spin up your disaster recovery instances once every quarter to test them, you aren't paying for them the other months of the year. 



Vendor lock-in used to force us to pay annual support contracts that were rarely used. This has changed from insurance payments to protection money, paid to guarantee that our critical services remain on. 



I have never seen a *check_salesforce_invoice* in Nagios, but I can't imagine that it's too far away. Likewise, if you use AWS, you should absolutely be trending and alerting on service charges. In fact, whenever you roll out a new SaaS, spend time determining what business aspects there are in relation to the service, and add those checks to your monitoring. Business decisions now have very real implications for IT infrastructure, and an unpaid invoice can have a worse effect on your company than a hurricane shutting down a cloud provider region. 



None of these tactics are new, just as SaaS isn't new. But more and more businesses constantly move "into the cloud", and new businesses rarely buy their own infrastructures anymore. These things bare repeating from time to time, and I hope that I have helped reiterate some good lessons for people. If you have other suggestions, please put them in the comments below, and thank you for your time.



