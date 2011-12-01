#!/usr/bin/perl -w

use lib "./lib";
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

