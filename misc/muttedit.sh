#!/bin/sh -u
#
# Spawn a mutt to edit a message and dispatch a reply in screen.
# This lets you detach from an unfinished reply and finish it later.
# Then just put "set editor=muttedit". Have to unset it for edit-message.
#	- Cameron Simpson <cs@zip.com.au> 31mar2006
# 

: ${TMPDIR:=/tmp}

cmd=$0
usage="Usage: $cmd filename"

[ $# = 1 ] || { echo "$usage" >&2; exit 2; }
filename=$1; shift
[ -s "$filename" ] || { echo "$cmd: expected non-empty file, got: $filename" >&2; exit 2; }

now=`date '+%d%b%Y-%H:%M'|tr '[A-Z]' '[a-z]'`
subj=`sed -n -e '/^$/q; /^[Ss]ubject:/{ s/^[^:]*:[ 	]*//; s/[^a-zA-Z0-9]/_/g; s/___*/_/g; p; q; }' <"$filename" | cut -c1-20`

set -x

#  IMAPFILE=`pwd-agent.sh decryptFile imap 1`
#  # echo $IMAPFILE
#  [ -f "$IMAPFILE" ] || { echo "$IMAPFILE doesn't exists!"; exit 1; }
#  ARGS="-e 'source $IMAPFILE'"


exec xterm -e mutt -e 'set editor="vim -s $HOME/.vim/scripts/mutt-compose.vim %s"' -H "$filename" &
sleep 2

