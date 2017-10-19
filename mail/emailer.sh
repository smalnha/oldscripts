#!/bin/bash

echo "
--------------------------------------------------------
--------------------------------------------------------"

#[ "$HOSTNAME" = "$MY_MAILSERVER" ] || { echo "Run this only on $MY_MAILSERVER."; exit 1; }
: ${EMAIL_USERNAME:=myUserName}

MAILDIR="$HOME/Mail"
GMailBox="$MAILDIR/AA_toGMail"
YahooBox="$MAILDIR/Yahoo_Inbox"

hotmail(){
	echo "-------- HotMail -------" 
	perl $MY_BINSRC/gotmail -p "$1" --folder-dir "$MAILDIR" --username "${EMAIL_USERNAME}"
	if [ -f "$MAILDIR/${EMAIL_USERNAME}" ]; then
        cat "$MAILDIR/${EMAIL_USERNAME}" >> "$GMailBox" 
        mv -f $MAILDIR/${EMAIL_USERNAME}{,.bak}
    fi
	echo "-------- HotMail done -------" 
}
yahoo(){
	echo "-------- Yahoo -------" 
    # see .fetchyahoorc
   if which fetchyahoo ; then
      fetchyahoo --password "$1" --spoolfile="$YahooBox"
   else
      perl $MY_BINSRC/fetchyahoo --password "$1" --spoolfile="$YahooBox"
   fi
    if [ -f "$YahooBox" ]; then
        cat "$YahooBox" >> "$GMailBox"
        mv -f "$YahooBox"{,.bak}
    fi
	[ -f yahoocal.html ] && mv -vf yahoocal.html $HOME/public_html/protected/
	echo "-------- Yahoo done -------" 
}
toGMail(){
   [ -e "$GMailBox" ] || { echo "$GMailBox does not exist."; return 1; }
	# no password needed
	NUM_EMAILS=`grep -c "^From " $GMailBox`
	echo "-------- to GMail ($NUM_EMAILS emails) -------" 
	# have to do some preprocessing of message sent from Pine, otherwise they are ignored by gml.py
	sed -i 's/\(^From .*\)\( -....\)/\1/' "$GMailBox"

	python "$MY_BINSRC/gml.py" mbox "$GMailBox" ${EMAIL_USERNAME}@gmail.com | tee $MY_TRASH/gml.log && \
		mv -f "$GMailBox" $MY_TRASH/toGMail.bak-`date +%Y-%m-%d-%T` && touch $GMailBox

	NUM_SUCCESS=`grep "Stats:" $MY_TRASH/gml.log | { read A B C D E; echo $C; }`
	if ! [ "${NUM_SUCCESS:--999}" -eq "$NUM_EMAILS" ]; then
		echo "!!!!!!!! Number of emails sent is NOT equal to number of emails !!!!!!!!! "
	fi
	echo "-------- to GMail done -------" 
}
mailall(){
    if ! pwd-agent.sh emailer existsFile; then
	    gpg --quiet -r $GPGID --decrypt "${SNOTES:-$HOME/.mysnotes.asc}" | grep --ignore-case -e "hotmail.com:${EMAIL_USERNAME}:" -e "Yahoo:${EMAIL_USERNAME2}:" | pwd-agent.sh emailer inputFile
    fi

    eval `pwd-agent.sh emailer getTrapCommand`
    local PSSFILE=`pwd-agent.sh emailer decryptFile`
    echo ========= $PSSFILE
    if [ -f "$PSSFILE" ]; then
        local ypwd=`grep "yahoo:${EMAIL_USERNAME2}:" $PSSFILE`
        yahoo ${ypwd##*:}
        ypwd=`grep "hotmail.com:${EMAIL_USERNAME}:" $PSSFILE`
        hotmail ${ypwd##*:}
        unset ypwd
    fi
    pwd-agent.sh emailer doneWithFile
    pwd-agent.sh emailer forgetFile

	toGMail
}

case "$1" in
    mailall | toGMail )
        $1
    ;;
    "") mailall
    ;;
    *)
	    $1
    ;;
esac

