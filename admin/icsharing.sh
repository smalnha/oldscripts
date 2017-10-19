#! /bin/bash
# [ $DOCIT ] || source /etc/init.d/docit.sh
# $DOCIT "icsharing: $0 $*" 

echo "check out firestarter as a replacement for iptables"

IPTABLESCMD=/sbin/iptables
INETCONNECTION=ppp0
GATEWAY_IFACE=${1:-eth0}
echo "1" > /proc/sys/net/ipv4/ip_dynaddr
# enable IP forwarding of incoming packets
echo "1" > /proc/sys/net/ipv4/ip_forward
# The first iptables line is flushing the iptables rules for nat.
$IPTABLESCMD -F -t nat
# turn on NAT (IP masquerading) for outgoing packets
$IPTABLESCMD -t nat -A POSTROUTING -o $INETCONNECTION -j MASQUERADE

# allowing your Network Card to be used as an ISP that serves the 192.168.0.2 PC.
# allows traffic from network card to pass through
$IPTABLESCMD -A FORWARD -i $GATEWAY_IFACE -j ACCEPT
# the rest probably is not needed for internet connection sharing
$IPTABLESCMD -A FORWARD -m state -j ACCEPT --state ESTABLISHED,RELATED
$IPTABLESCMD -A FORWARD -m limit --limit 5/minute --limit-burst 5 -j LOG

# basic firewall
# flush INPUT table
$IPTABLESCMD -F INPUT

# Allow loopback access. This rule must come before the rules denying port access!!
# This rule is essential if you want your own computer to be able to access itself through the loopback interface
$IPTABLESCMD -A INPUT -i lo -p all -j ACCEPT 
$IPTABLESCMD -A OUTPUT -o lo -p all -j ACCEPT

# deny any connection to your $INETCONNECTION interface from the three "C" class IP's
$IPTABLESCMD -A INPUT -i $INETCONNECTION -j DROP --source 192.168.1.0/24 
$IPTABLESCMD -A INPUT -i $INETCONNECTION -j DROP --source 10.0.0.0/8
$IPTABLESCMD -A INPUT -i $INETCONNECTION -j DROP --source 172.16.0.0/12

# allows all data sent out for this computer to come back (for ICMP/TCP/UDP)
$IPTABLESCMD -A INPUT -i $INETCONNECTION -j ACCEPT -m state --state ESTABLISHED -p icmp
$IPTABLESCMD -A INPUT -i $INETCONNECTION -j ACCEPT -m state --state ESTABLISHED -p tcp
$IPTABLESCMD -A INPUT -i $INETCONNECTION -j ACCEPT -m state --state ESTABLISHED -p udp

# allow incoming FTP requests
$IPTABLESCMD -A INPUT -p tcp -j ACCEPT --dport 20
$IPTABLESCMD -A INPUT -p tcp -j ACCEPT --dport 21

# allow incoming SSH requests
$IPTABLESCMD -A INPUT -p tcp -j ACCEPT --dport 22

# allow ping to work outside the network
$IPTABLESCMD -A INPUT -p icmp -j ACCEPT

# Deny outside packets from internet which claim to be from your loopback interface.
$IPTABLESCMD -A INPUT -p all -s localhost  -i $GATEWAY_IFACE -j DROP 

# drop and log (/var/log/syslog) all other data 
# if > 5 packets dropped in 3 secs, they are ignored (helps prevent DOS attacks)
# the following prevents SAMBA
#$IPTABLESCMD -A INPUT -m limit --limit 3/second --limit-burst 5 -i ! lo -j LOG
#$IPTABLESCMD -A INPUT -i ! lo -j DROP

#$DOCIT "Windows: set gateway to this IP address.  \n\tEnter ISPs DNSs: 128.83.185.40, 128.83.139.9, 146.6.53.4"


