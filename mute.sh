#!/bin/sh

case "$HOST" in
	dell6k) CARDID=ICH6;;
	blackhat) CARDID=I82801CAICH3;;
esac

{
	echo "
	state.$CARDID {
		control.1 {
			comment.access 'read write'
			comment.type BOOLEAN
			comment.count 1
			iface MIXER
			name 'Master Playback Switch'"

	if [ "$1" ]; then
		echo "			value true"
	else
		echo "			value false"
	fi

	echo "
		}
	}"
} | alsactl -f - restore

