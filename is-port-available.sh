#!/bin/sh
#To find an unused port
Port=5900
while netstat -atwn | grep "^.*:${Port}.*:\*\s*LISTEN\s*$"
do
Port=$(( ${Port} + 1 ))
done
echo "Looks like you get port ${Port}."
