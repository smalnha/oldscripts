#!/bin/bash

TARGET=${1:-/media/floppy}

if ! mount | grep "floppy"; then 
	mount "$TARGET"
	pushd "$TARGET"
	xterm.sh -name "Mount $TARGET"
	popd
	sync
	#sleep 3 # wait for xterm to quit and get out of dir
fi

umount $TARGET && xmessage -timeout 2 "Done umounting $TARGET."

