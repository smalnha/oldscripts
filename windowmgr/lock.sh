#!/bin/bash

# referenced in .Xresources and .fluxbox/keys
# couldn't specify direct/lock.sh path in .Xresources, so this file must be in path

lock(){
	echo "Locking ... don't use 'kill -KILL xlock', it makes the server unusable."
	if which xlock > /dev/null ; then
		if acpi_available || [ "$HOSTNAME" == "knop" ] || [ -f "/etc/laptop" ] || pgrep vncserver > /dev/null || pgrep Xtightvnc > /dev/null; then
			MODES=( clock )
		else
			# array of desired modes	
			MODES=( blank clock grav juggle swarm )
		fi
		echo xlock $* -mode ${MODES[$(($RANDOM % ${#MODES[*]}))]}
		#xlock -display $DISPLAY "$@" -mode ${MODES[$(($RANDOM % ${#MODES[*]}))]} -font "-misc-console-medium-r-normal--16-160-72-72-c-160-iso10646-1"
		xlock -display $DISPLAY "$@" -mode ${MODES[$(($RANDOM % ${#MODES[*]}))]} -font "fixed" +enablesaver
	elif which xscreensaver > /dev/null ; then
		xscreensaver &
		sleep 1
		xscreensaver-command -lock
	else
		xmessage "Could not find xlock or xscreensaver." 
	fi
}

unlock(){
	xautolock -exit
	# don't use 'kill -KILL xlock', it makes the server unusable. man xlock
}

if ps -U $USER -o command | grep -q -w "^xlock -display $DISPLAY" ; then
	unlock $*
else
	lock $*
fi

