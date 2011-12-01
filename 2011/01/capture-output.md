# Don't bash your process outputs

This article was written by [Phil Hollenback](http://www.twitter.com/philiph) 
([www.hollenback.net](http://www.hollenback.net))

## The Problem

Like most veteran bash scripters, I have a tendency to abuse shell
scripting.  In particular, I often fall in to the trap of collecting
and manipulating process output.  This works fine for the simple case
of one or two lines of stdout, but falls down horribly for complex
cases.  Pretty soon a simple

    output=`some_command`

turns in to a huge conditional block where you have to check exit
codes, redirect stderr in to temporary files, and generally hate
yourself.

## Welcome to Perl

I should warn you from the start: I've got a secret agenda.  My goal
is to convince all sysadmins to ditch the bash scripts and use perl
instead.  With perl you get both the ubiquity of shell scripting and
access to a rich data manipulation environment.

Unfortunately, the default perl backtick mechanism for capturing
process output isn't a whole lot better than what you get with bash.
The good news is that thanks to the [CPAN](http://www.cpan.org), there are many
ways to deal with gathering process input.  I'll cover two here:
[IO::CaptureOutput](http://search.cpan.org/~dagolden/IO-CaptureOutput-1.1102/lib/IO/CaptureOutput.pod)
and
[IPC::System::Simple](http://search.cpan.org/~pjf/IPC-System-Simple-1.21/lib/IPC/System/Simple.pm).
There's some overlap between these two modules but I find I often end
up using them both for different tasks.  In particular,
IO::CaptureOutput is best if you need to deal with both STDERR and
STDOUT, and IPC::System::Simple is best if you just need something
friendlier than the default perl `system` call or backticks operator.

## IO::CaptureOutput

IO::CaptureOutput is the more comprehensive solution to the problem of
capturing output and determining whether the external process ran
correctly.  Here's how I typically use it:

    #!/usr/bin/perl -w
    use IO::CaptureOutput qw/capture_exec/;

    my ($JobStdout, $JobStderr, $JobSuccess, $JobExitCode) =
             capture_exec("my_command");
    if ( ! $JobSuccess )
    {
        print "my_command failed with exit code " . ($JobExitCode >> 8);
        print " and printed on stderr:\n";
        print $JobStderr;
        die;
    }

    my @JobResults = split(/^/,$JobStdout);

    my $number = 1;
    foreach my $line (@JobResults) {
      print "$number: $line"
    }

This provides a comprehensive record of what happened when you ran
`my_command` and is appropriate if any failure is grounds for
terminating your script.  Note that it also preserves and outputs stderr in
case of failure, which is a friendly touch.

After running `capture_exec` this way, every line of your external
command output is sitting there in the array `@JobResults`, ready for
further processing.  For example, you could do this next to remove
beginning line numbers from your output:

    # perl arrays are always references so this is in-place
    # editing!
    map { s/^\s*\d+\s// } @JobResults;

Or, say you wanted to print all the non-comment lines from the output:

    print grep(!/^#/, @JobResults);

Another problem that capture_exec solves nicely is the issue of
external commands that print failures to stderr but then return a
successful exit code.  To trap this, check the contents of `$JobStderr`:

    #!/usr/bin/perl -w
    use IO::CaptureOutput qw/capture_exec/;
    use List::Util qw/first/;

    my $command = "echo hello world and some error text";
    my ($JobStdout, $JobStderr, $JobSuccess, $JobExitCode) =
            capture_exec($command);
    my @JobResults = split(/^/,$JobStdout);

    if ( first { /some error text/ } @JobResults )
    {
        # found an occurence of the error text
        print "'$command' command failed";
        print " and printed on stderr:\n";
        print $JobStderr;
        die;
    }

Let's put that all together in a trivial data munging script that calls
`lsof`(1) and finds all the open files from processes owned by my user:

    use IO::CaptureOutput qw/capture_exec/;
    my $username = "philiph";
    my $command = "lsof";

    my ($JobStdout, $JobStderr, $JobSuccess, $JobExitCode) =
        capture_exec($command);
    if ( ! $JobSuccess )
    {
        print "$command failed with exit code " . ($JobExitCode >> 8);
        print " and printed on stderr:\n";
        print $JobStderr;
        die;
    }
    # split lines in to an array
    my @JobResults = split(/^/,$JobStdout);

    print $#JobResults + 1;
    print " total open files on the system, here's what is owned by $username:\n";
    print grep(/^\S+\s+\S+\s+$username/, @JobResults);


That will print something like this:

    1687 processes owned by philiph:
    loginwind    47 philiph  cwd      DIR       14,2       1530        2 /
    loginwind    47 philiph  txt      REG       14,2    1754160  3902953 blah
    loginwind    47 philiph  txt      REG       14,2     113744    35203 foo
    loginwind    47 philiph  txt      REG       14,2     425504 14968261 quux
    ..etc..

The power of IO::CaptureOutput is that it provides a consistent way to
capture stderr, stdout, and the return code when calling an external
process.  In turn that makes it trivially easy to transform the
process output into an array and perform operations on that array.

## IPC::System::Simple

If you don't actually care about separately capturing the stdout,
stderr and exit value from a process then IO::CaptureOutput is a bit
of a heavyweight.  Instead, for the ultimate in simplicity you should
look at IPC::System::Simple.  This CPAN module provides a number of
extremely convenient replacements for the perl system and backticks
operators.  For example, if you just want to run a process and die on
failure, you can do this:

    use IPC::System::Simple qw(system);
    system("my_program");

That's it.  If anything goes wrong with calling `my_program`, this
replacement for the perl system builtin will just call die to exit
your script with a descriptive error message.  Of course, you can
always catch the exception instead of just die()ing.  The big
advantage of this version of `system` is it prints much more
descriptive messages on exit, including the real return code.

This module also includes a `capture` function which is a replacement
for the default backticks operator in perl.  It works similarly to
IO::CaptureOutput `capture_exec`, although note you can only capture
STDOUT, not STDERR.  If you don't care at all about STDERR you could
make my earlier example much simpler:

    #!/usr/bin/perl -w
    use IPC::System::Simple qw(capture);

    my $username = "philiph";
    my $command = "lsof";

    my @JobResults = capture($command);

    print $#JobResults + 1;
    print " total files on this system, the following are opened by by $username:\n";
    print grep(/^\S+\s+\S+\s+$username/, @JobResults);

If anything goes wrong, IPC::System::Simple will just bomb out with a
descriptive message, _and_ set an appropriate exit value
automatically.  This saves you from having to bit shift the system
result codes to figure out what the hell actually happened.  An
illustration:

    # the standard way
    my $command = "crontab -l -u root";
    system("$command") == 0 or die "$command failed: $?";

if you aren't running as root, this produces the following baffling error:

    crontab: must be privileged to use -u
    crontab -l -u root failed: 256 at /tmp/test.pl line 6.

that '256' actually has to be bitshifted (`$?>>8`) to get the real
exit value, which is 1.  Also, you have to remember to manually call
die on a non-zero return from the default perl `system` function.

If you replace the default system fucntion with the
IPC::System::Simple one, that is all taken care of automatically:

    # Replace system with IPC::System::Simple
    use IPC::System::Simple qw(system);
    my $command = "crontab -l -u root";
    system("$command");

this time you get the real failure:

    crontab: must be privileged to use -u
    "crontab -l -u root" unexpectedly returned exit value 1 at /tmp/test.pl line 6

And you don't even have to remember to call die! Of course, you can
trap the failure in an eval block if you don't want your script to
die.

As a further refinement, say you know that there is a list of exit
codes that are acceptable when calling an external process.
IPC::System::Simple has a shorthand for that:

    # Replace system with IPC::System::Simple
    use IPC::System::Simple qw(system);
    my $command = "crontab -l -u root";
    # return codes 0 or 1 are acceptable
    system([0,1], "$command");

Now, the script will continue on past the system call as long as it returns an
exit code of 0 or 1.  Otherwise it will die with a descriptive error message
the same way as before.

## Conclusion

Dealing with process output in bash scripts is hard! Doing it correctly and
safely can quickly end up with you shaving yaks.

Stock perl with the system function and backtick operator is an improvement.
You gain access to perl's rich data manipulation features, but you still have
to do unpleasant things like bitshifts to determine the real process exit code.

As usual, CPAN comes to the rescue.  If you just want to replace system or
backticks with more convenient functions, IPC::System::Simple is an excellent
choice.  If you want to capture all of STDOUT, STDERR, and the process return
code, then IO::CaptureOutput is the way to go.  Also, note that these modules
are portable across unix, mac, and windows.

## Further Reading

* A StackOverflow post that [discusses capturing stdout and stderr in
perl](http://stackoverflow.com/questions/109124/how-do-you-capture-stderr-stdout-and-the-exit-code-all-at-once-in-perl).
* [Capturing stdout, stderr, and exit code in Perl](http://www.perlmonks.org/?node_id=454715) from Perl Monks.
* [Subprocess output and more in Python](http://docs.python.org/library/subprocess.html)
* [Subprocess output and more in Ruby](http://ruby-doc.org/stdlib-1.9.3/libdoc/open3/rdoc/Open3.html)
* [Subprocess output and more in PHP](http://php.net/manual/en/function.proc-open.php)
