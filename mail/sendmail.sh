#!/bin/bash

INMAIL=`mktemp -p $HOME -t sendmail.sh.XXXXXX` || exit 2
cat > $INMAIL
trap "rm -f $INMAIL" TERM EXIT

if [ "$DISPLAY" ]; then
   if grep -q '^Content-Type:.*multipart' $INMAIL || ! grep -v '^>' $INMAIL | grep -iq ' attach\|patch\|enclose' || xmessage -buttons "Yes:0,No:1" -default "No" "Send mail without attachment?" ; then
      echo "Sending without attachment."
   else
      exit 3
   fi
fi

case $HOSTNAME in
    ece.utexas.edu) 
        searchString="^UT Direct-EID:$MY_EID:"
        msmtprcString="AEMS"
    ;;
    *boom | shannon)
        #no authorization/password needed
        searchString=""
    ;;
esac

eval `pwd-agent.sh smtp getTrapCommand`

if [ "$searchString" ]; then
    if ! [ "`pwd-agent.sh smtp existsFile`" ]; then
        IMAPPASSWD=`gpg --quiet -r $GPGID --decrypt "${SNOTES:-$HOME/.mysnotes.asc}" | grep "$searchString" | awk --field-separator ":" '{ print $3; }'`
        #echo $IMAPPASSWD
        [ "$IMAPPASSWD" ] || { echo "Could not find password for smtp in snotes!"; exit 222; }
        sed "/^#password $msmtprcString/i password ${IMAPPASSWD##*:}" $HOME/.msmtprc | pwd-agent.sh smtp inputFile
        unset IMAPPASSWD
    else
        echo "File exists pwd-agent.sh smtp."
    fi
fi

[ "$1" = "init" ] && exit 100;

# perhaps we should source .bash_profile instead of searching for msmtp?
#echo "$PATH" >> ~/sendmail.log
if which msmtp; then
    SMTPCMD="msmtp"
else
    if [ -x /usr/bin/msmtp ] ; then
        SMTPCMD="/usr/bin/msmtp"
    elif [ -x "$MY_BIN/$HOSTNAME/msmtp" ] ; then
        SMTPCMD="$MY_BIN/$HOSTNAME/msmtp"
    fi
fi

[ "$SMTPCMD" ] && { # this should be atomic
  if [ "$searchString" ]; then
    SMTPFILE=`pwd-agent.sh smtp decryptFile`
    [ -f "$SMTPFILE" ] || { echo "$SMTPFILE not found!!" ; exit 1;}
    echo $SMTPCMD -d --file=$SMTPFILE "$@"
    $SMTPCMD -d --file=$SMTPFILE "$@" < $INMAIL
    pwd-agent.sh smtp doneWithFile
  else
    echo $SMTPCMD -d "$@"
    $SMTPCMD -d "$@" < $INMAIL
  fi
}


