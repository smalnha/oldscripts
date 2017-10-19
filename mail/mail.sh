#!/bin/bash

notify(){
    # returns 0 if timeout
    xmessage -timeout $1 -buttons "View:1,Ignore:0" -default "Ignore" -file -    
}

: ${GMAILUSER:=myUserName}

case "$1" in
    notify)
        echo "New mail!" | notify 5 || mail.sh
        exit 0
    ;;
    check)
        [ "$MY_MAILSERVER" ] || { echo "MY_MAILSERVER not set."; exit 1; }
        # output the same as 'fetchmail -c' would
        if which osd_cat > /dev/null; then
            echo "Checking mail `date`" | osd_cat --pos=middle --indent=10 --color=yellow --shadow 4 - &
            MESS_PID=$!
        else
            xmessage -geometry +0+0 "Checking mail" &
            MESS_PID=$!
        fi
        if [ "$USEIMAP" ]; then
            echo -e "0 select inbox\n1 logout" | imapd > imapd.log
            TOTALMSG=`grep -n 1 " EXISTS" imapd.log | awk '{print $2}'`
            NEWMSG=`grep -n 1 " RECENT" imapd.log | awk '{print $2}'`
        else
            ssh $MY_MAILSERVER 'TOTALMSG=`grep "^From " /var/spool/mail/$USER | wc -l`; READMSG=`grep "^Status: R" /var/spool/mail/$USER | wc -l`; echo -n $TOTALMSG messages \(; echo $READMSG seen\) for $USER at $HOSTNAME' 
        fi
        #[ $TOTALMSG = $READMSG ] 
        kill $MESS_PID
        exit 0
    ;;
    checkGMail) shift
        TMPFILE="${1:-/tmp/checkGMail.xml}"
        #mv -f "$TMPFILE"{,.bak}
        [ -f "$TMPFILE" ] && rm -f "$TMPFILE"

        if which osd_cat > /dev/null; then
            echo "Checking GMail `date`" | osd_cat --pos=middle --indent=10 --color=yellow --shadow 4 - &
            MESS_PID=$!
        else
            xmessage -geometry +0+0 "Checking GMail" &
            MESS_PID=$!
        fi
        eval `pwd-agent.sh getTrapCommand gmail`
        { # this should be atomic
            URLFILE=`pwd-agent.sh decryptFile gmail`
            [ -f "$URLFILE" ] || { rm -f "$TMPFILE"; exit 1; }
            # cat "$URLFILE" 
            wget -q -i "$URLFILE" --output-document="$TMPFILE"
            pwd-agent.sh doneWithFile gmail
            cp $TMPFILE{,.debug}
        }
        if [ -f "$TMPFILE" ]; then
            tidy -q -xml -indent -wrap 120 -m "$TMPFILE"
            #cat "$TMPFILE"
            sed --quiet -i "/entry/,/entry/p" "$TMPFILE"
            # if file is not empty 
            if [ -s "$TMPFILE" ] ; then #&& diff -q "$TMPFILE"{,.bak} ; then
                {
                echo "You have `grep -c "<entry>" "$TMPFILE"` NEW messages!"
                grep -e "<title>" -e "<name>" -e "<email>" "$TMPFILE" 
                } | notify 20 || $BROWSER "http://gmail.google.com"
            fi
        fi
        # if called without arguments (like in th case of command-line call)
        [ -z "$1" ] && rm -f "$TMPFILE"
        exit 0
    ;;
    checkGMailLoop) shift
        TMPFILE="${1:-/tmp/checkGMailLoop.xml}"
        CHECKDELAY="${2:-10m}"     # check every 5 min by default
        touch $TMPFILE || echo "Could not create $TMPFILE !!!"
        while [ -f "$TMPFILE" ]; do
            mail.sh checkGMail "$TMPFILE"
            [ -f "$TMPFILE" ] && sleep $CHECKDELAY  # file can be removed to stop checking
        done
        # if called without arguments (like in th case of command-line call)
        [ -z "$1" ] && rm -f "$TMPFILE"
        echo "Stopped checking GMail at `date`"
        exit 0
    ;;
    startGMailLoop) shift
        TMPFILE="/tmp/gmail-$GMAILUSER.xml"

        eval `pwd-agent.sh getTrapCommand gmail`
        if ! pwd-agent.sh existsFile gmail; then
            GMAILPASSWD=`gpg --quiet -r $GPGID --decrypt "${SNOTES:-$HOME/.mysnotes.asc}" | grep "^gmail.com:$GMAILUSER:"`
            [ "$GMAILPASSWD" ] || exit 222
            echo "https://$GMAILUSER:${GMAILPASSWD##*:}@mail.google.com/mail/feed/atom" | pwd-agent.sh inputFile gmail
            unset GMAILPASSWD GMAILUSER
        fi

        pkill -f "mail.sh checkGMailLoop"
        if pwd-agent.sh existsFile gmail; then
            mail.sh checkGMailLoop "$TMPFILE"
        fi
        exit 0
    ;;
    stopGMail)
        TMPFILE="/tmp/gmail-$GMAILUSER.xml"
        rm -f "$TMPFILE"
        pkill -f "mail.sh checkGMailLoop"
        pwd-agent.sh forgetFile gmail 
        exit 0
    ;;
esac

#echo "[mail.sh] `ps -A`" > ~/mtest
#env >> ~/mtest
#echo $TERM $HOSTNAME $MY_MAILSERVER >> ~/mtest
#exit 0

case $HOSTNAME in
    *ece.utexas.edu) 
        searchString="^UT Direct-EID:$USER:"
    ;;
    *)
      read -p "No searchString for host $HOSTNAME!! Please add it to mail.sh";
      exit 1;
    ;;
esac

MAILCLIENT="mutt"

case $MAILCLIENT in
    pine) ATTACHOPTION="-attach";;
    mutt) ATTACHOPTION="-a"
        #eval `pwd-agent.sh getTrapCommand imap`
        if ! [ "`pwd-agent.sh existsFile imap`" ]; then

				# causes pinentry-curses to be used
				#if which pinentry-curses > /dev/null; then 
				#	export GPGAGENT_ARGS="--pinentry-program $(which pinentry-curses)"
				#fi

				crypt.sh mount private 0 && trap "crypt.sh umount private" TERM KILL QUIT EXIT
            IMAPPASSWD=`gpg --quiet -r $GPGID --decrypt "${SNOTES:-$HOME/.mysnotes.asc}" | grep "$searchString" | awk 'BEGIN { FS = ":" } ; { print $3; }'`
            if [ "$IMAPPASSWD" ]; then
                IMAPFILE=`echo "set imap_pass=\"${IMAPPASSWD##*:}\"" | pwd-agent.sh inputFile imap 8h`
                unset IMAPPASSWD
					echo "Success."
            else
               echo "IMAP password not found: '$searchString'"
            fi
        else
            echo "imap gpg file exists"
        fi
    ;;
    *) echo "mail.sh: Unsupported mail client=$MAILCLIENT"; exit 1;;
esac
for ARG in "$@"; do
	case "$ARG" in
		-attach)
		;;
		/*)
			if [ -f "$ARG" ]; then
                ATTACHMENTS="${ATTACHMENTS} $ATTACHOPTION $ARG"
			fi
		;;
		*)
			if [ -f "$PWD/$ARG" ]; then
                ATTACHMENTS="${ATTACHMENTS} $ATTACHOPTION $PWD/$ARG"
			else 
				ARGS="$ARGS $ARG"
			fi
		;;
	esac
done
ARGS="$ARGS $ATTACHMENTS"
#read -p "ARGS=$ARGS"


# $MY_MAILSERVER is not immediately set when executing via ssh
if false && [ "$obsolete_after_Exchange_transition" ] && [ "$MY_MAILSERVER" ] && [ "$HOSTNAME" != "$MY_MAILSERVER" ]; then 
	#! ps -u $USER | grep "mozilla" &&
	#echo $HOSTNAME $MY_MAILSERVER
	MAILCMD="ssh -t $MY_MAILSERVER bin/mail.sh $ARGS"
else
	# so that open.sh and other scripts can be found
	source /etc/profile
	export PATH=$PATH:$HOME/bin

    case $MAILCLIENT in
        mutt)
        { # this should be atomic
            IMAPFILE=`pwd-agent.sh decryptFile imap 1`
            # echo $IMAPFILE
            [ -f "$IMAPFILE" ] || { echo "$IMAPFILE doesn't exists!"; exit 1; }
            ARGS="-e 'source $IMAPFILE' $ARGS"
        }
        ;;
    esac
    MAILCMD="$MAILCLIENT $ARGS"
fi

# It's ok to have more than 1 mutt running
if pgrep -U $USER mutt; then
   xmessage -timeout 5 "Note: $MAILCLIENT already running on $HOSTNAME." &
fi
# else
	USE_ELINKS=""
    if [ "$USE_ELINKS" ]; then # || [ "$MAILCLIENT" = "mutt" ] ; then 
        BROWSER="text" eval $MAILCMD
    else
        eval $MAILCMD
    fi

    if [ -s "$HOME/Mail/AA_toGMail" ]; then
        emailer.sh
    fi
# fi


