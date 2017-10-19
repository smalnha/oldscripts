#!/bin/bash

cd
case "$1" in
	MyMail*)
		pgrep offlineimap || xterm -geometry 80x33+0-0 -e offlineimap &
		if [ "$DISPLAY" ]; then
			xterm -geometry 130x30+0-0 -T MyMail -name email -e mutt -F ~/.mutt/muttrc-MyMail
		else
			mutt -F ~/.mutt/muttrc-MyMail
		fi
	;;
	*|imap)  
		if [ "$DISPLAY" ]; then
			xterm -geometry 130x30+0-0 -T Email -name email -e mutt
		else
			mutt
		fi
	;;
esac

