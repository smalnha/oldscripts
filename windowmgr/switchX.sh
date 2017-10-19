
if [ "$1" ]; then
	DRIVER=$1
elif lsmod | grep -q "nvidia" ; then
	DRIVER="nv"
else
	DRIVER="nvidia"
fi

echo "Switching to $DRIVER"

# killall kdm

cd /usr/X11R6/lib/modules/extensions || exit 1
if [ "$DRIVER" == "nvidia" ]; then
	# use nvidia driver
	sudo modprobe nvidia
	# [ ! -f libglx.so ] && cp baklib-glx.so.$DRIVER libglx.so
else
	sudo modprobe -r nvidia
	# use regular nv driver
	# [ ! -f libGLcore.a ] && cp baklib-GLcore.a.$DRIVER libGLcore.a
	# [ ! -f libglx.a ] && cp baklib-glx.a.$DRIVER libglx.a
fi

#sudo cp /etc/X11/XF86Config-4{.$DRIVER,}




