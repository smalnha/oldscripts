#!/bin/bash

# plays dvds
DVD_DEV=/dev/hdc


# if drive supports UDMA/33 
sudo hdparm -X66 -d1 $DVD_DEV


# need write permissions for libdvdcss
sudo xine

exit 0


configure(){
	sudo apt-get install libdvdcss2 dvdbackup ogmtools transcode mjpegtools
}

$DVD_DEV=/dev/dvd
# should have LOTS of space: dvd, cat vobs, tcextract vobs, requant, mplex
# about 5 x 8GB = 40 GB

# ripped vobs from dvd
$DVDBKUP_DIR=/mnt/dvd
# 

rip(){
	echo "Info about the dvd:"
	dvdbackup -i /dev/dvd -I
	echo ""
	read -p "Ready?"
	# see man for selective backup
	dvdbackup -M -i $DVD_DEV -o $DVDBKUP_DIR
}

reduce(){
	VOBFILE=$1
	AUDIO_TRACK=${2:0}
	tcextract -i $VOBFILE -t vob -x mpeg2 > $VOBFILE.m2v
	tcextract -i $VOBFILE -t vob -a $AUDIO_TRACK -x ac3 > $VOBFILE.ac3
}

getReduceFactor(){
	# VOB = video + audio tracks + subtitles
	REQUANT_FACTOR=`echo "($video_size / (4700000000 - $audio_size)) * 1.04" | bc`
}



# - Xine 0.98
# xine-lib-0.9.8
# xine-ui-0.9.8
# xine-dvdnav-0.9.8.beta2
# dvdnav-plugin requires libdvdread; for encrypted DVDs libdvdcss is also required
# - libdvdcss1-1.0.1-1
# - libdvdread-0.9.2
# 

rip(){
	tccat -t dvd -T 6,-1,1 -i /dev/dvd |splitpipe -f /usr/dvd/vobs/rip.log 1024 /usr/dvd/vobs/vob vob |tcextract -a 0 -x ac3 -t vob|tcdecode -x ac3 |tcscan -x pcm
	transcode -i /usr/dvd/vobs/vob-001.vob -a 0 -w 1000,250,100 -b 128 -s 1.4 -V -f 23.976 -g 720x480 -M 2 -x vob -o MiBtrailer.avi -y divx4

#Those commands rip "Men in Black"-trailer from FF:TSW DVD and convert it to DivX.
}


# http://dvd-create.sourceforge.net/dvdbackup-readme.html
# http://bunkus.org/dvdripping4linux/en/single/index.html#introduction
# http://www.exit1.org/dvdrip




