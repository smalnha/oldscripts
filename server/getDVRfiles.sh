#!/bin/bash

cd ~/NOBACKUP
#nc -l -p 8081 | tar -xzf - &
nc -l 8081 | tar -xzf - &
NCPID=$!

. $MY_BINSRC/functions.src
export myIP=`my_ip`

[ "$myIP" ] || exit 1

if [ "$1" == "" ]; then
	expect $MY_BIN/direct/getDVRfiles.exp
else
	echo "$1" | expect $MY_BIN/direct/getDVRfiles.exp
fi

echo "Done telnet."

# in case

if [ -d toDownload ]; then
	if rmdir toDownload &> /dev/null; then
		echo "No snapshots."
	else
		cd toDownload
		for F in *.jpg; do 
			G=`echo "$F" | cut --output-delimiter="" -d_ -f2-7`;  
			echo "$G $F"; 
		done | sort | cut -d' ' -f 2 > sorted.ls
		cd ..

		destDir="dvrFiles-`date +%Y-%m-%d-%H%M`"
		mv -v toDownload "$destDir"
		[ "$1" == "" ] && feh "$destDir"/*.jpg
	fi
elif [ -f dir.lst ]; then
	echo "No snapshots."
	destDir="dirList-`date +%Y-%m-%d-%H%M`"
	mv -v dir.lst "$destDir"  
else
	echo "Transfer failed."
	killall nc
	exit 2
fi


# echo 'if ! [ -e test1.sh ]; then echo "blah" > test.sh; fi'
#sleep 2
# if [ "testing" ]; then
# else
# fi

