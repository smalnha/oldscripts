#!/bin/bash
# script for docking and undocking laptops at home and at work/lab
# must be executed as root or sudo

# NetGear wireless router notes: 
# 	set Authentication=Auto (not Shared)
# 	set IP and DNS to automatically get addresses since no broadband internet access (causes problems in Windows)

#		fixed issues:
#			/sbin/ifconfig calls ifup, causing dhclient or pump to change DNS in /etc/resolv.conf
#				DNS is set to the router's IP address -- Why doesn't the router give it's DNS?  because it's doing "DNS relay" (replacing with appropriate dns?)
#			ppp can correctly update /etc/resolv.conf with DNSs from dial-up server.


source ${MY_BINSRC:-~/bin/src}/helperfuncs.src

if [ "$1" == "--completion_options" ]; then
	echo "static undock setgw usegw reload info ppp"
	exit 0;
fi

unset IFACE

case "$1" in
	--completionCommand$COMPLETION_OPT)
		[ "$CREATE_COMPLETION_SCRIPT" ] && $CREATE_COMPLETION_SCRIPT $0 
		exit $COMPLETION_OPT
	;;
	"" | --help | -h)
		echo "dock.sh IFACE [options]

		With no options, $0 toggles between docking and undocking (confirm required).
			tries dhcp, which if fails, sets to last lease (or whatever is in /etc/dhclient.conf)

		Note: when docking IFACE, a default gateway will be added for IFACE.
		
		--static
			sets static IP (machine dependent)

		--undock (no confirmation)
			/sbin/ifconfig IFACE down


		--setgw   (for ppp)
			set this as gateway (loading wireless if needed): 
				- remove all gateways
				- change this ip to be default gateway 192.168.100.111
		--usegw   (for ppp)
			use default 192.168.100.111 as gateway (loading wireless if needed):
				- set correct DNSs
				- set gateway in route table 


		--reload
			reload modules (dependent on card type) if laptop suspend breaks interfaces

		--info
			uses iwgetid, iwconfig, and iwlist to get about wireless config

		--ppp
			ppp established
		--pppDown
			ppp disconnected


		--pcmcia socketnumber
		    cardctl insert socketnumber; then, use it
	"
		exit 0
	;;
esac

myecho(){
	echo "[dock.sh] $*"
}

# local NFSMOUNT="true"
DOCKCMD="dockToggle"
while [ "$1" ] ; do
	ARG="$1"
	# echo "case $ARG"
	case "$ARG" in
		--dock | dock | up) shift
			DOCKCMD="dock"
			;;
		--undock | undock | down) shift
			DOCKCMD="undock"
			;;
		--static | static) shift
			DOCKCMD="dockStatic"
			;;
		--setgw | set*) shift
			DOCKCMD="setThisAsGateway"
			;;
		--usegw | use*) shift
			DOCKCMD="useGateway"
			#echo "args=$*"
			GATEWAY=$1
			shift
			#echo "args=$*"
			;;
		--info | info) shift
			DOCKCMD="info"
			;;
		--reload | *load) shift
			DOCKCMD="reloadModule"
			;;
		--ppp | ppp) shift
			DOCKCMD="pppEstablished"
			;;
		--pppDown | pppDown) shift
			DOCKCMD="pppDown"
			;;
		--pcmcia) shift
			CARDINDEX="$1"
			shift
			;;
		eth*) 
			IFACE=$ARG
			shift
			;;
		*)
			myecho "Unknown argument $ARG"
			shift
			exit 1
			;;
	esac
done

#myecho "Will exec: $DOCKCMD $IFACE" && exit 0

# ------------------------------------------------------------------------------------------
# return 0 = true, return 100 = probably wired, return 200 = try cardmgr to load wireless driver
isWireless(){
	/sbin/iwconfig $1 2>&1 | grep -q "No such device" && return 200
	/sbin/iwconfig $1 2>&1 | grep -q "no wireless extensions" && return 100
	/sbin/iwgetid $1 | grep -q "ESSID" && return 0
}


getESSIDkey(){
	[ ! "$SNOTES" ] && local SNOTES=~/.mysnotes.asc
	[ ! "$ypwd" ] && local ypwd=`gpg --quiet -r $GPGID --decrypt $SNOTES | grep --ignore-case "$1"`
	echo ${ypwd##*:}
}

setESSID(){
	myecho "!!!!!!!!!!!!!!!!!!!! setESSID"
		if [ "$MY_LOCATION" == "" ]; then
			sudo iwconfig $1 essid off
			echo "iwconfig $1= `iwconfig $1`"
		else 
			ESSID=`iwgetid -s $1`
			if [ -z "$ESSID" ] || [ "$ESSID" = "NETGEAR" ]; then
				myecho "   Setting ESSID and key for location $MY_LOCATION"
				if [ "$MY_LOCATION" == "cheryl" ] ; then
					local ESSIDkey=`getESSIDkey iwconfig-cheryl:msierra:`
					sudo iwconfig $1 essid msierra key $ESSIDkey
				elif [ "$MY_LOCATION" == "home" ] ; then
					# danvilleWireless
					# remember to start cardmgr, which is started by pcmcia service
					# for more control of pcmcia card, cardinfo
					local ESSIDkey=`getESSIDkey iwconfig-home:danville8603:`
					if [ "$ESSIDkey" ]; then
						sudo iwconfig $1 essid danville8603 key $ESSIDkey nick "tosh-linux"
						# defaults are fine: mode Managed sens 1 
					else
						echo "No ESSID key.  Exiting."
						exit 0
					fi
				else
					sudo iwconfig $1 essid off
				fi
			else
				myecho "    ESSID already set to $ESSID"
			fi
		fi
}

# may parse /var/lib/pcmcia/stab to get the correct index; see below

checkIfWireless(){
	# load wireless if $IFACE is wireless
	isWireless $1
	IS_WIRELESS=$?
	if [ $IS_WIRELESS -eq 200 ] && [ ! "$DOCKCMD" == "reloadModule" ]; then
		if ! ps -C cardmgr; then
			myecho "Starting cardmgr"
			if [ "$USEPCMCIAINIT" ]; then
				myecho " via /etc/init.d/pcmcia"
				sudo /etc/init.d/pcmcia start
				sleep 2
			else
				sudo modprobe pcmcia
				sudo modprobe yenta_socket
				sleep 1
				sudo cardmgr -v
				sleep 2
			fi
			CARDMGR_STARTED="true"
		fi

		if [ "$CARDINDEX" ] ; then
			# 	cat /var/lib/pcmcia/stab
			#	if ask "Eject Socket 0?"; then
			#		sudo cardctl eject 0
			#	fi

			myecho "Inserting Socket $CARDINDEX"
			sudo cardctl insert $CARDINDEX
		fi

#		[ "$CARDINDEX" ] || 
#		CARDINDEX=`while read SOCKET INDEX EMPTY OTHER; do 
#			if [ "$SOCKET" = "Socket" ] && [ "$EMPTY" != "empty" ]; then 
#				echo "${INDEX%:}"
#			fi; 
#		done < /var/lib/pcmcia/stab`
		
		if [ "$CARDINDEX" ] ; then
			while [ ! -f /var/lib/pcmcia/stab ] ; do
				myecho "Waiting for pcmcia socket table (/var/lib/pcmcia/stab)..."
				sleep 2
				if ! /sbin/iwconfig $1 2>&1 | grep -q "No such device"; then
					myecho "iwconfig sees $1.  Done waiting."
					break;
				fi
			done;
		else
			myecho "No pcmcia socket specified."
			if [ ! -f /var/lib/pcmcia/stab ]; then
				myecho "Could not find /var/lib/pcmcia/stab."
				unset IS_WIRELESS
				return
			fi
		fi

		#setESSID $1

		#CARDINDEX="`cat /var/lib/pcmcia/stab | grep $1 | cut -f 1`"
		isWireless $1
		IS_WIRELESS=$?
	fi
	#myecho "IS_WIRELESS=$IS_WIRELESS"

	if [ -z "$IS_WIRELESS" ] ; then
		myecho "!!!!!!!!!"
	elif [ $IS_WIRELESS -eq 100 ] ; then
		myecho "Assuming interface $1 is wired."
		unset IS_WIRELESS
	elif [ $IS_WIRELESS -eq 0 ] ; then
		myecho "Wireless interface $1 found."
		if [ "$DOCKCMD" = "undock" ]; then
			sudo iwconfig $1 essid off
			return 0
		fi
		setESSID $1
	else
		myecho "huh? IS_WIRELESS=$IS_WIRELESS"
	fi
}

[ "$IFACE" ] && checkIfWireless $IFACE

# ------------------------------------------------------------------------------------------

info(){
	if [ "$IS_WIRELESS" ]; then
		myecho "----- /var/lib/dhcp/dhclient.leases -----"
		cat /var/lib/dhcp/dhclient.leases
		myecho "Wireless info for interface $1"
		sudo iwconfig $1
		iwgetid -c $1
		sudo iwlist $1 key
	else
		ifconfig $1
	fi
}


reloadModule(){
	# may need to do this after suspend
	# source /etc/sysconfig/knoppix
	# have to set it manually if more than one netcard (e.g., wireless and wire)
	if [ "$IS_WIRELESS" ]; then
		# myecho "Not sure how to reload wireless interface in socket $CARDINDEX"
		# sudo cardctl reset $CARDINDEX
		#myecho "ejecting" && sudo cardctl eject
		# sudo cardctl insert $CARDINDEX
		myecho "-- unloading --"
		undock $1
		sudo cardctl reset $CARDINDEX 
		sudo cardctl suspend $CARDINDEX 
		sudo cardctl eject $CARDINDEX 
		if [ "true" ]; then
			sudo /etc/init.d/pcmcia stop
		else
			sudo killall cardmgr
			sleep 2
		fi
		NETCARD_DRIVER=orinoco_cs
		sudo modprobe -r yenta_socket
		if ! sudo modprobe -r $NETCARD_DRIVER ; then
			sudo killall net.ifup
			sleep 1
			sudo modprobe -r $NETCARD_DRIVER 
		fi
		#sudo modprobe -r ds
		sudo modprobe -r pcmcia_core
		sleep 1
		lsmod | grep $NETCARD_DRIVER
		ps -C cardmgr
		ps -C dhclient3
		sudo rm -i /var/lib/dhcp/dhclient.leases
		myecho "-- Don't need to load wireless drivers now" && return 0

		myecho "-- reloading --"
		sudo modprobe pcmcia_core
		return 0

		sudo modprobe $NETCARD_DRIVER
		sudo cardmgr
		sleep 1
		sudo killall net.ifup
		undock $1

		#myecho "Restarting /etc/init.d/pcmcia"
		#sudo /etc/init.d/pcmcia restart
		return 0
	else
		NETCARD_DRIVER=8139too 	#for RealTek RTL8139 ethcard
		myecho "Reloading $NETCARD_DRIVER ($NETCARD_FULLNAME)"
		lsmod | grep -q "slamr" && myecho "If this doesn't work, may have to remove slamr module."
		sudo modprobe -r $NETCARD_DRIVER
		sudo modprobe $NETCARD_DRIVER
		sudo rm -i /var/lib/dhcp/dhclient.leases
	fi
}

TRIP="[0-2]\?[0-9]\?[0-9]\?"
# used to lookup 'mygateway', 'router', and IP for docking using static IP
iplookup(){ # looks in /etc/hosts for given hostname
	local IPADDR=`grep -w "$TRIP\.$TRIP\.$TRIP\.$TRIP[ \t]*.*[ \t]*$1" /etc/hosts`
	if [ "$IPADDR" ] ; then
		echo ${IPADDR%% *}
	else 
		IPADDR=`host $1`
		echo ${IPADDR##* }
	fi
}

listGatewayInterfaces(){
	/sbin/route -n | {
	while read DEST GW MASK FLAGS METRIC REF USE IFACE ; do
		if echo $FLAGS | grep -q "G"; then 
			echo $IFACE
		fi
	done
	}
}

# no longer needed now that /etc/dhclient.conf is configured
# writeResolvConf(){
# 	[ -f /etc/resolv.conf.dock ] || sudo mv -v /etc/resolv.conf{,.dock}
# 	{
# 		myecho "# created by dock.sh"
# 		myecho "search ece.utexas.edu"
# 		myecho "nameserver `iplookup dns1`"
# 		myecho "nameserver `iplookup dns2`"
# 		myecho "nameserver `iplookup dns3`"
# 	} >> /tmp/resolv.conf
# 	sudo mv -v /{tmp,etc}/resolv.conf
# }

getIPof(){
	! ifconfig $1 | grep -q -w " *UP" && echo ""
	ifconfig $1 2> /dev/null | grep "inet addr" | sed 's/ *inet addr:\([^ \t]*\)/\1/' | { read -a A B; echo $A; }
}

listInterfaces(){
	ifconfig | grep "^[^ ]" | while read -a A B; do [ "$A" == "lo" ] ||  echo "$A" | grep -q "^ppp" || echo $A; done;
}

pppEstablished(){
	myecho `date`
	IFACES="`listInterfaces`"
	if [ -z "$IFACES" ] ; then
		myecho "No existing interfaces to set as a gateway."
		[ "$NO_AUTODOCK" ] && return 1
		for IFACE in eth0 eth1 eth2 ; do
			myecho "Attempting to bring up interface $IFACE"
			setThisAsGateway $IFACE && return 0
			# if you want to check for LAN connection should use instead:
			# dockDHCP $IFACE && break
			myecho "Failed ---------  Trying next interface:"
		done;
		IFACES="`listInterfaces`"
	fi
	for IFACE in $IFACES; do
		myecho "Picking first interface $IFACE as gateway"
		setThisAsGateway $IFACE && break
	done
}

pppDown(){
	myecho `date`
	IFACES="`listInterfaces`"
	local GWIP=`iplookup ${2:-mygateway}`
	for IFACE in $IFACES; do
		local IFACE_IP=`getIPof $IFACE`
		#myecho "$IFACE $IFACE_IP"
		if [ "$IFACE_IP" == "$GWIP" ]; then
			myecho "Bringing down gateway interface $IFACE"
			undock $IFACE && dock $IFACE && break 
		fi
	done
}

useGateway(){
	# set gateway
	GW_IFACES="`listGatewayInterfaces`"
	if [ "$GW_IFACES" ] ; then
		route -n
		for GW_IFACE in $GW_IFACES; do
			if echo $GW_IFACE | grep -q "^ppp" ; then
				myecho "$GW_IFACE is connected. Cannot use another gateway!"
				return 1
			fi
			myecho "Removing existing default gateway on $GW_IFACE."
			sudo /sbin/route del default $GW_IFACE
		done
		route -n
	fi

	local GWIP="$2"
	if ! echo "$GWIP" | grep -q "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*"; then
		local GWIP=`iplookup ${GWIP:-mygateway}`
	fi
	echo ------------$2 $GWIP

	# change ip if same as gateway
	IFACE_IP=`getIPof $1`
	#echo "if [ "$IFACE_IP" == "$GWIP" ]; then"
	if [ "$IFACE_IP" == "$GWIP" ]; then
		myecho "Interface $1 has the same IP as the gateway $GWIP.  Getting new IP."
		dock $1
	fi

	myecho "Adding gateway $GWIP to $1"
	sudo /sbin/route add default gw $GWIP $1

	#done: myecho "Should figure out how to prevent pump or dhclient from overwriting resolv.conf"
	#myecho " see /etc/pcmcia/network"
	#writeResolvConf
}

setThisAsGateway(){
	killdhcp $1

	myecho "ISSUE: dhclient may override /etc/resolv.conf while ppp is on; okay for now since DNS the same."

	local GWIP=`iplookup ${2:-mygateway}`
	if [ "$GWIP" == "`getIPof $1`" ]; then
		myecho "Interface $1 already set to IP $GWIP"
		# sudo /sbin/ifconfig $1 up  # in case it is not up
	else 
		myecho "Setting interface $1 IP to $GWIP"
		sudo /sbin/ifconfig $1 $GWIP broadcast 192.168.100.255 netmask 255.255.255.0 
	fi

	GW_IFACES="`listGatewayInterfaces`"
	for GW_IFACE in $GW_IFACES; do
		[ -z "$GW_IFACE" ] && continue
		if echo "$GW_IFACE" | grep -q "^ppp" ; then
			myecho "Keeping gateway on $GW_IFACE."
		else
			myecho "Remove existing gateway on $GW_IFACE."
			sudo /sbin/route del default $GW_IFACE
		fi
	done

	sudo icsharing.sh
}

killdhcp(){
	DHCLIENT_PID=`ps -A -o pid,command | grep -v "grep" | grep "dhclient3 .*$1" | { read PID COMMAND; echo $PID; }`
	if [ "$DHCLIENT_PID" ]; then
		myecho "Killing dhclient associated with $1"
		sudo kill $DHCLIENT_PID
	else
		myecho "dhclient for $1 not found."
		ps -A -o pid,command | grep -v "grep" | grep "dhclient*"
	fi
}

undock(){
	killdhcp $1

	# check where I am:
	if /sbin/ifconfig $1 | grep -q '192.168.100.' ; then
		# if home, ...
		[ "$NFSMOUNT" ] && mountdirs.sh --unmount -i $1 home
		sudo /sbin/ifconfig $1 down
	elif /sbin/ifconfig $1 | grep -q '146.6.53.' ; then 
		# else if lab, ...
		# unmount directories
		[ "$NFSMOUNT" ] && mountdirs.sh --unmount -i $1 lab
		sudo /sbin/ifconfig $1 down
	else
		myecho "Unknown broadcast address; see below: "
		/sbin/ifconfig $1
		myecho "Bringing $1 down anyway."
		sudo /sbin/ifconfig $1 down
	fi

	if listGatewayInterfaces | grep -q "$1" ; then
		myecho "Removing default route for $1"
		sudo /sbin/route del default $1
	fi
}

dockStatic(){
	killdhcp $1

	# set up eth for local home network
	if [ "$IS_WIRELESS" ]; then
		local HOSTALIAS="${HOSTNAME}Wireless"
	else
		local HOSTALIAS="${HOSTNAME}"
	fi
	local IP=`iplookup $HOSTALIAS`
	if [ "$IP" ] ; then
		myecho "Setting up LAN network for \"$HOSTALIAS\" using ip=$IP :"
		sudo /sbin/ifconfig $1 $IP broadcast 192.168.100.255 netmask 255.255.255.0
		if [ "" ] ; then #apparently, I don't need these:
			# send packets with given IP to $IFACE ?
			route add $IP $1
			# route for internal packets
			route add -net 192.168.100.0 netmask 255.255.255.0 $1
			# ??
			route add -host 127.0.0.1 lo
		fi
		/sbin/ifconfig $1
		# mount linux-black directories
		[ "$NFSMOUNT" ] && mountdirs.sh -i $1 home
		myecho "Done."
	else 
		myecho "Could not find entry \"$HOSTALIAS\" in /etc/hosts!"
		return 1
	fi
}

externalip(){
	if which wget > /dev/null; then
		wget -q "http://www.whatismyip.com" --output-document=- | grep -o -m 1 "$TRIP\.$TRIP\.$TRIP\.$TRIP"
	elif which ssh > /dev/null; then
		# ssh phillips "printenv SSH_CONNECTION | sed 's/ /\n/g' > ~/.ssh_connection; head -n 1 ~/.ssh_connection"
		ssh ${MAINSERVER:-shell.sf.net} 'echo ${SSH_CONNECTION%% *}'
	fi
}

removeAllGateways(){
	route -n
	local EXIST_GW="`route -n | grep "G .*" | { read DEST GATEWAY OTHER; echo $GATEWAY; }`"
	if [ "$EXIST_GW" ]; then
		GW_IFACES="`listGatewayInterfaces`"
		for GW_IFACE in $GW_IFACES; do
			[ -z "$GW_IFACE" -o "$GW_IFACE" = "$1" ] && continue
			myecho "Existing gateway exists !!!!!  Probably should remove (IF $1 acquires a gateway)"
			myecho "Need to ask if want to remove existing gateways"
			if ask "Want to remove gateway on $GW_IFACE"; then
				myecho "Removing default gateway on $GW_IFACE.  And killing dhclient $GW_IFACE."
				sudo /sbin/route del default $GW_IFACE
				killdhcp $GW_IFACE
				route -n
			fi
		done
	fi
}


dockDHCP(){
#	myecho -e "Hit a key in 1 second to skip DHCP ..."
#	read -s -t 1 -n 1 && SKIPDHCP="true"

	killdhcp $1
	removeAllGateways 
	myecho "Trying dhcp ... " #(edit /etc/pump.conf to decrease timeout) ..."

	if sudo dhclient3 $1; then # if dhcp working,
		#dhclient3 fixes this: removeAllGateways $1  # for some reason, dhclient brings up other eth's gw

		# do LAN-specific tasks
		if /sbin/ifconfig $1 | grep -q '146.6.53.' ; then 
			myecho "location=lips"
			# mount phillips directories
			[ "$NFSMOUNT" ] && mountdirs.sh -i $1 lab
		elif /sbin/ifconfig $1 | grep -q '192.168.100.' ; then
			myecho "location=home"
			local GW="`route -n | grep "G .* $1" | { read DEST GATEWAY OTHER; echo $GATEWAY; }`"
			local ROUTERIP="`iplookup router`"
			myecho GW=$GW ROUTERIP=$ROUTERIP
			if [ "$GW" = "$ROUTERIP" ]; then
				myecho "----- using router as gateway ----"
				myecho "Your external ip is `externalip`"
			else 
				if ask "Use ppp gateway?"; then
					#myecho "Assuming using ppp ..."
					useGateway $1
				fi
			fi
		else
			myecho "Unknown network; not mounting any dirs or setting up gateways:"
			/sbin/ifconfig $1
		fi

		GW_IFACES="`listGatewayInterfaces`"
		if echo "$GW_IFACES" | grep -q "ppp" && echo "$GW_IFACES" | grep -q "$1"; then
			myecho "Removing default gateway on $1 (added by dhclient)."
			sudo /sbin/route del default $1
		fi
		return 0
	else
		myecho "   Could not get IP using dhcp and no old leases in /var/lib/dhcp/dhclient.leases!"
		return 1
	fi
}

dock(){
	if [ "$SKIPDHCP" ] ; then
		myecho "Skipping DHCP."
	else
		dockDHCP $1 && return 0
	fi

	myecho "Trying static IP:"
	dockStatic $1
}

dockToggle(){
	if [ -z "$CARDMGR_STARTED" ] && /sbin/ifconfig | grep -q $1 ; then # if eth1 is connected, undock
		ask "Want to undock?" && undock $1
	else
		dock $1
	fi
}

myecho "$DOCKCMD $IFACE $GATEWAY"
$DOCKCMD $IFACE $GATEWAY


