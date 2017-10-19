#!/bin/bash

# This should be run with sudo or as root

# http://ubuntuforums.org/showthread.php?t=938533&page=2
wakeUpAt(){
	# kill previous if any
	if ps auxc | grep rtcwake; then
		echo "Need to previous rtcwake execution because woke up before wake time."
		killall -9 rtcwake
	fi

  #   # example: # wakeUpAt "Nov 28, 2008 00:16:00"
  #   echo "Will wake up at `date --date "$1"`"
  #   t=`date --date "$1" +%s`
  #   # since -t for rtcwake doesn't seem to work, calculate seconds instead
  #   now=`date +%s`
  #   let diff=t-now
	diff=$1
	# rtcwake and pm-suspend requires root permissions (or chmod +s)
	# rtcwake doesn't restore from suspend correctly, so we'll do it later with pm-suspend
	echo "Running: rtcwake to wake up at $t"
	echo "rtcwake --seconds $diff --mode on &"
	rtcwake --seconds $diff --mode on &
	# give rtcwake some time to make its stuff:
	echo "You have 5 seconds to cancel..."
	if ! sleep 5; then
			killall rtcwake
			return 2
	fi
	# then suspend
	echo "Suspending..."
	pm-suspend
}

export MY_BIN=$HOME/bin
export MY_BINSRC=$MY_BIN/online/src
{
	echo -n "# "
	date
	echo "vlc $HOME/NOBACKUP/Music/autoplay"
} > "$HOME/autoSnapshotDownload"
chown $USER "$HOME/autoSnapshotDownload"
while [ -f "$HOME/autoSnapshotDownload" ] ; do
	wakeUpAt "86000" || break
	#wakeUpAt "18:30"
	LOGF="$HOME/$0-`date`".log
	{
	echo "Woke up at `date`"
	for (( i=0; i<10; ++i )); do
		echo "Waiting for network connection"
		sleep 10
		if route | grep UG; then
			break;
		fi
	done
	if [ $i -lt 10 ]; then
		$HOME/bin/online/getDVRfiles.sh myH0use 
		chown $USER -R $HOME/NOBACKUP/dvrFiles*
	else
		echo "Skipping getDVRfiles.sh since waited too long for connection."
	fi;
	date
	} &> "$LOGF"
	chown $USER "$LOGF"
	echo "In 30 minutes, this computer will go to sleep unless the $HOME/autoSnapshotDownload is deleted"
	. $HOME/autoSnapshotDownload
	sleep 30m
done 

echo "Stopping autoSnapshotDownload."


