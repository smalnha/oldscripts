#!/bin/bash

setMonetDBDir(){
	# set LD_LIBRARY_PATH to path for libmonet.so.0
	for POSSIBLEPATHS in /usr/local/lib /usr/lib/ ; do
		if [ -d "$POSSIBLEPATHS/MonetDB" ] ; then
			export MONET_HOME="$POSSIBLEPATHS/MonetDB"
			export LD_LIBRARY_PATH="$POSSIBLEPATHS"
		fi
	done;
	if [ -z "${MONET_HOME}" ] ; then 
		echo "Could not find MonetDB dir!"
		return 1
	fi
}

startServer(){
	echo "MONET_HOME=$MONET_HOME LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
	Mserver $MONET_HOME/sql_server.mil || read
	#unset LD_LIBRARY_PATH
}

startClient(){
	MapiClient -l sql -H
	#unset LD_LIBRARY_PATH
}

clearTmp(){
	# source installed
	[ -d /usr/local/var/MonetDB.bak ] && sudo rm -rf /usr/local/var/MonetDB.bak
	[ -d /usr/local//var/MonetDB ] && sudo mv -f /usr/local/var/MonetDB{,.bak}

	# rpm installed
	[ -d /var/lib/MonetDB.bak ] && sudo rm -rf /var/lib/MonetDB.bak
	[ -d /var/lib/MonetDB ] && sudo mv -f /var/lib/MonetDB{,.bak}
}

if ! setMonetDBDir ; then
	exit 1
fi

if [ "$1" == "-s" ] ; then
	if sudo echo "Starting server ... " ; then
		sudo xterm -e $HOME/bin/monetDB.sh startServer &
		sleep 3
		startClient
	else 
		echo "Try running as root.  Quiting ..."
		exit 1
	fi
elif [ "$1" ]; then
	$1
else 
	startClient
fi
