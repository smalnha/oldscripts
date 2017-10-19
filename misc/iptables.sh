# To allow incoming traffic on port 22 (traditionally used by SSH), you could tell iptables to allow all TCP traffic on port 22 of your network adapter.
# 

iptables -A INPUT -p tcp -i eth0 --dport ssh -j ACCEPT

# Specifically, this appends (-A) to the table INPUT the rule that any traffic to the interface (-i) eth0 on the destination port for ssh that iptables should jump (-j), or perform the action, ACCEPT.
# 
# Lets check the rules: (only the first few lines shown, you will see more)
# 
iptables -L
# Chain INPUT (policy ACCEPT)
# target     prot opt source               destination        
# ACCEPT     all  --  anywhere             anywhere            state RELATED,ESTABLISHED  
# ACCEPT     tcp  --  anywhere             anywhere            tcp dpt:ssh 
# 
# Now, let's allow all web traffic
# 
iptables -A INPUT -p tcp -i eth0 --dport 80 -j ACCEPT
# 
# Checking our rules, we have
# 

iptables -L
# Chain INPUT (policy ACCEPT)
# target     prot opt source               destination        
# ACCEPT     all  --  anywhere             anywhere            state RELATED,ESTABLISHED  
# ACCEPT     tcp  --  anywhere             anywhere            tcp dpt:ssh 
# ACCEPT     tcp  --  anywhere             anywhere            tcp dpt:www 
# 
# We have specifically allowed tcp traffic to the ssh and web ports, but as we have not blocked anything, all traffic can still come in.
# 

#--------------------------------------------------------------
# Blocking Traffic
# 
# Once a decision is made about a packet, no more rules affect it. As our rules allowing ssh and web trafic come first, as long as our rule to block all traffic comes after them, we can still accept the traffic we want. All we need to do is put the rule to block all traffic at the end. The -A command tells iptables to append the rule at the end, so we'll use that again.
# 
# 
iptables -A INPUT -j DROP
iptables -L
# # Chain INPUT (policy ACCEPT)
# # target     prot opt source               destination        
# # ACCEPT     all  --  anywhere             anywhere            state RELATED,ESTABLISHED  
# # ACCEPT     tcp  --  anywhere             anywhere            tcp dpt:ssh 
# # ACCEPT     tcp  --  anywhere             anywhere            tcp dpt:www 
# # DROP       all  --  anywhere             anywhere 
# # 
# # Because we didn't specify an interface or a protocol, any traffic for any port on any interface is blocked, except for web and ssh.
# # 
# Editing iptables
# 
# The only problem with our setup so far is that even the loopback port is blocked. We could have written the drop rule for just eth0 by specifying -i eth0, but we could also add a rule for the loopback. If we append this rule, it will come too late - after all the traffic has been dropped. We need to insert this rule onto the fourth line.
# 
iptables -I INPUT 4 -i lo -j ACCEPT
iptables -L
# Chain INPUT (policy ACCEPT)
# target     prot opt source               destination        
# ACCEPT     all  --  anywhere             anywhere            state RELATED,ESTABLISHED  
# ACCEPT     tcp  --  anywhere             anywhere            tcp dpt:ssh 
# ACCEPT     tcp  --  anywhere             anywhere            tcp dpt:www
# ACCEPT     all  --  anywhere             anywhere            
# DROP       all  --  anywhere             anywhere
# 
# The last two lines look nearly the same, so we will list iptables in greater detail.
# 
iptables -L -v
# 
# 

# -----------------------------------------------

# Most people just have a single PPP connection to the Internet, and don't want anyone coming back into their network, or the firewall:

## Insert connection-tracking modules (not needed if built into kernel).
# insmod ip_conntrack
# insmod ip_conntrack_ftp

## Create chain which blocks new connections, except if coming from inside.
# iptables -N block
# iptables -A block -m state --state ESTABLISHED,RELATED -j ACCEPT
# iptables -A block -m state --state NEW -i ! ppp0 -j ACCEPT
# iptables -A block -j DROP

## Jump to that chain from INPUT and FORWARD chains.
# iptables -A INPUT -j block
# iptables -A FORWARD -j block

# -----------------------------------------------

# The kernel starts with three lists of rules in the `filter' table; these lists are called firewall chains or just chains. The three chains are called INPUT, OUTPUT and FORWARD.

# Incoming                 /-----\         Outgoing
#        -->[Routing ]--->|FORWARD|------->
#           [Decision]     \_____/        ^
#                |                        |
#                v                      ____
#               ___                    /    \
#              /   \                  |OUTPUT|
#             |INPUT|                  \____/
#              \___/                      ^
#                |                        |
#                 ----> Local Process ----
# 
# 
# The three circles represent the three chains mentioned above. When a packet reaches a circle in the diagram, that chain is examined to decide the fate of the packet. If the chain says to DROP the packet, it is killed there, but if the chain says to ACCEPT the packet, it continues traversing the diagram.
# 
# A chain is a checklist of rules. Each rule says `if the packet header looks like this, then here's what to do with the packet'. If the rule doesn't match the packet, then the next rule in the chain is consulted. Finally, if there are no more rules to consult, then the kernel looks at the chain policy to decide what to do. In a security-conscious system, this policy usually tells the kernel to DROP the packet.
# 
#    1. When a packet comes in (say, through the Ethernet card) the kernel first looks at the destination of the packet: this is called `routing'.
#    2. If it's destined for this box, the packet passes downwards in the diagram, to the INPUT chain. If it passes this, any processes waiting for that packet will receive it.
#    3. Otherwise, if the kernel does not have forwarding enabled, or it doesn't know how to forward the packet, the packet is dropped. If forwarding is enabled, and the packet is destined for another network interface (if you have another one), then the packet goes rightwards on our diagram to the FORWARD chain. If it is ACCEPTed, it will be sent out.
#    4. Finally, a program running on the box can send network packets. These packets pass through the OUTPUT chain immediately: if it says ACCEPT, then the packet continues out to whatever interface it is destined for.
# 
# http://www.netfilter.org/documentation/HOWTO/packet-filtering-HOWTO-7.html
