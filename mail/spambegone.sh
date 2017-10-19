#!/bin/bash

case $1 in
    utexas.edu)
        IMAPSERVER=mailboxes.utexas.edu
        SPAMINBOX=Junk
    ;;
    default | "")
        read -p "Please specify the IMAP server!"
        exit 1
    ;;
esac

shift

echo "----------------------------------
IMAP Spam Be-Gone
"

eval `pwd-agent.sh isbg getTrapCommand`
if ! [ "`pwd-agent.sh isbg existsFile`" ]; then
   echo "isbg.py's IMAP password file not found.  Please enter password."
   PSWDFILE=$HOME/.isbg-$IMAPSERVER.imap
   $HOME/.spamassassin/imapspambegone.py --savepw --verbose --imaphost $IMAPSERVER --spaminbox $SPAMINBOX --passwordfilename $PSWDFILE --delete --expunge
   cat $PSWDFILE | pwd-agent.sh isbg inputFile
   rm -f $PSWDFILE
else
   PSWDFILE=`pwd-agent.sh isbg decryptFile`
   $HOME/.spamassassin/imapspambegone.py --verbose --imaphost $IMAPSERVER --spaminbox $SPAMINBOX --passwordfilename $PSWDFILE --delete --expunge
   pwd-agent.sh isbg doneWithFile
fi

