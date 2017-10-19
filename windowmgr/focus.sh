#!/bin/bash

# Usages: 
#   focus.sh email || xterm
#   focus.sh email "xterm -name email -e mail.sh"
#   focus.sh email "xterm -name email -e mail.sh" || xterm

toLower() {
  echo $1 | tr "[:upper:]" "[:lower:]" 
} 

APP=${1:-flock}
if wmctrl -l | grep "$APP"; then 
	wmctrl -a "$APP"
	wmctrl -r "$APP" -b remove,shaded
	exit 0
else
	#APP=`toLower "$APP"`
	if [ "$2" ]; then
		$2
	else
		which "$APP" && exec $APP
	fi
fi

