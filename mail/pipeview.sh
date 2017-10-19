#!/bin/bash

# used by mutt to view individual emails

TMPFILE=`tempfile -d ~/.mutt/muttcache/ --prefix=email-`
cat > $TMPFILE
xterm -title "email message" -e "vim -c 'set filetype=mail noautoindent' $TMPFILE && rm $TMPFILE" &

