# Day 21 - Automating Web Monitoring

This article is written by [Brandon Burton](http://www.inatree.org), who can
mostly be found posting lolcats and retweeting 
[@solarce](http://www.twitter.com/solarce), though he occasionally posts
interesting links to things sysadmin, devops, and unix.

As systems administrators, we all know that [it's not in production until it's
monitored](https://twitter.com/#!/griggheo/status/62239661568958464), but this
isn't always as simple a rule to live by as it may sound.  Not all web
applications, for example, are easily monitored through traditional monitoring
solutions such as Nagios, Zenoss, or various commercial tools.  These tools
tend to take a "curl | grep" style monitoring, or they may support somewhat
more complex POSTing of XML or JSON data and validation of the returned data.
But often the most key parts of applications being deployed into production
involve complex browser interactions and behaviors - AJAX, or some other
session or transaction that traditional monitoring frameworks don't have an
easy way to accommodate.

Enter [Selenium](http://seleniumhq.org/).
[Selenium](http://en.wikipedia.org/wiki/Selenium_%28software%29) is a mature
and robust framework for doing complex interactions with web applications. It
originated as a tool at the consulting company ThoughtWorks as a way to do
testing against web applications by driving a web browser. Since its release,
it has seen the development of numerous tools, including browser plugins to
make it easy to develop Selenium tests quickly and easily, language bindings to
write tests in pretty much every major language, and tools to run many browsers
across many operating systems, in parallel. 

Additionally, services, such as [BrowserMob](http://www.browsermob.com) and
[Sauce Labs](http://www.saucelabs.com), have grown around the Selenium
ecosystem to help you do testing and monitoring in a scalable and offsite
fashion. It is these services that we'll focus on utilizing in this blog post.

So what does all this mean? It means that we have a mature and robust toolset
that we can utilize and perform testing and monitoring of the complex web
applications that we are deploying into production.

## Getting started

So how do we get started? My preferred method is to begin by developing tests
locally. You can use the [Selenium IDE](http://seleniumhq.org/projects/ide/), but
for this example I'll show a Firefox extension called [Sauce
Builder](http://saucelabs.com/docs/builder) which makes it a snap to build and
run your first test locally.

To get started you'll need Firefox installed, then go to the [Sauce Builder
download
page](https://addons.mozilla.org/en-US/firefox/addon/sauce-builder/?src=search)
and walk through getting the extension installed.

Once you've got the Sauce Builder extension installed, it is time to build our
first test.

I'm going to walk you through building a test to search for jelly beans on
[Amazon](http://www.amazon.com).

1. Open Firefox
2. Click on Tools -> Sauce Builder
3. Enter ''amazon.com'' in the Start Record prompt and click Go
4. Enter ''jelly beans'' for the search term
5. Click Go
6. Click on the first search result, for me this was '''Kirkland Signature
   Jelly Belly Jelly Beans 49 Flavors (4 Lbs)'''
7. Go back to the Sauce Builder window and click Stop recording.
8. Now that we've recorded a test, we should save it for safe keeping. Click
   File -> Save or Export -> Choose HTML as the format and name it, then click
   Save.

As you can see from the test we've recorded. The test is composed of a series
of actions and each action will have one or more options associated with it.

[Here is a short video of recording your first test](http://www.screencast.com/t/ufRm1SfMbEo)

Digging into how to modify and adapt tests is beyond the scope of what I want
to cover in this post, but the following links are some good places to go
deeper:

* [Sauce Builder documentation](http://saucelabs.com/docs/builder)
* [Selenium Docs - Test Design Considerations](http://seleniumhq.org/docs/06_test_design_considerations.html)
* [Selenium Docs - Selenium IDE - Building Test Cases](http://seleniumhq.org/docs/02_selenium_ide.html#building-test-cases)

Now that we've recorded our first test, it is time to run it. 

1. Click on Run and choose Run test locally. 
2. The test will begin running in the currently selected tab in Firefox. 
3. Obviously this is a pretty simple test and you could do a lot more with it,
   including go through adding it to a cart, checking out, and buying the
   order. But for the purposes of getting started, it's a good place to stop.

[Here is a video of running your first test](http://www.screencast.com/t/2bQlCLPKUGOr)

The next thing we want to do, since our focus is on monitoring, is add some
verification steps to each page load. This step is crucial in making our test
doing the same kind of checking that your traditional `curl URL | grep STRING`
style monitoring did, but now it's integrated into our browser-driven mode of
execution.

1. Go to the Sauce Builder window
2. Mouse over the second step and choose New step below
3. Select the new step
4. Choose edit action
5. Select the assertion option
6. Choose page content
7. Choose assertText
8. Click Ok
9. Choose locator and enter ''link=Your Amazon.com'
10. Click Ok
11. Choose equal to and enter the string ''Your Amazon.com''
10. Click Ok
11. Click on Run and Run test locally

The test should run successfully, if it does not, then you may want to click on
`locator` and choose `Find a different Target` and use the tool to select the
element you're asserting text with. 

This is a critical step as the assertions are somewhat brittle and must be
maintained as your application changes over time. For more details, see [help
on choosing good
locators](http://release.seleniumhq.org/selenium-core/1.0/reference.html).

[Here is a video of adding the assertion to your test and running it
locally](http://www.screencast.com/t/JIQnnbD6MX)

## Using Sauce Labs for Testing

Now that you've gotten your test running locally and you've added some
assertions to make the test useful for monitoring, it is a good idea to run the
test externally. As previously mentioned, the [Sauce
Labs](http://www.saucelabs.com/) folks run a service to run your tests in the
*Cloud*, and they are nice enough to offer a free plan that gives you 200
"execution" minutes per month and the ability to run your tests under multiple
browsers and operating systems with ease. Plus you'll get your jobs stored,
logs, screenshots, and a video recorded of the whole test for later review and
analysis. So now that you're thinking "where do I sign up?!"

To sign up for the free plan, do the following.

1. Go to [https://saucelabs.com/signup](https://saucelabs.com/signup)
2. Enter a username
3. Enter your email address
4. Enter a password
5. Click Sign Me Up

Now configure your Sauce Builder installation to use your free account

1. Login to https://saucelabs.com/ and click on View My API key
2. Copy your API key
3. In your test, choose Run -> Run on Sauce OnDemand
4. Leave the default Linux - Firefox 3.0
4. Click Run
5. When prompted if you have a Sauce Labs account, choose Yes
6. Enter your username and API key
7. Choose Save
8. Your test will start running. Grab a snickers.
9. You'll end up with a Job URL that looks something like https://saucelabs.com/jobs/6f4629f04dad85cd7803d8049ec00888 (which I've made public, since there is nothing private in it.)
10. Review the details of the test, as you can see, you get the following for each test
 * Platform
 * Start and End Times
 * Duration
 * Status
 * Break down of each Selenium command that's executed
 * Screenshot of the final page of the test
 * Video recording of the whole test run.

At this point you've successfully executed a test on Sauce Labs. I recommend you review the following to get a full idea of Sauce Labs features, which includes being able to use it programmatically from various languages, which is beyond the scope of what I'm covering this post.

* [Sauce Labs - FAQ](https://saucelabs.com/tech-resources)
* [Sauce Labs - Supported Browsers](https://saucelabs.com/docs/ondemand/browsers/env/ruby/se2/mac)
* [Sauce Labs - Additional Config Options](https://saucelabs.com/docs/ondemand/additional-config)
* [Sauce Labs - REST API](https://saucelabs.com/docs/saucerest)

# Using BrowserMob for monitoring #

So you've succeeded in getting your test run locally, you've run it externally
in the "Cloud", and now you're thinking "wasn't I promised I could use this for
monitoring?". Yes, you were, and that's where
[BrowserMob](http://www.browsermob.com/) comes in. 

While BrowserMob's primary product is focused on load testing, they've also
built a great [monitoring
product](https://browsermob.com/website-monitoring-features) and that's what
we'll using to get our monitoring up and running. 

BrowserMob is kind enough to offer a free plan, so let's start with getting signed up.

To sign up for the free plan, do the following.

1. Go to [https://browsermob.com/website-monitoring-load-testing-signup](https://browsermob.com/website-monitoring-load-testing-signup)
2. Enter all the required info.
3. Click Sign Up
4. Complete the email verification.
5. You're done.

Now upload and verify your first test.

1. Go to [https://browsermob.com/account/overview](https://browsermob.com/account/overview)
2. Click on Scripts
3. Click on Upload Selenium Browser Script
4. Give it a Name
5. Click Browser, locate your test file you saved from Sauce Builder
6. Click on Upload
7. It should automatically validate.
8. If it passes validation, you should then see Revalidate, View Log, and Screenshot links
9. Check out the log and screenshot to get an idea of what will be recorded for each monitoring test run.

[Here is a short video showing  uploading and verifying your first test](http://www.screencast.com/t/fmt9oswX)

Let's configure an email address for notifications

1. Click on Monitoring
2. Clic on Notifications
3. Click on [create one](https://browsermob.com/monitoring/create-notification-preferences)
4. Enter a name
5. Confirm the contact name and email, it will default to what you registered with
6. Click Create

Now let's set up a monitoring job.

1. Click on Monitoring
2. Click on Schedule
3. Give the job a name
4. Select a Frequency * With the free account, you can run a simple test every
   12 hours, for higher frequency or more complicated tests, you'll need to
   [purchase](https://browsermob.com/website-monitoring-pricing) a paid
   account.
5. If you want to do an alert, click create
6. Select a location
7. Select your notification preference
8. Click Activate Now
9. The job will be scheduled and will run at the next internal after the minute
   the job was created.
10. Since you just signed up for a trial, you can get the test to run a bit
    sooner, but only a couple times, so we'll do that now, so we can see what
    it looks like.
11. Click Edit next to the test
12. Change Frequency to 10 minutes
13. Click Save and Activate
14. Set a timer for 12 minutes and wait, once it is done, we'll review what
    things look like.  * Once you're done with this, you may want to revert to
    every 12 hours so that when you're trial expires you won't be over your
    credits, or just pause/delete the monitoring job.

[Here is a video of creating the monitoring job](http://www.screencast.com/t/vpkz9XepvrYn)

So now that that test has run, let's take a look at what it looks like.

1. Click on Dashboard
2. Mouse over the name of the job and click on the URL, it should look like
   something like this: https://browsermob.com/monitoring/view/{some_id_here}
3. You should see a chart that defaults to 1 day and shows you each test, with
   a bar showing each data point, based on the overall time it took to run the
   test.  * This gives you some quick insight to how performance (as measured
   by execution time) is doing over time.
4. You can drill into each data point, and you'll get a waterfall style break
   down of each test run: how long each element of the page took to load, etc.

Below is a screenshot of a test that has run for a few days.

<div class="thumbnail"><a href="https://skitch.com/solarce/g1kjc/view-monitoring-job-browsermob"><img src="https://img.skitch.com/20111219-dhh47y4pg9gr8bdmi74dispkbb.preview.png" alt="View Monitoring Job | BrowserMob" /></a><br /></div>

So a couple tips on how you can use custom stuff from BrowserMob's API to make
your tests that much more effective.

### Setting variables.

Since the BrowserMob scripts are written in JavaScript, doing variables is as
simple as doing `var zipcode = '90210'`

### Getting back data from a webpage. 

I've only ever used this to get back the whole response from a page and use it
as is, so you'd need to break out a bit of your own JS-fu if you want to use
part of a response, but here's how I did it. The code below also shows using a
previously declared variable in your request.

    var response = c.get("http://api.example.com:8080/id?"+zipcode)
    var testid = response.getBody()

At this point the `testid` variable contains the string returned in the
response from the request to
[http://api.example.com:8080/id?90210](http://api.example.com:8080/id?90210)

### Extra Logging

BrowserMob's JS API has a nice function called `browserMob.log()` which lets
you log arbitrary data and it will show up in the raw logs that BrowserMob
keeps for each test run. An example of this is

    browserMob.beginStep("Step 2");
    selenium.waitForPageToLoad(60000);
    selenium.type("id=twotabsearchtextbox", "jelly beans");
    browserMob.log('searched for jelly beans')
    browserMob.endStep();

For more info on these and more functions, check out the [BrowserMob API
Documentation](http://static.browsermob.com/api/)

## What Next?

At this point you've successfully built a test, run it locally, run it in the
"cloud", and deployed it to monitor every 12 hours and are getting alerted by
email, you're wondering what's next.

Well, amongst the things you could would would be

1. [Load Testing](https://browsermob.com/website-load-testing) through
   BrowserMob
2. Get called or pager by sending your email alerts into
   [PagerDuty](http://www.pagerduty.com)
3. Interact with your own web services by using the ''getting data back''
   example from above

I've made a [github
repository](https://github.com/solarce/sysadvent_2011_examples) with my
Amazon.com example. 

As a challenge and a way to motivate people to contribute and give feedback,
the 5 most interesting tests that people submit as pull requests on Github, I
will send them a package of stickers, including SysAdvent, Github, Riak, and
more!

I hope you've found this post to be informative and would love feedback via
email or Twitter on how you do end up using any or all of the services in this
post.
