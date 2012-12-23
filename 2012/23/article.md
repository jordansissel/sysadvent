# Down and Dirty Log File Filtering with Perl

This was written by [Phil Hollenback](http://www.twitter.com/philiph) 
([www.hollenback.net](http://www.hollenback.net))

## Here We Go Again

Say you have a big long logfile on some server somewhere and a need to
analyze that file.  You want to throw away all the regular boring
stuff in the logfile and just print lines that look suspicious.
Further, if you find certain critical keywords, you want to flag those
lines as being extra suspicious. It would also be nice if this was
just one little self-contained script.  How are you going to do that?

Sure, I know right now you are thinking "hey Phil just use a real tool
like logstash, ok?"  Unfortunately, I'm not very good at following
directions, so I decided to implement this little project with my
favorite tool: Perl.  This post will shed some light on how I designed the
script and how you could do something similar yourself.

## Requirements and Tools

This whole thing was a real project I worked on in 2012.  My team
generated lots of ~10,000 line system install logs.  We
needed a way to quickly analyze those logs after each install.

This tool didn't need to be particularly fast, but it did need to be
relatively self-contained.  It was fine if analyzing a logfile took 30
seconds, since these logfiles were only being generated at the rate of
one every few hours.

For development and deployment convenience, I decided to embed the
configuration in the script.  That way I didn't have to deal with updating both
the script and the config files separately.  I did decide however to try to do
this in a modular way so I could later separate the logic and config if needed.

I had been previously playing with embedding data in my perl scripts through
use of the
[__DATA__ section](https://www.socialtext.net/perl5/data) so I wanted
to use that approach for this script.  However, that presented a
problem: I knew I wanted three separate configuration sections (I will
explain that later). This meant that I would have to do something to
split the `__DATA__` section of my file in to pieces with keywords or
markers.

Naturally, I found a lazy way to do this: the
[Inline::Files](http://search.cpan.org/~ambs/Inline-Files-0.68/lib/Inline/Files.pm)
perl module.  This module gives you the ability to define multiple
data sections in your script, and each section can be read as a
regular file.  Perfect for my needs.

## Reading the Logfile

The first step in this script is to read in the logfile data.  As I
mentioned, it's around 10,000 lines at most, not a staggering
amount.  This is a small enough number that you don't need to worry
about memory constraints - just read the whole file in to memory.
With that, here's the beginning of the script:

    #!/usr/bin/perl

    use warnings;
    use strict;
    use Inline::Files;

    my $DEBUG = 0;
    my @LOGFILE = ();
    my (@CRITICAL, @WARN, @IGNORE);
    my (@CriticalList, @WarnList);

    while(<>)
    {
      # skip comments
      next if /^#/;
      push(@LOGFILE, split("\n"));
    }

What does that all do?  Well of course the first few lines set up our
initial environment and load modules.  Then I define a LOGFILE
variable.  Finally the while loop uses the magic `<>` operator to take
input lines from either STDIN or from any file specified on the
command line.

Inside the while loop the combination of `shift` and `push` converts
each line of input text into an array entry.  At the end of this whole
thing I've got an array `@LOGFILE` which contains the logfile data.
As I mentioned, this works just fine for logfiles which aren't enormous.

## Reading the Data

Next, I want to create arrays for three sorts of matches.  First, I
need a list of matches which we should warn about.
Second, I need a list of matches that we ignore.  The third list is a
list of critical errors that I always want to flag no matter what.

The idea here is that the first list of matches is the broadest, and
is intended to catch all possible anomalies.  For example, the word
'error' is caught by the warn list.

The second list is more discriminatory, and acts to filter the first
list.  Any time a match is found on the warn list, it's checked
against the ignore list and discarded if a match is found.  Thus, the
line

    this is a spurious warning

is initially flagged by the warn list.  However, the ignore list
includes a match for 'spurious warning' so ultimately this line gets
suppressed as we know it's spurious.

The final list short circuits the entire process - if any match is
found on the critical list, no checking of the warn or ignore lists is
done.  This list is intended for only specific critical failures and
nothing else.  That way we can invoke a special code path for the
worst problems and do things like exit with a non-zero value.

Remember that we are using `Inline::Files` so we can treat sections of
the script as data files.  Here's the end of the script that can be used to
configure the run:

    __DATA__
    # nothing after this line is executed
    __CRITICAL__
    # everything in this section will go in the critical array
    .*File.* is already owned by active package
    __IGNORE__
    # everything in this section will go in the ignore array
    warning: unable to chdir
    set warn=on
    __WARN__
    # everything in this section will go in the warn array
    error
    fail
    warn

We can now treat CRITICAL, WARN, and IGNORE as regular files and open
them for reading like so:

    open CRITICAL or die $!;
    while(<CRITICAL>)
    {
      next if /^#/; #ignore comments
      chomp;
      push @CRITICAL, $_;
    }
    close CRITICAL;

Repeat for WARN and IGNORE.  We now have three arrays of matches to
evaluate against the logfile array.

## Pruning the Logs

Now, we need to act on the log data.  The simplest way to do this is with a
bunch of `for` loops.  This actually works just fine with 10,000 line logfiles
and a few dozen matches.  However, let's try to be slightly more clever and
optimize (prematurely?).  We can compile all the regexes so we don't have to
evaluate them every time:

    my @CompiledCritical = map { qr{$_} } @Critical;
    my @CompiledWarn = map { qr{$_} } @Warn;
    my @CompiledIgnore = map { qr{$_} } @Ignore;

then we loop through all the logfile output and apply the three
matches to it.  We use a label called `OUTER` to make it easy to jump
out of the loop at any time and skip further processing.

    OUTER: foreach my $LogLine (@LOGFILE)
    {
      # See if we found any critical errors
      foreach my $CriticalLine (@CompiledCritical)
      {
        if ($LogLine =~ /$CriticalLine/)
        {
          push @CriticalList, $LogLine;
          next OUTER;
        }
      }
      # Any warning matches?
      foreach my $WarnLine (@CompiledWarn)
      {
        if ($LogLine =~ /$WarnLine/i)
        {
          # see if suppressed by an IGNORE line
          foreach my $IgnoreLine (@CompiledIgnore)
          {
            if ($LogLine =~ /$IgnoreLine/)
            {
              # IGNORE suppresses WARN
              next OUTER;
            }
          }
          # ok, the warning was not suppressed by IGNORE
          push @WarnList, $LogLine;
          next OUTER;
        }
      }
    }

## Output the Results

With that, the script is essentially complete.  All that remains of
course is outputting the results.  The simplest way to do that is to
loop through the CRITICAL and WARN arrays:

    if (@CriticalList)
    {
      print "Critical Errors Found!\n";

      while(my $line = shift @CriticalList)
      {
        print $line . "\n";
      }
      print "\n";
    }

    if (@WarnList)
    {
      print "Suspicious Output Found!\n";

      while(my $line = shift @WarnList)
      {
        print $line . "\n";
      }
      print "\n";
    }

Assuming a logfile like this:

    1 this is a warning: unable to chdir which will be suppressed
    2 this is an error which will be flagged
    3 set warn=on
    4 this is superfluous
    5 set warn=off
    6 looks like File foobar is already owned by active package baz

the script outputs the following:

    $ scan.pl log.txt
    Critical Errors Found!
    6 looks like File foobar is already owned by active package baz

    Suspicious Output Found!
    2 this is an error which will be flagged
    5 set warn=off

The end result is exactly what we want - a concise list of
problematic log lines.

## Conclusion

This is a pretty simple example, but hopefully, it gives you
some ideas to play with.  As I said in the beginning, I realize that
there are lots and lots of other more clever ways to go about this
sort of log analysis.  I won't claim that this is even a particularly smart way
to go about things.  What I can tell you is that a variation on this script
solved a particular problem for me, and it solved the problem very well.

The thing I'm really trying to illustrate here is that scripting isn't
that hard.  If you are a sysadmin you absolutely must be comfortable
with scripting.  I prefer perl, but rumor has it, there are some other
scripting languages out there.  If you have the ability to throw together a
script you can quickly and easily automate most of your daily tasks.  This is
not just theory.  I used to review multiple 10,000 line install logfiles by
hand.  Now I don't have to do anything but look at the occasional line that the
script flags.  I freed up a couple hours a week with this approach and I
encourage all of you to take the same approach if you aren't already.

## Further Reading

* A [perlmonks discussion about line by line matching](http://www.perlmonks.org/?node_id=661292).
