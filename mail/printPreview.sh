#!/bin/bash

# used as a printer

#  add printer "PrintToFile" using driver "Generic PostScript Printer"
#  "No pre-filtering"
#  sudo vim /etc/cups/printers.conf
#      "DeviceURI parallel:/tmp/printfile.ps"
: ${PSFILE:=/tmp/printfile.ps}
: ${PRINTERNAME:=PrintToFile}

touch $PSFILE
chmod a+w $PSFILE  
echo "" > $PSFILE
# pipe stdin to PSFILE
#cat > $PSFILE
if [ -f "$1" ]; then
	gtklp -P "$PRINTERNAME" "$1"
	SUCCESS=$?
else
	cat | tee ~/test.ps | lpr -P "$PRINTERNAME"
fi

if [ "$SUCCESS" == 0 ]; then
	sleep 3
	ps2ps $PSFILE /tmp/preview.ps
	{ gv /tmp/preview.ps 
	  rm /tmp/preview.ps
	} &
	#gv $PSFILE &
fi
