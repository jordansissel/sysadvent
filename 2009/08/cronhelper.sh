#!/bin/bash
# cronhelper.sh
# Author: Jordan Sissel
# License: BSD
#
# usage: cronhelper.sh <command [arg1 ...]>

# You should set the following environment variables:
# SLEEPYSTART - sleeps at startup a random number from 0 to $SLEEPYSTART seconds
# TIMEOUT - sets expiration time for your command (requires alarm.rb)
# JOBNAME - sets the job name used for locking and syslog tag (should be unique)

if [ -z "$JOBNAME" ] ; then
  echo "No jobname given. Please set JOBNAME in environment."
  exit 1
fi

output=$(mktemp) # for output capture
lockfile="/tmp/cronhelper.lock.$JOBNAME"

# use a subshell to capture all command output
(
  # redirect stderr to stdout for everything in this subshell.
  exec 2>&1

  if [ ! -z "$SLEEPYSTART" ] ; then
    sleeptime=$(echo "scale=8; ($RANDOM / 32768) * $SLEEPYSTART" | bc | cut -d. -f1)
    echo "Sleeping for $sleeptime seconds before starting."
    sleep $sleeptime
  fi

  # you'll want to use 'lockf -t 0' on FreeBSD
  flock="flock -w 0 $lockfile" 
  if [ -z "$TIMEOUT" ] ; then
    exec $flock "$@"
  else
    exec $flock alarm.rb $TIMEOUT "$@"
  fi
) | tee $output | logger -it "$JOBNAME"

# bash has "pipestatus" so we can get the exit status of the first command in
# the pipe. Normal /bin/sh does not support this.
jobstatus=${PIPESTATUS[0]}

if [ "$jobstatus" -ne 0 ] ; then
  echo "Job failed with status $jobstatus (command: $@)" | tee /dev/stderr | logger -it "$JOBNAME"
  # flock(1) on linux fails with exit code 1 if lock cannot be obtained.
  if [ "$jobstatus" -eq 1 ] ; then
    echo "Exit status ($jobstatus) may indicate lockfile is held."
  fi
  cat $output
  rm $output
  exit $jobstatus
fi

echo "job ran successfully"
rm $output


