#!/bin/sh
# Sync homedirs from someserver::homedirs  to /home
#
# Platform notes:
# This script uses some Linux or GNU-specific tools:
# su(1) at the bottom of the script use the standard gnu one
# You could swap it out with your own setuid tool (such as daemontools'
# setuidgid) or another su invocation
#
# 'sed -r' is GNU specific, if you're on FreeBSD (or familiy) you'll want
# to use 'sed -E'

# set this to the path to your rsync server and path where you keep
# your homedirs
source="someserver::homedirs"

prog="$(basename $0)"
# Make sure someserver::homedirs rsync module exists
rsync -q $source
if [ $? -ne 0 ] ; then
  echo "$prog: rsync fatal error" >&2
  exit 1
fi

# For all directories in someserver::homedir that are not dot-directories,
# assume they are a user and try to sync files to their homedir.

rsync $source | awk '/^d/ && $NF !~ /^\./ { print $NF }' \
| while read user; do
  # If the user doesn't exist on this system, skip it.
  getent passwd $user > /dev/null
  if [ $? -ne 0 ] ; then
    echo "$prog: User '$user' does not exist on this server, skipping" >&2
    continue
  fi 

  # Create the home directory first.
  if [ ! -d "/home/$user" ] ; then
    # Get $user's default group
    gid="$(id $user | sed -re 's/^.* gid=([0-9]+)[^0-9].*$/,\1/')"
    install -d -o $user -g $gid -m 0711 /home/$user
  fi
  
  # run rsync as $user to prevent accidents
  su -c "rsync -vr --exclude=.svn $source/$user/ /home/$user/" $user
done

