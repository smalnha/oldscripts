#!/bin/bash


xmessage -center -timeout 5 -buttons "OK:10,Cancel:0" -default "OK" "Suspend?"
returnCode=$?
if [ $returnCode -eq 10 ] ; then 
    klaptop_acpi_helper --suspend
fi

exit 0

	suspendLaptop(){
		echo "Resuming to text console doesn't work using this"
		klaptop_acpi_helper --suspend
	}

# http://gentoo-wiki.com/HOWTO_Getting_APM_Suspend_to_Work

sudo acpitool -s

#  S1 - "Stopgrant"
#  Power to cpu is maintained, but no instructions are executed. The CPU halts itself and may shut down many of its internal components. In Microsoft Windows, the "Standby" command is associated with this state by default.

#  S2
#  While defined in the spec, this state is not currently in use. It resembles S3 with the qualification that some devices are permitted to remain on.

#  S3 - "Suspend to RAM"
#  All power to the cpu is shut off, and the contents of its registers are flushed to RAM, which remains on. In Microsoft Windows, the "Standby" command can be associated with this state if enabled in the BIOS. Because it requires a high degree of coordination between the cpu, chipset, devices, OS, BIOS, and OS device drivers, this system state is the most prone to errors and instability.
#  Pavel Machek has created a small document with some hints how to solve problems with S3. You can find it in the kernel sources at Documentation/power/tricks.txt.
#  S3 is currently _not_ supported by the 2.4.x kernel series in Linux.

#  S4 - "Suspend to Disk"
#  CPU power shut off as in S3, but RAM is written to disk and shut off as well. In Microsoft Windows, the "Hibernate" command is associated with this state. A variation called S4BIOS is most prevalent, where the system image is stored and loaded by the BIOS instead of the OS. Because the contents of RAM are written out to disk, system context is maintained. For example, unsaved files would not be lost following an S4 transition.
#  S4 is currently _not_ supported by the 2.4.x kernel series in Linux, but you might have good luck with SWSUSP. Some machines offer S4_BIOS whose support is considered to be experimental within ACPI4Linux.

#  S5 - "Soft Off"
#  System is shut down, however some power may be supplied to certain devices to generate a wake event, for example to support automatic startup from a LAN or USB device. In Microsoft Windows, the "Shut down" command is associated with this state. Mechanical power can usually be removed or restored with no ill effects.
#  

# ------------

# In order to install the software suspend feature, you need to download a kernel patch and an optional suspend script. I currently use the 2.0-rc1 version (my partitions are ext3) and the suspend script. Note:
# 
#     * Disable DRI/DRM in XFree86 or the computer will freeze on resume. Apparently the DRI/DRM modules for Intel 81x graphics cards cause the lock-up.
#     * Do not initiate the hibernation from acpid or it will be impossible to unload/load some kernel modules (usb and ieee1394 related).
#     * Before suspend:
#           o Unmount NFS and external drives including memory stick.
#           o Stop any network connections like ssh, ftp, etc.
#           o Stop ALSA.
#           o Unload (modprobe -r <module>) the following modules in the stated order: sbp2, ohci1394, usb-storage, hid, uhci.
#           o Stop or suspend (cardctl suspend) PCMCIA.
#     * On resume start/resume PCMCIA, load required modules, start ALSA.
# 
# This recipe works for me. It takes care of the wireless network connection and all usb/ieee1394 devices. Note that I do not stop the ethernet adapter although it is suggested. As a matter of convenient implementation of the recipe, I suggest using the swsusp script. 
