DRIVE=${1:-/dev/hda}
MOUNTPOINT="/"
PARTITIONS=`/usr/sbin/parted $DRIVE p | grep "ext[23]" | cut -f 1 -d " "`
for p in $PARTITIONS ; do
	echo "Scanning $DRIVE$p"
	mount $DRIVE$p $MOUNTPOINT
	if [ -d /etc ] ; then
		echo "   found /etc"
		break
	else
		umount $MOUNTPOINT
	fi
done
