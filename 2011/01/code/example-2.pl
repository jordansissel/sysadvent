#!/usr/bin/perl -w

use lib "./lib";
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

