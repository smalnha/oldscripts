lsusb -v || usbview

USB_MOUNTPT=/mnt/usb

if ! mount | grep "$USB_MOUNTPT" || [ "$1" == "-m" ] ; then 
	USB_MOUNT="true"
fi

if [ "$USB_MOUNT" ] ; then
	# not mounted
	if ! mount $USB_MOUNTPT; then 
		xmessage "Could not mount $USB_MOUNTPT."; 
	else 
		exec xfe $USB_MOUNTPT
	fi
else
	if ! umount $USB_MOUNTPT; then 
		xmessage "Could not unmount $USB_MOUNTPT."; 
	else 
		xmessage -timeout 1 "Unmounted $USB_MOUNTPT."; 
	fi
fi

