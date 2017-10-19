#!/bin/bash

# mount [--unmount] [-i interface] [location] 

# use $MY_LOCATION variable; possible values "home", "lips", "cheryl", ""

getLocation(){
	if /sbin/ifconfig $1 | grep -q '146.6.53.' ; then 
		myecho "location=lips"
		# mount phillips directories
		[ "$NFSMOUNT" ] && setLabMounts; mountall
	elif /sbin/ifconfig $1 | grep -q '192.168.100.' ; then
		myecho "location=home: Adding default gw to route table"
	else
		myecho "Unknown network; not mounting any dirs:"
		/sbin/ifconfig $1
	fi
}

sethomeMounts(){
	MOUNTS=($MY_HOMEMACHINE:/home )
	MOUNTDIRS=(/mnt/$MY_HOMEMACHINE/home )
}
setlabMounts(){
	MOUNTS=($MAINSERVER:/raid/installationFiles $MAINSERVER:/raid/home)
	MOUNTDIRS=(/mnt/installationFiles /mnt/$MAINSERVER/home)
}

mountall(){
	let arrSize=${#MOUNTS[*]}
	[ $arrSize -eq 0 ] && return 1
	myecho "Mounting $arrSize directories:"
	let i=0
	while [ $i -lt $arrSize ] ; do
		if [ ! -d "${MOUNTS[$i]}" ] ; then 
			mkdir -v "${MOUNTS[$i]}"
		fi
		myecho "Trying to mount ${MOUNTS[$i]} -> ${MOUNTDIRS[$i]}"
		sudo mount ${MOUNTS[$i]} ${MOUNTDIRS[$i]}
		let i=$i+1
	done
}
unmountall(){
	let arrSize=${#MOUNTS[*]}
	[ $arrSize -eq 0 ] && return 1
	myecho "Unmounting $arrSize directories:"
	let i=0
	while [ $i -lt $arrSize ] ; do
		if [ -d "${MOUNTS[$i]}" ] ; then 
			myecho "Trying to unmount ${MOUNTS[$i]} -x-> ${MOUNTDIRS[$i]}"
			sudo umount ${MOUNTS[$i]}
		else
			myecho "Skipping ${MOUNTDIRS[$i]}: does not exists"
		fi
		let i=$i+1
	done
}

set${MY_LOCATION}Mounts
echo "${MOUNTS[*]}"
