#!/bin/bash

if [ "$MY_WMpid" ]; then
	echo ".xinitrc is already running !!!"
	printenv > ~/xinit.env
	xmessage "Error: see ~/xinit.env"
else
	[ "$TEMP" ] || if [ -e "$HOME/.my_links/tempDir" ]; then
		TEMP="$HOME/.my_links/tempDir"
	else 
		TEMP="${TMP:-/tmp}"
	fi
	# TEMP is my own temp dir separate from /tmp that is easily accessible by all
	[ "$XLOG" ] || XLOG="$TEMP/`basename $0`-$USER$DISPLAY.log"

	[ -f "$XLOG" ] && mv -vf "$XLOG"{,.bak}
	exec &> "$XLOG"
	ln -sf "$XLOG" "$HOME/.x-errors-$USER$DISPLAY"

	
	echo "------ $0 .xinitrc running -------------- `date`"
	if [ -z "$WINDOW_MANAGER" ]; then
		for WM in fvwm2 fvwm-crystal fluxbox; do
			if which "$WM"; then
				export WINDOW_MANAGER="$WM"
				break
			fi
		done;
	fi
	
	# desktop environment (e.g., KDE, GNOME), diff from WINDOW_MANAGER
	# export DESKTOP=$WINDOW_MANAGER
	
	# used by KDE, GNOME, X
	export BACKGROUND="$HOME/.background/$HOSTNAME.jpg"
	
	# do WINDOW_MANAGER-specific prep and set arguments
	case "$WINDOW_MANAGER" in
		fluxbox)
			export LC=C
			# suppose to make load fluxbox faster
			export LC_ALL=C
	
			WM_ARGS="-display $DISPLAY -log $TEMP/.$WINDOW_MANAGER.log-$USER$DISPLAY"
	
			# to reduce load time
			#$HOME/.fluxbox/loadmenu.sh reset
			#if [ -L "$HOME/.fluxbox/mymenu" ] && ! cmp "$HOME/.fluxbox/"{mymenu,shortmenu} ; then
			#	ln -sf "$HOME/.fluxbox/shortmenu" "$HOME/.fluxbox/mymenu"
			#fi
		;;
		fvwm2)
			WM_ARGS="--display $DISPLAY"
		;;
	esac

	#export MY_WMpid=`pgrep -U $USER -f "$WINDOW_MANAGER -display ${DISPLAY%%\.*}"`
	export MY_WMpid=`pgrep -U $USER -f "$WINDOW_MANAGER $WM_ARGS"`
	[ -z "$MY_WMpid" ] && MY_WMpid=`ps -u $USER -o pid,command | grep -v "grep" | grep -m 1 "$WINDOW_MANAGER -display ${DISPLAY%%\.*}" | awk '{print $1}'`
	
	if [ "$MY_WMpid" ] ; then
		# window manager started
		xmessage -timeout 30 "Window manager $WINDOW_MANAGER is already running: MY_WMpid=$MY_WMpid.  Do you want to start another $WINDOW_MANAGER?" -buttons "Yes,No" -default "No"
		if [ $? -ne 101 ]; then
			# if not "Yes", then exit
			exit 1
		fi
	fi
	
	# /usr/X11R6/include/X11/cursorfont.h has cursor_names
	#xsetroot -solid black -cursor_name watch
	
	#echo [xinitrc] LD_LIBRARY_PATH=$LD_LIBRARY_PATH
	#export LD_LIBRARY_PATH=/usr/local/X11R6.8/lib  # add this to /etc/ld.so.conf instead, when ready; or ln -s /usr/local/X11R6.8 /usr/X11R
	
	#see /usr/lib/X11/app-defaults for possible files
	export XUSERFILESEARCHPATH="$HOME/.Xapp-defaults/%N:/usr/lib/X11/%L/app-defaults/%N:/usr/lib/X11/app-defaults/%N"
	
	[ -f "$HOME/.Xresources" ] && xrdb -merge $HOME/.Xresources
	# X should load $HOME/.Xdefaults-$HOSTNAME, but doesn't seem to work,
	# so load it now to override any previously set .Xresources
	if [ -f "$HOME/.Xdefaults-$HOSTNAME" ] ; then
		xrdb -merge $HOME/.Xdefaults-$HOSTNAME
	fi
	
	# if preferred WINDOW_MANAGER or twm is running and a vncserver is running, then start a vncviewer instead.
	if false && { pgrep -U $USER "$WINDOW_MANAGER" || pgrep -U $USER twm ; } && pgrep -U $USER Xtightvnc || pgrep -U $USER vncserver; then
		# Ask user to run vncviewer or $WINDOW_MANAGER
		xmessage "Running vncviewer on localhost:1"
		WINDOW_MANAGER="vncviewer"
		# rm -f xinit.log
		WM_ARGS="-fullscreen -shared -passwd ~/.vnc/passwd -depth 24 localhost:1 >> $MY_LOG 2>&1"
	fi
	
	echo "-------------- .xinitrc: about to execute $WINDOW_MANAGER------------ `date +%c:%N`"
	# not sure if needed, but it doesn't hurt
	cd $HOME
	# PATH is being reset by /etc/Xsession.d/45xsession
	# source once here so that each term doesn't have to do it
	source $HOME/.bash_profile "manually sourced at top level"
	
	# found in /etc/X11/Xsession.d/45xsession: use XFT font system
	#export GDK_USE_XFT=1
	
	# start WINDOW_MANAGER accordingly
	case "$WINDOW_MANAGER" in
		vncviewer)
			eval $WINDOW_MANAGER $WM_ARGS &
			sleep 20
			xterm &
			exec twm || xterm  # need a basic window manager to move windows around
		;;
		*)
			for AGENT_PROG in gpg-agent ssh-agent; do
				if which "$AGENT_PROG" &> /dev/null; then
					SECURE_AGENT=$AGENT_PROG
					break
				fi
			done
			echo "Using SECURE_AGENT=$SECURE_AGENT"
	
			case "$SECURE_AGENT" in
				gpg-agent)
					# set "GPG_AGENT_INFO" before the GUI starts
					#xterm -e crypt.sh startAgent  # xterm  needed to enter password
					#. ~/bin/crypt.sh
					exec $WINDOW_MANAGER $WM_ARGS &
					MY_WMpid=$!
				;;
				ssh-agent)
					if [ "$SSH_AGENT_PID" ] || pgrep -U $USER "$SECURE_AGENT" > /dev/null; then
						# TODO: verify SSH_AGENT is working (perhaps by sourcing bin/ssh)
						# $SECURE_AGENT already running
						exec $WINDOW_MANAGER $WM_ARGS &
						MY_WMpid=$!
						# MY_WMpid=$(xprop -root | grep "^_BLACKBOX_PID" | awk '{print $3}')
					else
						# occurs when called by startx
						# echo "!!!!!!!   Starting WM with $SECURE_AGENT"
						exec $SECURE_AGENT $WINDOW_MANAGER $WM_ARGS &
						MY_WMpid=$!
					fi
				;;
				*)
					xmessage -timeout 30 "!!! Unknown SECURE_AGENT=$SECURE_AGENT"
				;;
			esac

			# independent of WINDOW_MANAGER
			xterm.sh &
			sleep 1
			# independent of WINDOW_MANAGER's autostart feature
			source "$HOME/.xautostart" &
			wait $MY_WMpid
			RETURN_VAL=$?
			# if WINDOW_MANAGER returns non-zero, open a backup
			if [ $RETURN_VAL -ne 0 ]; then
				xmessage -timeout 30 "$WINDOW_MANAGER $WM_ARGS returned $RETURN_VAL! \n Starting backup wm or xterm." && \
				twm || xterm
			fi
		;;
	esac
	
	# X client (and server if no more clients?) quits once this script exits.
	source "$HOME/.xautostop" >> xautostop.log
fi

