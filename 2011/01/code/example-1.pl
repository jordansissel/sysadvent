#!/usr/bin/perl -w

use lib "./lib";
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
