#!/usr/bin/perl -w

use lib "./lib";
use IPC::System::Simple qw(capture);

my $username = "philiph";
my $command = "lsof";

my @JobResults = capture($command);

print $#JobResults + 1;
print " total files on this system, the following are opened by by $username:\n";
print grep(/^\S+\s+\S+\s+$username/, @JobResults);
