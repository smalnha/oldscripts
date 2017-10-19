#!/bin/bash

if ! [ "$1" = "init" ]; then
   FTPCMDS=`mktemp -p $HOME -t ftp.sh.XXXXXX` || exit 2
   cat > $FTPCMDS
   trap "rm -f $FTPCMDS" TERM EXIT
fi

#if [ "$DISPLAY" ]; then
#   if grep -q '^Content-Type:.*multipart' $FTPCMDS || ! grep -v '^>' $FTPCMDS | grep -q 'attach\|patch\|enclose' || xmessage -buttons "Yes:0,No:1" -default "No" "Send mail without attachment?" ; then
#      echo "Sending without attachment."
#   else
#      exit 3
#   fi
#fi

searchString="^netfirms.com:$MY_USERNAME.net:"
ftprcString="ftp.netfirms.com"

eval `pwd-agent.sh ftp getTrapCommand`

if [ "$searchString" ]; then
        FTPPASSWD=`gpg --quiet -r $GPGID --decrypt "${SNOTES:-$HOME/.mysnotes.asc}" | grep "$searchString" | awk -F ":" '{ print $3; }'`
        #echo FTPPASSWD=$FTPPASSWD
        [ "$FTPPASSWD" ] || { echo "Could not find password for ftp in snotes!"; exit 222; }
			NETRC="$HOME/private/encrypted/home/.netrc"
			ln -snf "$NETRC" "$HOME/.netrc"
			gpg --quiet "$NETRC.asc"
			sed -i "s/^#password ${ftprcString}.*/password ${FTPPASSWD##*:}/" "$NETRC"
      	unset FTPPASSWD

			{
				sleep 5
				rm -f "$NETRC"
			} &> /dev/null &

			if [ "$1" != "init" ]; then
				 ftp "$@" < $FTPCMDS
			fi

fi

