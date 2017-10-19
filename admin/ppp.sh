#!/bin/bash 

# redirect stderr and stdout to file
#   exec &> /tmp/ppp-go.log
# or run this script as follows:
#   ppp.sh 2>&1 | tee /tmp/ppp-go.log

if [ "$1" == "--help" ]; then
	echo "
		--kill
	"
	exit 0
fi

echo "=-=-=-=- ppp.sh starting -=-=-=-=-="
date

configure(){
		sudo ln -s /dev/ttySL0 /dev/modem
		sudo chmod +sx `which pppd` `which chat` # used by ppp-{go,stop}
}

killppp(){
	echo "Killing and reloading..."
	sudo ppp-stop
	echo "tail /var/log/ppp-ipupdown.log"
	#tail -50 /var/log/ppp-ipupdown.log
	sudo killall -9 pppd
	sudo killall -9 slmodemd
	sudo modprobe -r slamr
}

if [ "$1" == "-k" ] ; then
	killppp
	exit 0
fi


if [ -f /etc/laptop ] ; then
	if [ "$HOSTNAME" == "knop" ] ; then
		modemdPID=` ps --no-headers -C slmodemd -o pid`
		if ! ps -C slmodemd ; then
			sudo modprobe -r slamr 
			sudo modprobe slamr
			if [ "invisible" ] ; then
				sudo slmodemd &
			elif which aterm ; then
				( aterm -name slmodemd -title slmodemd -geometry 60x20+105+130 -tint gray -fade 50 -shading 90 -e sudo slmodemd ) &
			else 
				( xterm -name slmodemd -title slmodemd -geometry 60x20+105+130 -e sudo slmodemd ) &
			fi
			sleep 2
		else 
			# if pppd running (didn't connect and this was run again)
			if ps -C pppd ; then
				# then kill existing 
				echo "Killing existing slmodemd."
				killppp
				sleep 1
				exec $0
			else
				echo "Using existing slmodemd."
			fi
		fi
	else
		echo "Unknown laptop: add to ppp.sh"
		exit 1
	fi
fi


echo "Running ppp-go ..."
sudo ppp-go 
# sudo ppp-go &

echo "tail /var/log/ppp-ipupdown.log"
# tail -50 /var/log/ppp-ipupdown.log
# pid=`ps -C pppd -o pid`
# tail -f /tmp/ppp-go.log
# sleep 90

# wait

