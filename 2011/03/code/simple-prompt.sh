#!/bin/sh

dialog --yesno "Do you want to do this?" 0 0
result=$?
echo

if [ $result -eq 0 ] ; then
  echo "Doing it."
else
  echo "Cancelled"
  exit 1
fi
