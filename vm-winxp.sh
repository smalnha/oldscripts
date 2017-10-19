vmFile="$HOME/.vmware/vmWinXP/vm-winXP.vmx"
source ~/.bash_profile;
if [ "${HOSTNAME}" = "$MY_LIPSMACHINE" ] ; then	
	exec ssh -t backflips "bin/vm-winxp.sh"
elif [ "$HOSTNAME" = "$MY_HOMEMACHINE" ] ; then
	if [ ! -e $vmFile ] ; then
		echo "Mounting /mnt/10GB ..."
		mount /mnt/10GB
	fi
fi

if [ "$HOSTNAME" = "$MY_HOMEMACHINE" ] || [ "$HOSTNAME" = "knop" ] ; then
	if [ -f "$vmFile" ] ; then
		exec vmware -x "$vmFile"
	else
		xmessage "Sorry, Could not find $vmFile."
	fi
else
	xmessage "$HOSTNAME is not in the list of machines with vmware; see vm-winxp.sh"
fi
