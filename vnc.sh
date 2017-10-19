#!/bin/bash

listUsed(){
	let count=0
	pushd $HOME/.vnc > /dev/null
	for PIDFILE in *.pid; do 
		[ -e "$PIDFILE" ] || continue
		echo ${PIDFILE%.*}
		let count++
	done
	popd > /dev/null
	return $count
}
listUnused(){
	for x in 1 2 3 4 5 6 7; do 
		[ ! -f "$HOME/.vnc/$HOSTNAME:$x.pid" ] && echo $x;
	done
}
killserver(){
	SERVERS=`listUsed`
	select SERVER in $SERVERS "exit"; do
		[ "$SERVER" == "exit" ] && return 0;		
		break;
	done
	[ -z "$SERVER" ] && echo "Quiting." && return 0;
	if [ "${SERVER%%:*}" == "$HOSTNAME" ] ; then
		vncserver -kill :${SERVER##*:}
	else
		ssh ${SERVER%%:*} -x vncserver -kill :${SERVER##*:}
	fi
}
viewer(){
	local SERVERS=`listUsed`
	listUsed > /dev/null
	local NUMOFSERVERS=$?
	echo "NUMOFSERVERS=$NUMOFSERVERS"
	if [ -z "$SERVERS" ] ; then
		echo "No servers found"
		return 1;
	elif [ $NUMOFSERVERS -eq 1 ] ; then
		SERVER="$SERVERS"
		echo "One server found: $SERVERS"
	else
		select SERVER in $SERVERS "exit"; do
			[ "$SERVER" == "exit" ] && return 0;		
			break;
		done
		[ -z "$SERVER" ] && echo "Quiting." && return 0;
	fi 

	echo "Running vncviewer -passwd ~/.vnc/passwd $SERVER"
	vncviewer -passwd ~/.vnc/passwd "$@" $SERVER
}

server(){
	which vncserver || return 1
	echo "Starting server, please wait ..."
	LOCATION=`vncserver -geometry $1 2>&1 | grep "New 'X' desktop" | grep -o "[[:alpha:]\.]*:.*$"`
	[ -z "$LOCATION" ] && echo "!!! Could not get vncserver location" && return 1
	echo -n "Want a viewer to $LOCATION? [y/N] "
	read ans; case "$ans" in
        y*|Y*) vncviewer -passwd ~/.vnc/passwd $LOCATION; return 0 ;;
        *) echo "Use this command to access the vncserver: vncviewer -passwd ~/.vnc/passwd $LOCATION"; return 0 ;;
    esac
}

askForTask(){
	echo "--- list of servers on $HOSTNAME:$HOME/.vnc -----------"
	listUsed
	echo "--------------------------------------------"
	select TASK in "killserver" "viewer" "viewer -shared" "server 1280x1024" "server 1024x768" "server 800x600" "exit" ; do
		[ "$TASK" == "exit" ] && return 0;		
		break;
	done
	[ -z "$TASK" ] && echo "Quiting." && return 0;
	echo "--------------------------------------------"
	$TASK
}
askForTask




