#!/bin/bash

ARCHIVES_DIR="$HOME/NOBACKUP/archives/"
USBKEY="$ARCHIVES_DIR/usbKey"
CONNECTED_MACHINE=$MY_LIPSMACHINE

makeScript(){
	WGETSCRIPT="./wget-script-`date +%Y-%m-%d-%T`.sh"
	echo [ Press no when prompted, make sure you are happy with the actions ]
	if [ -z "$*" ] ; then
		APTGET_COMMAND=upgrade
	else 
		APTGET_COMMAND=$@
	fi
	#sudo apt-get $APTGET_COMMAND
	if [ "$? -eq 1" ]; then # if answered no
		echo "# $APTGET_COMMAND" > $WGETSCRIPT
		echo "OLDDIR=`date +%Y-%m-%d-%T`" >> $WGETSCRIPT
		echo "mkdir \"\$OLDDIR\" && mv -v *.deb \"\$OLDDIR\"" >> $WGETSCRIPT
		echo "read -p \"Hit Enter to continue:\"" >> $WGETSCRIPT
		
		# assume file doesn't change, so that continue works
		# --continue --no-clobber
		sudo apt-get -qq --print-uris $APTGET_COMMAND | awk '{print "[ -f \"" $2 "\" ] || wget --output-document=" $2 " " $1}' >> $WGETSCRIPT

		echo "read -p \"Insert USB key & Hit Enter to copy *.deb files to $USBKEY/archives:\"" >> $WGETSCRIPT
		echo "mkdir \"$USBKEY/archives\"" >> $WGETSCRIPT
		echo "cp -v *.deb \"$USBKEY/archives\"" >> $WGETSCRIPT

		echo "read -p \"Hit Enter to move script $WGETSCRIPT to $USBKEY/archives:\"" >> $WGETSCRIPT
		echo "mv -v $WGETSCRIPT \"$USBKEY/archives\"" >> $WGETSCRIPT

		chmod +x $WGETSCRIPT
		echo "$WGETSCRIPT written"
		echo "$APTGET_COMMAND" >> $MY_BIN/aptget.history
		if [ "$CONNECTED_MACHINE" != "$HOSTNAME" ] && ping -c 1 $CONNECTED_MACHINE; then
			echo "Copying $WGETSCRIPT to $CONNECTED_MACHINE:$ARCHIVES_DIR"
			echo "   scp $WGETSCRIPT $CONNECTED_MACHINE:$ARCHIVES_DIR"
			scp $WGETSCRIPT "$CONNECTED_MACHINE:$ARCHIVES_DIR" && rm $WGETSCRIPT
		fi
	else
		echo "No script written"
	fi
}

#copy files to /var/cache/apt/archives and do normal aptget found in aptget.history

#echo "doAptGets"
doAptGets(){
	# read in aptget.history & execute each command
	cat $MY_BIN/aptget.history | while read APTGET_CMD PKG; do
		if [ "$PKG" == "upgrade" ]; then
			# only upgrade packages that we have debs for
			APTGET_PARAM="-o dir::cache::archives=$ARCHIVES_DIR --ignore-missing --no-download"
		else
			# download if needed
			APTGET_PARAM="-o dir::cache::archives=$ARCHIVES_DIR"
		fi

		echo "---- apt-get $APTGET_PARAM $APTGET_CMD ----"
		if read -p "Enter to continue"; then
			eval apt-get $APTGET_PARAM $APTGET_CMD
		fi
	done
}

if [ "$1" ] ; then 
	case "$1" in
		install | upgrade | dist-upgrade )
			eval makeScript "$@"
		;;
		history)
			doAptGets
		;;
	esac
else
	echo "aptget.sh [install|upgrade|dist-upgrade] "
fi

exit 0
#-------------------------------------------
echo"
copyAptArchives(){
	# echo "Copy apt archives?"
	SRC_PREFIX=${1:-/}
	DEST_PREFIX=${2:-/mnt/usb/apt}
	# mount $IPofARCHIVE:/var $DEST_PREFIX
	rsync --archive -v  $SRC_PREFIX/var/cache/apt/archives $DEST_PREFIX/var/cache/apt/archives
	rsync --archive -v $SRC_PREFIX/var/lib/apt/lists  $DEST_PREFIX/var/lib/apt
	mv -iv /etc/apt/sources.list{,.bak}
	echo "Copying over /etc/apt/sources.list"
	# ssh $IPofARCHIVE "cp /etc/apt/sources.list /var"
	rsync --archive -v $SRC_PREFIX/etc/apt/sources.list $DEST_PREFIX/etc/apt
	if [ -f /mnt/tmp/sources.lst ] ; then
		echo " /mnt/tmp/sources.list does not exists"
		echo " You need to 'cp /etc/apt/sources.list /var' on $IPofARCHIVE"
		read
	fi	
	cp -iv /sources.list /etc/apt
	# umount /mnt/tmp
}
"
