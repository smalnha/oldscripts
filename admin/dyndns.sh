#!/bin/bash
# Set the username and password for the dyndns account
USERNAME=myUsername
PASSWORD=$DYNDNS
# Set the system being used to either static or dynamic DNS
SYSTEM=dyndns
# Set the hostname for the record to change
DYNHOST=$USERNAME.homelinux.net
# Set whether to wildcard the DNS entry, i.e. *.$DYNHOST
WILDCARD=OFF
############################################
## DO NOT EDIT ANYTHING BEYOND THIS POINT ##
############################################
if [ -z "$DYNDNS" ]; then
DYNDNS="$DYNHOST"
fi
if [ -z "$DNSWILD"]; then
DNSWILD="$WILDCARD"
fi
LOOKUP=`host $DYNHOST | awk '{print $4}'`
MYIP=`curl -s http://www.ipchicken.com | awk '/[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*/ {print $1}'`
# Do the work
if [ "$LOOKUP" = "$MYIP" ]; then
echo "No change in DNS entry."
else
echo `lynx -auth=${USERNAME}:${PASSWORD} -source "http://members.dyndns.org:8245/nic/update?system=${SYSTEM}&hostname=${DYNDNS}&myip=${MYIP}&wildcard=${DNSWILD}"`
fi

