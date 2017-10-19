 
if xmessage -buttons "Yes:0,No:1" -default "Yes" -timeout 10 "Exit?" ; then
   FLUXBOX_pid=`xprop -root _BLACKBOX_PID | awk '{print $3}'`
   kill -TERM $FLUXBOX_pid

#	if ! kill `ps --no-headers -C fluxbox -o pid` ; then
#		echo "killall $WINDOW_MANAGER"
#      read
#	fi
fi

logoff(){
	if [ "$DISPLAY" ] ; then
		if [ "$WINDOW_MANAGER" ] ; then
			local WMpid=`ps --no-headers -C $WINDOW_MANAGER -o pid` 
			kill $WMpid || killall $WINDOW_MANAGER || echo "Could not kill $WINDOW_MANAGER: `ps -AF`" >> ~/fluxbox.log
		else
			echo "WINDOW_MANAGER is not set.  It should have been set in .xinitrc to 'fluxbox'"
		fi
	else
		logout
	fi
}
#export -f logoff

asklogout(){
	if /sbin/getkey -c 3 -m $"Press a key within %d to stay connected "; then 
		echo "Staying connected "
	else 
		logout
	fi
}

