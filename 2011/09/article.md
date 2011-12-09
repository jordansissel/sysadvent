# Day 9 - Data in the Shell

This was written by [Jordan Sissel](http://twitter.com/jordansissel)
([semicomplete.com](http://semicomplete.com)).

The shell is where I live most days, and the shell has pipes. Pipes simply
transmit plain text, and many pieces of data I deal with are structured data
where staples like grep and sed are not the best.

Fortunately, there are lots of tools available to help you deal with these
structured formats.

## Delimited Data

I'll start with data you're probably already familiar with, simple text
delimited by some characters like spaces or commas. The general tools used
here are awk and cut. I often want to get some simple stats using awk, so I
keep some handy shell functions to help me do sums and counts by field.

    function _awk_col() {
      echo "$1" | egrep -v '^[0-9]+$' || echo "\$$1"
    }

    function sum() {
      [ "${1#-F}" != "$1" ] && SP=${1} && shift
      [ "$#" -eq 0 ] && set -- 0
      key="$(_awk_col "$1")"
      awk $SP "{ x+=$key } END { printf(\"%d\n\", x) }"
    }

    function sumby() {
      [ "${1#-F}" != "$1" ] && SP=${1} && shift
      [ "$#" -lt 0 ] && set -- 0 1
      key="$(_awk_col "$1")"
      val="$(_awk_col "$2")"
      awk $SP "{ a[$key] += $val } END { for (i in a) { printf(\"%d %s\\n\", a[i], i) } }"
    }

    function countby() {
      [ "${1#-F}" != "$1" ] && SP=${1} && shift
      [ "$#" -eq 0 ] && set -- 0
      key="$(_awk_col "$1")"
      awk $SP "{ a[$key]++ } END { for (i in a) { printf(\"%d %s\\n\", a[i], i) } }"
    }

It's not exactly pretty, but it lets me do things like this:

    # Simply sum the first field
    % seq 10 | sum 1
    55

    # Sum one field grouping by another
    % printf "hello:1\nworld:1\nworld:3\n" |sumby -F: 1 2
    4 world
    1 hello

    # Count instances by field
    % printf "hello:1\nworld:1\nworld:3\n" | countby -F: 1
    2 world
    1 hello

### fex

Over the years, I've found awk to be useful for some cases, but the majority
of my uses of cut (with cut -d) and awk were essentially setting the field
separator and picking out a few fields. I wanted something with better syntax to
solve some more complex field selection problems, so I wrote a tool called
[fex](http://semicomplete.com/projects/fex/).

The best example I can give of fex's power is by chopping up an apache log
entry:

    echo '208.36.144.8 - - [22/Aug/2007:23:39:05 -0400] "GET /hello/world HTTP/1.0" 200 3595' \
      | fex 1 '"2 2'
    208.36.144.8 /hello/world

The above asks for two values, the client ip and the request path. The first
field (default delimiter is space) and the 2nd field (delimited by
doublequote), then inside that the 2nd field by space. I believe this 
tight syntax is still readable while being expressive enough to get most field
splitting and selections done. Doing the same thing in awk (or worse, cut)
would require much more effort to capture.

## Structured Data

Awk, cut, and fex are useful, but there are better tools to use when dealing
with structured data formats.

## JSON

Lots of web APIs speak JSON these days, so there's an increasing likelihood
that you will have to mangle it on the command line at some point

For this format, I use [jgrep](https://github.com/psy1337/JSON-Grep) to search
json data.

Let's use it to look for github public gists with comments:

    % curl -s https://api.github.com/gists | jgrep 'comments>0' -s url     
    https://api.github.com/gists/1450770
    https://api.github.com/gists/1450726

Boom, only seeing gist urls with comments.

## XML

Lots of programs use XML for configuration and data transport, so it is helpful
to have a tool you can use to quickly poke at this data format.

Many of the tools in this area use a language called XPath, which I originally
learned from [here](http://zvon.org/xxl/XPathTutorial/General/examples.html).
The XPath language is in most cases fairly simple to learn. The other language
you will likely see in these XML processing tools is XSLT, but that is a bit
outside the scope of this article.

Tool: [xmlstarlet](http://xmlstar.sourceforge.net/)

Data: Hadoop [core-default.xml](https://github.com/jordansissel/sysadvent/blob/master/2011/09/code/core-default.xml

    # Get all the properties set in this file:
    % xmlstarlet sel -t -v '/configuration/property/name' core-default.xml

    # The above can also be written:
    % xmlstarlet sel -t -v '//name' core-default.xml
    hadoop.common.configuration.version
    hadoop.tmp.dir
    io.native.lib.available
    ...

    # Read the 'hadoop.tmp.dir' property:
    % xmlstarlet sel -t -v '//property[name/text() = "hadoop.tmp.dir"]/value' *.xml  
    /tmp/hadoop-${user.name}

This kind of thing is very useful when you need to feed other tools from data
in xml config files (like monitoring settings, etc)

## CSV

In most cases, awk, cut, or fex will be sufficient in dealing with CSV or other
delimited format files. There are edge cases in CSV (like quoting) that
make using normal delimiter tools insufficient.

In this case, there's nicely a whole suite of tools for mangling CSV data, csvkit:

Tool: [csvkit](https://github.com/onyxfish/csvkit)

csvkit comes with tools to cut, grep, sort, and more to csv data sets.

For a fun example, let's look outside the sysadmin world at some UK Government
data on [mergers and
acquisitions](http://www.ons.gov.uk/ons/rel/international-transactions/mergers-and-acquisitions-involving-uk-companies/q3-2011/dd-am-dataset.html).

After downloading the
[csv](http://www.ons.gov.uk/ons/datasets-and-tables/downloads/csv.csv?dataset=am)
data, let's get some stats on quarterly domestic acquisitions (listed as code
AIHA in the csv data):

First, since there's both yearly and quarterly data, we'll need to grep for only quarterly data, second we'll want to get stats on column 2 (AIHA):

    % python csvgrep -c 1 -r ".*Q[1-4]" AM_CSDB_DS.csdb.csv | python csvstat -c 2            
      2. AIHA
            <type 'int'>
            Nulls: No
            Min: 56
            Max: 464
            Sum: 27967
            Mean: 164
            Median: 140.5
            Unique values: 116
            5 most frequent values:
                    120:    5
                    139:    4
                    148:    4
                    124:    3
                    88:     3

    Row count: 170

    # What quarter had 464 acquisitions?
    % python csvgrep -c 2 -r '^464$' AM_CSDB_DS.csdb.csv  | python csvcut -c 1
    1988 Q3

    # What quarter had only 56?
    % python csvgrep -c 2 -r '^56$' AM_CSDB_DS.csdb.csv  | python csvcut -c 1
    1975 Q1

This tool is pretty slick. As a tip, if csvkit has features you like (column
selection/grep, stats, etc), remember that if your data set is not already in
csv, it might be easy to convert to csv for use with csvkit.

## Parting Thoughts

Sysadmins are often required to deal with multiple systems that speak different
languages - one might log in plain text, another expose data over a HTTP API
and send JSON, etc. 

You're not alone, and having the right data mangling tools in your toolbox will
help you answer the right questions faster without spending energy fighting with
data formats. This lets you be more effective, and have more time at the pub with
friends, at home with the family, or wherever you happen to find happiness.

## Further Reading

* [good coverage of jgrep](http://www.devco.net/archives/2011/07/29/rich-data-on-the-cli.php) and
  reasons why it was created.
* [csvkit docs](http://csvkit.readthedocs.org/en/latest/index.html) which are excellent
* [Week of Unix Tools - Day 3: awk](http://semicomplete.com/blog/articles/week-of-unix-tools/day-3-awk.html)
