#!/bin/bash

# $1 is /dev/..
# $2 is product name and mount dir name

# make sure dir does not already have a mount and is empty
#mkdir -p "$MOUNTPT"
#echo pmount "$1" "$MOUNTPT"
MOUNTPT="/media/$2"
if xmessage -buttons Mount:0,Ignore "Mount device $1 on $MOUNTPT ?" && pmount "$1" "$2"; then
	pushd "$MOUNTPT" > /dev/null
	POSTMOUNT=xterm.sh
	eval "$POSTMOUNT"
	popd > /dev/null

	pumount "$MOUNTPT" || xmessage -timeout 2 "FAILED unmounting $MOUNTPT."
else
	echo "pumount failed. Try adding device $1 to /etc/pmount.allow if device is reported as unremovable. "
fi

