#!/bin/bash

if ! which lsmod; then
	exit 1
fi

startNewX(){
	local STARTX=$1
	shift

	# use this instead of startx if you wanna be able to start multiple x 
	# sessions seamlessly, w/out typing startx -- :1 etc every time.

	if [ $# -eq 0 ]      # check to see if arguments are given (color depth)
		then a=16        # default color depth
		else a=$1        # use given arguement
	fi

	if [ $a -ne 8 -a $a -ne 16 -a $a -ne 24 ]
		then
			echo "Invalid color depth. Use 8, 16, or 24."
		exit 1
	fi

	# checks for open display, starts X on next available
	for display in 0 1 2 3 4 5 ; {
		if [ ! -f "/tmp/.X$display-lock" ]; then
			echo "Using display $display"
         echo $STARTX -- :$display "$@" # -bpp $a
			# will by initiated by .xinitrc: exec ssh-agent 
            exec $STARTX -- :$display "$@" # -bpp $a
			exit 0
		fi
	}
	echo "No displays available."
	exit 1
}

startX(){
    XLOG="$HOME/.xorg-errors" startNewX `which startx` "$@"
}

Xorg(){
	#added path /usr/local/X11R6.8/lib to /etc/ld.so.conf to get correct libraries found
	#don't need to set LD_LIBRARY PATH

	#export LD_LIBRARY_PATH=/usr/local/X11R6.8/lib
	#export PATH=/usr/local/X11R6.8/bin:$PATH

    XLOG="$HOME/.xorg-errors" startNewX "/usr/local/X11R6.8/bin/startx" "$@"
}

XFree86(){
	XLOG=".xfree-errors" startNewX "/usr/X11R6/bin/startx" "$@"
}

. $MY_BINSRC/helperfuncs.src


case "$HOSTNAME" in
	"$MY_LIPSMACHINE")
		VNCOPTIONS="-geometry 3200x1200 -shared"
        if ! lsmod | grep -q nvidia; then
            DEFAULT=Xorg
        else
            echo "Note: nvidia module is currently loaded"
        fi
	;;
    dell6k | shannon)
        DEFAULT=startX
    ;;
	*)
        DEFAULT=startX
		VNCOPTIONS="-geometry 1200x1024 -shared"
	;;
esac

[ "$DEFAULT" ] && echo -e "\e[1;31m ----  Hit a key in 1 second to load $DEFAULT ... \e[0m"

CHOICES=""

which startx > /dev/null && CHOICES="$CHOICES startX"
which xorgcfg > /dev/null && CHOICES="$CHOICES Xorg"
which xf86cfg > /dev/null && CHOICES="$CHOICES XFree86"
which tightvncserver > /dev/null && CHOICES="$CHOICES \"exec tightvncserver -passwd ~/.vnc/passwd $VNCOPTIONS\" "
which vncserver      > /dev/null && CHOICES="$CHOICES \"exec vncserver      -passwd ~/.vnc/passwd $VNCOPTIONS\" "

if [ "$DEFAULT" ] && read -s -t 2 -n 1 ; then
	$DEFAULT
elif [ -z "$CHOICES" ]; then
	exit 1
else
	eval choose $CHOICES
	echo CHOICE=$CHOICE "$@"
	echo -------------------------
	$CHOICE "$@"
fi


