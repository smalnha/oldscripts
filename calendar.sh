#!/bin/bash

CALROOT="$HOME/.calendar"
DIRFORMAT="+%Y/%m"
FILEFORMAT="${DIRFORMAT}/%d"
ENTRYDELIM="%&"
ENTRYEND="$ENTRYDELIM ---end---"

checkToday(){
	TODAYDATE=`date +%Y-%m-%d`
	if ! [ "$1" == "-f" ] ; then
		[ -f $CALROOT/lastChecked ] && source $CALROOT/lastChecked
		[ "$LASTCHECKED" == "$TODAYDATE" ] && return 1   # already checked
	fi
	echo "LASTCHECKED=$TODAYDATE" > $CALROOT/lastChecked
	showEntries $TODAYDATE
}

addToYahoo(){
	DATEFILE=`date $FILEFORMAT -d "$1"`
	# the rest adds it to yahoo calendar.
	[ "$2" ] && MAILURL="http://gmail.google.com/gmail?search=adv&view=tl&start=0$(createQuery $DATEFILE $2)"
	VERBOSE=":" browser.sh $(getYahooAddEvent -d "$1" -t "e:${3:-fromMyCalenScript}" -n "$MAILURL entry $2: $4" -l "email")
}

addMail(){
	DATEFILE=`date $FILEFORMAT -d "$*"`
    [ "$DATEFILE" ] || { echo "Wrong date."; return 1; }
	[ -d "$CALROOT/${DATEFILE%/*}" ] || mkdir -p $CALROOT/${DATEFILE%/*}
	let ID=$(date +%s)-$(date +%s -d "0:00")
	{
		#SUBJECT=`cat | grep "^Subject:" | { read SUBJ TEXT ; echo $TEXT; }`
		#$MY_BINSRC/
		#source $HOME/bin/src/calendar.src addMail $DATE "\"${SUBJECT}\""
		echo "$ENTRYDELIM $ID email "
		head -50 | while read LABEL ALINE; do 
			case $LABEL in				
				"Subject:" )					
					if [ -z "$SUBJECT" ]; then
						echo "$LABEL $ALINE"
						NOTES="$NOTES\n $LABEL $ALINE"
						addToYahoo "$*" $ID "$ALINE" "$NOTES"
					fi
					;;
				"From:" | "To:") 
					echo "$LABEL $ALINE"
					NOTES="$NOTES\n $LABEL $ALINE"
					;;
			esac
		done
		echo "$ENTRYEND" 
	} >> $CALROOT/$DATEFILE

}

showEntry(){
	DATEFILE=`date $FILEFORMAT -d$1`
	ID=$2
	eval sed -n \"/$ENTRYDELIM $ID /,/$ENTRYEND/p\" $CALROOT/$DATEFILE
}

removeEntry(){
	DATEFILE=`date $FILEFORMAT -d$1`
	ID=$2
	cp $CALROOT/$DATEFILE{,.bak}
	eval sed -i \"/$ENTRYDELIM $ID /,/$ENTRYEND/d\" $CALROOT/$DATEFILE
}

getDATEFILE(){
	if [ "$1" ] ; then
		DATEFILE=`date $FILEFORMAT -d$1`
	else
		DATEFILE=`date $FILEFORMAT`
	fi
}

showEntries(){
	getDATEFILE $1
	if [ -f "$CALROOT/$DATEFILE" ] ; then
		echo "========== $DATEFILE `date +%a -d$1` : #entries=`grep -c "$ENTRYEND" $CALROOT/$DATEFILE`"
		#echo "----------------------------------------------------"
		cat $CALROOT/$DATEFILE
		#echo "----------------------------------------------------"
	else 
		echo "========== $DATEFILE `date +%a -d$1` : 0 entries"
	fi
	echo ""
}

showNextDays(){
	#getDATEFILE $1
	if [ "$1" ] ; then
		local DATEPREFIX=`date $DIRFORMAT -d$1`
		local DAY=`date +%d -d$1`
	else
		local DATEPREFIX=`date $DIRFORMAT`
		local DAY=`date +%d`
	fi
	for (( i=0; i<5 ; i++ )); do
		DATEFILE=`date $FILEFORMAT -d$DATEPREFIX/$DAY`
		showEntries $DATEFILE
		let DAY+=1
	done;
}

encodeForURL(){
	echo $1 | sed 's/%/%25/g ; s/ /%20/g ; s/:/%3A/g; s/~/%7E/g ; s/\;/%3B/g ; s/=/%3D/g ; s/\?/%3F/g ; s/\@/%40/g ; s/,/%2C/g ; s/\\\$/%24/g ; s/\&/%26/g ; s/\+/%2B/g ; s/\//%2F/g ; s/\#/%23/g ; s/\\\`/%60/g ; s/\\\\/%5C/g ; s/\{/%7B/g ; s/\}/%7D/g ; s/|/%7C/g ; s/\^/%5E/g ; s/\[/%5B/g ; s/\]/%5D/g ; s/\"//g ; s/</%3C/g ; s/>/%3E/g ; s/\\n/%0A/g ; '
}

createQuery(){
	sed -n "/$ENTRYDELIM $2/,/$ENTRYDELIM/P" $CALROOT/$1 | while read LABEL ALINE; do 
		case $LABEL in				
			"Subject:")
				echo -n "&as_subj=`encodeForURL "$ALINE"`"
			;;
			"From:")
				echo -n "&as_from=`encodeForURL "$ALINE"`"
			;;
			"To:") 
				echo -n "&as_to=`encodeForURL "$ALINE"`"
			;;
			"Date:")
				echo -n "&as_date=`encodeForURL "$ALINE"`"
			;;
		esac
	done 
}

openMail(){
	DATEFILE=`date $FILEFORMAT -d$1`
	QUERY=$(createQuery $DATEFILE $2)
	#echo "Q=$QUERY"

#	browser.sh "http://gmail.google.com/gmail?search=query&view=tl&start=0&q=$QUERY"
	browser.sh "http://gmail.google.com/gmail?search=adv&view=tl&start=0$QUERY"
}

getYahooAddEvent(){
	if [ "$YAHOO" ]; then
		URL="$YAHOO/?v=5"
		DATE_POST="t"
		LOC_POST="INV_LOC"
	else
		URL="http://calendar.yahoo.com/?v=60"
		DATE_POST="ST"
		LOC_POST="in_loc"
	fi
	while [ "$1" ] ; do
		ARG="$1"
		# echo "case $ARG"
		case "$ARG" in
			-d | --date) shift
				if [ "$YAHOO" ]; then
					local Y_DATE="$(date -d "$1" +%s)"
				else
					local Y_DATE="$(date -d "$1" +%Y%m%dT%H%M%S)"
				fi
				shift
				[ "$Y_DATE" ] && URL="$URL&${DATE_POST}=${Y_DATE}"
				;;
			-r | --reminder) shift
				[ "$1" ] &&	URL="$URL&REM1=$1"
				shift
				;;
			-t | --title) shift
				[ "$1" ] &&	URL="$URL&TITLE=`encodeForURL "$1"`"
				shift
				;;
			-n | --notes) shift
				# echo "------- $1 -------" >&2
				[ "$1" ] &&	URL="$URL&DESC=`encodeForURL "$1"`"
				shift
				;;
			-l | --location) shift
				[ "$1" ] &&	URL="$URL&${LOC_POST}=`encodeForURL "$1"`"
				shift
				;;
			*) CMD="$1"
				shift
				;;
		esac
	done

	echo $URL
}

case "$0" in
	*/evitewww)
		case "$1" in 
			*www.evite.com*)
				EVITE_URL=$1
			;;
			"")
				read -p "Enter the URL: " EVITE_URL
			;;
			*)
				echo "--------------------------------"
				echo "!!! Expecting www.evite.com url."
				exit 1
			;;
		esac
		let ID=$(date +%s)-$(date +%s -d "0:00")
		HTML="$MY_TRASH/evite-$ID.html"
		wget --span-hosts --relative --level 2 "$EVITE_URL" --output-document="$HTML" &> "$MY_TRASH/wget-evite.log"
		EVITE_TITLE=$(grep '<title>' "$HTML" | sed 's/<title>\(.*\)<\/title>/\1/; s/&\#039;/\'\''/g')
		# wish I could parse time and location
		PARSED_HTML="$HTML.txt"
		cat $HTML | sed '1,/you.re invited/d; /Guest List/,$d' | sed 's/<[^>]*>/ /g; s/&[^\;]*;//g;' | sed '/^[ \t\n\r\s]*$/d' | sed 's/^[ \t]*//g' > $PARSED_HTML
		EVITE_FROM=`sed -n '/Host/,+1p' $PARSED_HTML`
		EVITE_LOC=`sed -n '/Location/,+1p' $PARSED_HTML | sed -n '2p'`
		EVITE_DATE=`sed -n '/When/,+1p' $PARSED_HTML | sed -n '2p' | sed 's/,//g'`
		echo "EVITE = $EVITE_TITLE; $EVITE_FROM; $EVITE_LOC; $EVITE_DATE"
		while ! date -d "$EVITE_DATE"; do
			read -p "Could not parse date \"$EVITE_DATE\".  Enter a date: " EVITE_DATE
		done
		browser.sh $(getYahooAddEvent -d "$EVITE_DATE" -t "$EVITE_TITLE" -l "evite" -n "$1 evite: `cat $PARSED_HTML | sed 's/\([^:]\) $/\1\\\\n/g'`") 
	;;
	*/evite)
		browser.sh $(getYahooAddEvent -d "$1" -t "$2" -n "evite: $3") 
	;;
	*/event)
		addMail "$@"
	;;
	*)
		if [ "$1" ]; then
			CMD=$1
			shift
			$CMD "$@"
		else
			for link in event evite evitewww; do
				[ ! -f "$MY_BIN/$link" ] && echo "Creating $MY_BIN/$link" && ln -s "$MY_BIN/calendar.sh" "$MY_BIN/$link"
			done
			echo "calendar commands: 
	event dateAndTime
	evite dateAndTime title [subtitle]
	evitewww \'url\'
			"
		fi
	;;
esac

echo "Check browser to add event to your calendar."

