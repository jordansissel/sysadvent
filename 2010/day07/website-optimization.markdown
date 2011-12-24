# Website Performance Optimization

_This article was written by [Bob Feldbauer](http://www.completefusion.com) ([@bobfeldbauer](http://twitter.com/bobfeldbauer))_

Optimizing website performance can dramatically increase conversions and
loyalty, and decrease costs. Although it may be traditionally viewed as a
responsibility of developers, the reality is that sysadmins are also often
asked to work on website performance optimization. 

The following is intended as a busy sysadmin's "crash course" in optimizing
website performance.

As with trying to optimize any process, you should establish a baseline to
measure any changes against. Install the [Firebug](http://getfirebug.com/)
Firefox plugin and Yahoo!'s [YSlow](http://developer.yahoo.com/yslow/) add-on
to measure your initial performance and verify improvements as you make
changes. To see performance changes over time from a consistent external
source, you can use free tools like Pingdom's [Full Page
Test](http://tools.pingdom.com/fpt/) or Octagate's
[SiteTimer](http://www.octagate.com/service/SiteTimer/). Also, [Google's
Webmaster Tools](http://www.google.com/webmasters/tools/) shows optimization
suggestions based on the [Page Speed](http://code.google.com/speed/page-speed/)
tool, and crawl stats for the average time spent downloading a page from your
site.

Yahoo!'s
[research](http://yuiblog.com/blog/2006/11/28/performance-research-part-1/)
shown in the table below shows 62-95% of the time required to load a page is
spent making HTTP requests for non-HTML components like images, scripts, and
stylesheets. See the following table for the time spent loading HTML vs
non-HTML components for popular websites:

<table border="1" cellspacing="0">
  <tr>
    <th> Site </th>
    <th> Time Retrieving HTML </th>
    <th> Time Elsewhere </th>
  </tr>
  
  <tr>
    <td> Yahoo! </td> 
    <td> 10% </td>
    <td> 90% </td>
  </tr>
    <td> Google </td> 
    <td> 25% </td>
    <td> 75% </td>
  </tr>
    <td> MySpace </td> 
    <td> 9% </td>
    <td> 91% </td>
  </tr>
    <td> MSN </td> 
    <td> 5% </td>
    <td> 95% </td>
  </tr>
    <td> eBay </td> 
    <td> 5% </td>
    <td> 95% </td>
  </tr>
    <td> Amazon </td> 
    <td> 38% </td>
    <td> 62% </td>
  </tr>
    <td> YouTube </td> 
    <td> 9% </td>
    <td> 91% </td>
  </tr>
    <td> CNN </td> 
    <td> 15% </td>
    <td> 85% </td>
  </tr>
</table>

As the table indicates, reducing the number of HTTP requests can provide one
of the biggest increases in performance. Aggregating CSS and JavaScript into as
few files as possible and using [CSS
Sprites](http://css-tricks.com/css-sprites/) are two ways to reduce the number
of HTTP requests.


In addition to reducing the number of HTTP requests, being able to load
scripts in parallel instead of serially can improve performance. A newly
developed tool called [Head JS](http://headjs.com/) can be used to load
JavaScript scripts in parallel, while retaining execution order. This allows
scripts to load without blocking other components from loading.

Most sites include static files that change infrequently (CSS, images,
JavaScript, etc) and can benefit from appropriate HTTP caching. See the
Google's Page Speed team's [guide to HTTP caching](http://code.google.com/speed/page-speed/docs/caching.html) for more information.

Another important step in website performance optimization is configuring your
web or application server to deliver gzip compressed content. On [typical
sites](http://www.websiteoptimization.com/speed/18/18-2t.html), gzipping
content reduces text size by 75% and total size by 37%.

In addition to gzip compression, making images, scripts, and CSS files smaller
also helps - especially when loading a site on lower bandwidth connections
like mobile devices. Even if you gzip scripts or CSS files, you can "minify"
them to further reduce their size by 5% or more. Yahoo!'s [YUI
Compressor](http://developer.yahoo.com/yui/compressor/)
can minify both CSS and JavaScript, while Yahoo's
[Smush.it](http://www.smushit.com) can optimize image sizes without losing
quality.

Although there are many other things you can do to optimize website
performance, this "crash course" in optimization should get you started.

Further reading:

  1. [Yahoo!'s Exceptional Performance team's](http://developer.yahoo.com/performance/index.html)
  2. [Web Performance Best Practices](http://code.google.com/speed/page-speed/docs/rules_intro.html) by Google's Page Speed team



