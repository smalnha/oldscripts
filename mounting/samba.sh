#!/bin/bash

SMBLOG="-l $TEMP"
SMBTAB="$MY_BINSRC/sambaTab"
SMBMOUNTDIR="$TEMP/smb"

case "$1" in
	--completion_mount | --completion_umount)
		echo "compgen -A directory -- \$2"
		exit $COMPLETION_OPT
	;;
	--completion_list)
		echo "compgen -A hostname -- \$2"
		exit $COMPLETION_OPT
	;;
	--completion_list*)
		echo "echo _ PRESS_ENTER"
		exit $COMPLETION_OPT
	;;
	--completionCommand$COMPLETION_OPT)
		# each $KEYWORD should have a --completion_$KEYWORD option
		KEYWORDS="mount umount list listMachines listAll"
		[ "$CREATE_COMPLETION_SCRIPT" ] && $CREATE_COMPLETION_SCRIPT $0 "$KEYWORDS"
		exit $COMPLETION_OPT
	;;
	--completion_*)
		echo "echo _ UNDOCUMENTED_$1"
		exit $COMPLETION_OPT
	;;
	--help)
		echo "Usage: $0 COMMAND
 where COMMAND is one of the following:
   mount DIR                        mount a samba dir
   umount DIR                       unmount a samba dir
   list HOST                        list shared directories for machine
   listMachines                     list machines
   listAll                          list all info for all machines
 other OPTIONS
	--help
	--test
"
		exit 0
	;;
	mount | umount | list )
		SMB_CMD=$1
		shift;
		ARGS="$1"
		# echo ARGS="$ARGS"
		shift
	;;
	configure | listMachines | listAll )
		SMB_CMD=$1
		shift
	;;
	*)
		echo "Attempting to mount $1 ..."
      samba.sh mount "$1"
      echo ""
      df
      read -p "Press a key to unmount $1."
      samba.sh umount "$1"
		exit 0
	;;
esac

configureSmb(){  # smbmnt must be installed suid root
	sudo chmod u+s /usr/bin/{smbmnt,smbumount}
}

getMountOptions(){ # given mount point
	grep $1 $SMBTAB | {
		IFS=:
		read MACHINENAME DIRNAME MNTPT MNTOPT
		[ "$MNTPT" == "$1" ] && echo "$MNTOPT" && return 0
	}
}
getMountDevice(){ # given mount point
	grep "$1" $SMBTAB | { 
		IFS=:
		read MACHINENAME DIRNAME MNTPT MNTOPT
		#echo "====== $MACHINENAME, $DIRNAME, $MNTPT, $MNTOPT ====="
		if [ "$MNTPT" == "$1" ] ; then
			local IPaddr="`ping.sh -l $MACHINENAME`"
			if [ $? -eq 0 ]; then
				echo "//$IPaddr/$DIRNAME"
				return 0
			else
				return 1
			fi
		fi
		#echo read $MNTDEV, $MNTPT, $MNTOPT
	}
}

mountSmb(){
	local MOUNT_PT="$SMBMOUNTDIR/$1"
	[ -d "$MOUNT_PT" ] || mkdir -p $MOUNT_PT
	# smbmount //silver/Shared $MOUNT_PT -o password=""
	local MOUNT_DEV="`getMountDevice $1`"
	local MOUNT_OPTIONS="-o `getMountOptions $1`"
	echo smbmount dev=$MOUNT_DEV mount_pt=$MOUNT_PT options=$MOUNT_OPTIONS
	echo smbmount $MOUNT_DEV $MOUNT_PT $MOUNT_OPTIONS
	smbmount "$MOUNT_DEV" $MOUNT_PT $MOUNT_OPTIONS
	cd $MOUNT_PT
}

umountSmb(){
	local MOUNT_PT=$1
	[ -d $MOUNT_PT ] || MOUNT_PT=$SMBMOUNTDIR/$1
	smbumount $MOUNT_PT
}

listSmb(){
	[ -z "$1" ] && echo "Specify a [\\\\]SAMBA_MACHINE_NAME" && return 1;
	smbclient $SMBLOG -N -L $1
}
listMachinesSmb(){
	smbtree -N -S | grep "\\\\"
}
listAllSmb(){
	# smbtree -N
	smbtree -N -d | grep "\\\\"
}

smblookup(){
	nmblookup $1	
}

if [ "$SMB_CMD" ] ; then
	SMB_CMD=${SMB_CMD#--*}
	shift
	echo ${SMB_CMD}Smb $ARGS
	${SMB_CMD}Smb $ARGS
fi



