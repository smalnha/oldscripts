#!/bin/bash

MOUNTTABLE="${MY_BINSRC:-.}/mnttab"

[ -f "$MOUNTTABLE" ] || { echo "$MOUNTTABLE file not found!"; exit 1; }

TARGET="$1"
if [ -d "$TARGET" ]; then
	FIELDNAME=RELMOUNTPT
else
	FIELDNAME=RELMOUNTPT
fi

MOUNTBASEDIR="$HOME/.my_links/mntDir"
MOUNTPT="$MOUNTBASEDIR/$TARGET"
[ -d "$MOUNTPT" ] || mkdir -p "$MOUNTPT"

case "`basename $0`" in
	m*nt*) DIRECTIVE=mount ;;
	u*m*nt*) DIRECTIVE=umount ;;
	*) echo "=== Unknown mount command: $DIRECTIVE" >&2 && exit 1	;;
esac

# may require user input
getSambaKey(){
	AUTOMNT_KEY="$1"
	case "$AUTOMNT_KEY" in
		silver* )
			searchString="^samba-home:$USER"
			;;
		nopassword)  # no credentials needed
			return 0
			;;
		*)	echo "=== Unknown Samba lookup key for: $AUTOMNT_KEY" >&2
			exit 301
			;;
	esac

	export USETEMPDIR=true
	PASSWD=`crypt.sh find "$searchString" | awk 'BEGIN { FS = ":" } ; { print $3; }'`
  	if [ "$PASSWD" ]; then
		echo "$PASSWD"
#   		echo "
# username=$ME
# password=${PASSWD##*:}
# domain=ARLUT
# " | pwd-agent.sh tempFile smb-"$AUTOMNT_KEY"  # this will echo the filename
# 		unset PASSWD
	else
		echo "SMB_password_not_found-$searchString" >&2
		exit 302
	fi
	unset USETEMPDIR
}

processLine(){
	MACHINENAME="$1"
	DIR="$2" 
	RELMOUNTPT="$3"
	FSTYPE="$4"
	TTL="$5"
	MNTOPTIONS="$6"
	eval FIELDVALUE="\${$FIELDNAME}"
	if [ "$FIELDVALUE" == "$TARGET" ]; then
		[ "$MNTOPTIONS" ] && OPTIONS_SEPARATED="`eval echo "-o ${MNTOPTIONS//,/ -o }"`"
		[ "$VERBOSE" ] && echo "$DIRECTIVE $FIELDVALUE $MACHINENAME;$DIR;$RELMOUNTPT;$FSTYPE;$TTL;$OPTIONS_SEPARATED"

		case "$FSTYPE" in
		SSHFS|ssh*)
			# links don't consistently appear, but you can cd to them
			# sshfs host:dir mountpoint -o idmap=user -o follow_symlinks
			case "$DIRECTIVE" in
			mount)
				MCOMMAND="sshfs \"$MACHINENAME:$DIR\" \"$MOUNTPT\" -o idmap=user -o follow_symlinks $OPTIONS_SEPARATED" ;;
			umount)
				MCOMMAND="fusermount -u \"$MOUNTPT\"" ;;
			esac
			;;
		SMBFS|CIFS|smb*|cifs)
			# SETUP: 
			if ! [ -f /sbin/mount.cifs ] || ! [ -f /sbin/umount.cifs ]; then
				echo "/sbin/[u]mount.cifs doesn't exists!!!  apt-get install smbfs" >&2
				exit 880;
			fi

			if ! [ -u /sbin/mount.cifs ] || ! [ -u /sbin/umount.cifs ]; then
				#echo "Need to set uid stick bit for mount.cifs and umount.cifs:"
				xterm -e sudo chmod u+s /sbin/{,u}mount.cifs
			fi
			case "$DIRECTIVE" in
			mount)
				#export PASSWD="`getSambaKey $RELMOUNTPT`" || exit 210
				echo "Enter password to access remote SAMBA host."
				MCOMMAND="mount.cifs \"//$MACHINENAME/$DIR\" \"$MOUNTPT\" $OPTIONS_SEPARATED" ;;
			umount)
				# must use absolute, non-linked directory as listed in mtab
				MCOMMAND="umount.cifs \"$(readlink -f "$MOUNTPT")\"" ;;
			esac
			;;
		*)	exit 222 ;;
		esac
#echo $PASSWD
		# unset it so that the password is asked
		[ -z "$PASSWD" ] && unset PASSWD
		echo $MCOMMAND
		eval $MCOMMAND
		RETVAL=$?
		unset PASSWD
		return $RETVAL
	fi
	return 888  # not found
}

grep -v "^[[:space:]]*#" "$MOUNTTABLE" | { 
	while read FIRST LINE; do
		case "$FIRST" in
		set)
			eval $LINE
			;;
		*) # eval needed to process variables
			eval processLine $FIRST $LINE
			RETVAL=$?
			#echo "$FIRST $LINE $RETVAL"
			case "$RETVAL" in
				0) exit 0 ;; # success
				888 | 120) ;;  # go to next line
				*) exit $RETVAL ;;
			esac
			;;
		esac
	done
	exit 101
}
RETVAL=$?
case "$RETVAL" in
	0) if [ "$DIRECTIVE" == "mount" ] && [ "${POSTMOUNT:=xterm.sh}" ]; then
			pushd "$MOUNTPT" > /dev/null
			if [ "$PS1" ]; then
				eval "$POSTMOUNT" &
				popd > /dev/null
				read -p "Umount $TARGET? [Y]" && umnt.sh "$TARGET"
			else
				eval "$POSTMOUNT"
				popd > /dev/null
				umnt.sh "$TARGET" && xmessage -timeout 2 "Done umounting $TARGET."
			fi
		fi
		;;
	1) echo "=== Mounting failed: $MOUNTPT" >&2	;;
	101) echo "=== '$TARGET' not found in $MOUNTTABLE" >&2 ;;
	130) echo "=== Problem with GPG" >&2 ;;
	210) echo "=== Could not get Samba credentials for $TARGET" >&2 ;;
	222) echo "=== Unknown filesystem type: $FSTYPE" >&2 ;;
	255) echo "=== Could not get Samba password for $TARGET or some other problem" >&2 ;;
	*) echo "=== Unknown return value=$RETVAL" >&2 ;;
esac


