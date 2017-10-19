#!/bin/bash

#cat > ~/newmail.biff 
wmctrl -x -r gnubiff -b remove,hidden
play /usr/share/gnubiff/coin.wav
# pgrep -f "xmessage .* New mail" || xmessage -buttons "View:1,Ignore:0" -default "Ignore" "New email!" || xterm -name email -title "email" -e mail.sh

