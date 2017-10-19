if [ "$1" == "cd" ] ; then
	exec xmms /dev/cdrom
	# cdrom -> /dev/scd0
	# cannot mount audio cd's using iso9660
fi

if [ -d /mnt/music ] && [ ! -e /mnt/music/autosource ] ; then 
	mount /mnt/music/
fi
echo xmms $@
xmms "$@" &
