#!/bin/bash

#
# This script has features similar to ssh-agent.
# The idea is to save passwords for future use in scripts and such.
# Don't want to put passwords on command line, because that's easily seen using 'ps'.
# - Initially the user enters passwords (and any other type of data) and this is saved to a file.
# - The file is encrypted using a no password key that only the user has (unless someone gets it).
#		 UPDATE: using gpg-agent, we can use the normal key without entering the password every time
# - The file is decrypted when needed using the key.
# 
# Uses:
# - mutt config file with password setting
# - Samba credential file with password
#
# Encrypted file can be kept around (original design uses no password key) 
# or can be created every time (made convenient by gpg-agent).
#

KEYRING="pwdagent"
GPGKEYID="$GPGID"

PSSWDDIR="${TEMP:-/tmp}"
PSSWDFILE="$PSSWDDIR/tmp.$KEYRING-$2"


case "$1" in
	tempFile)
		cat > "$PSSWDFILE"	# from stdin
		echo "$PSSWDFILE"
		{
			sleep ${3:-5}	# file will self-destruct in 5 seconds
			rm -f "$PSSWDFILE"
		} &> /dev/null &
		exit
	;;
	find)
		# using '--max-count=1' for grep causes "gpg: Broken pipe" error
		gpg --quiet -r $GPGID --decrypt "${SNOTES:-$HOME/.mysnotes.asc}" | grep "$2" | head -1 | awk 'BEGIN { FS = ":" } ; { print $3; }'
		exit
	;;
	shutdown)
	  	rm -f "$PSSWDDIR"/tmp.*
	  	exit
	;;
	getTrapCommand){
	  	#echo "Setting trap for calling script: $0"
	  	echo "trap 'echo \"pwd-agent: Cleaning up.\"; pwd-agent.sh doneWithFile \"$2\"; exit' TERM INT KILL;"
	  	exit 0
	};;
	existsFile)
	  	if [ -f "$PSSWDFILE.asc" ]; then
	  		echo "$PSSWDFILE.asc exists."
	  		exit 0
	  	else 
	  		exit 1
	  	fi
	  	[ -f "$PSSWDFILE.asc" ]
	  	exit
	;;
	doneWithFile)
	  	[ -f "$PSSWDFILE" ] || xmessage "$PSSWDFILE not found!	Remove manually."
	  	rm -f "$PSSWDFILE"	
	  	exit
	;;
	forgetFile)
	  	rm -f "$PSSWDFILE.asc"
	  	exit
	;;
esac




#echo "pwd-agent.sh $*" > /dev/stderr
GNUPGPDIR="$HOME/.gnupg"
#GPGARGS="--no-default-keyring --secret-keyring $GNUPGPDIR/$KEYRING.sec --keyring $GNUPGPDIR/$KEYRING.pub"
#GPGKEYID="nopass"

createNoPassGPGkey(){
	if ! gpg $GPGARGS --list-secret-keys "$GPGKEYID" > /dev/null; then
		 # secret key for user "GPGKEYID" does not exist
		 read -p "About to generate '$GPGKEYID' and add it to your gnupg DB. (Ctrl-C to quit)"
		 #createKey
			 pushd "$GNUPGPDIR"
			 cat >$KEYRING <<-EOF
					%echo Generating a standard key
					Key-Type: DSA
					Key-Length: 1024
					Subkey-Type: ELG-E
					Subkey-Length: 1024
					Name-Real: No Pass
					Name-Comment: auto generated for GMail check
					Name-Email: $GPGKEYID@pwd-agent.org
					Expire-Date: 0
					# Passphrase: 
					%pubring $KEYRING.pub
					%secring $KEYRING.sec
					# Do a commit here, so that we can later print "done" :-)
					%commit
					%echo done
EOF
				gpg --batch --gen-key $KEYRING
				rm -f $KEYRING
				popd
		 read -p "Press a key to continue."
	fi
}
#createNoPassGPGkey

# need "--trust-model always" since it was automatically created (and it's already signed)
#GPGTRUST="--trust-model always"
#GPGTRUST="--always-trust"

case "$1" in
	inputFile)
	# some apps (running as root or setuid) cannot access encrypted fs
 	SAFEDIR=`mount | grep --max-count 1 "^encfs" | cut -d" " -f 3`
 	[ -d "$SAFEDIR" ] || SAFEDIR="$TEMP"
 	[ -w "$SAFEDIR" ] || SAFEDIR="$HOME/.gnupg"
 	TEMPFILE="$SAFEDIR/tmp.$KEYRING-$2"

		cat > "$TEMPFILE"	# from stdin
		[ -f "$TEMPFILE.asc" ] && rm "$TEMPFILE.asc"
		gpg $GPGARGS -sea --local-user "$GPGKEYID" -r "$GPGKEYID" $GPGTRUST	"$TEMPFILE"
		ENCRYPTED=$?
		chmod go-rwx "$TEMPFILE.asc"
		mv "$TEMPFILE.asc" "$PSSWDFILE.asc" 
		[ -f "$TEMPFILE" ] && rm -f "$TEMPFILE"
		[ $ENCRYPTED -eq 0 ] || { echo "Could not encrypt $TEMPFILE."; exit 1; }
		{
			sleep ${3:-1h}	# encrypted file will self-destruct in 1hour
			rm -f "$PSSWDFILE.asc"	
		} &> /dev/null &
	;;
	decryptFile)
		if ! [ -e "$PSSWDFILE" ]; then
			# no password required		# ignore spurious output
			gpg $GPGARGS --quiet $GPGTRUST "$PSSWDFILE.asc" 2>&1 | grep -v -e "Good signature" -e "Signature made"
			chmod go-rwx "$PSSWDFILE"
			{
				sleep ${3:-5}	# decrypted file will self-destruct in 5 seconds
				rm -f "$PSSWDFILE"	
			} &> /dev/null &
		fi
		echo "$PSSWDFILE"
	 ;;
esac




