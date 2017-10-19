#!/bin/bash

rm -f $HOME/nokia.log
encodeForPOST(){
	echo $1 | sed 's/ /+/g ; s/\//%2F/g; s/:/%3A/g;' 
	#echo $1 | sed 's/%/%25/g ; s/ /+/g; s/~/%7E/g ; s/\;/%3B/g ; s/=/%3D/g ; s/\?/%3F/g ; s/\@/%40/g ; s/,/%2C/g ; s/\\\$/%24/g ; s/\&/%26/g ; s/\+/%2B/g ;  s/\#/%23/g ; s/\\\`/%60/g ; s/\\\\/%5C/g ; s/\{/%7B/g ; s/\}/%7D/g ; s/|/%7C/g ; s/\^/%5E/g ; s/\[/%5B/g ; s/\]/%5D/g ; s/\"//g ; s/</%3C/g ; s/>/%3E/g ; s/\\n/%0A/g ; '
}

sendNokiaContact(){
    MYCELL="$1"
    [ "$MYCELL" ] || return 1
    [ "$2" ] && NAME="txtName=`encodeForPOST "$2"`"
    [ "$3" ] && PHONE="&txtPhone=`echo "$3" | tr -d " .()-"`"
    [ "$4" ] && EMAIL="&txtEmail=$4"
    { cat <<EOF
$NAME$PHONE$EMAIL&txtMobileNumber=%2B$MYCELL&networkid=90&phoneid=86
---
EOF
    } | lynx -post_data "http://secure.mouse2mobile.com/clients/nokia/americas/vCard/send_single_vCard.asp" >> $HOME/nokia.log
}

sendNokiaEvent(){
    : ${ALARM:=15}
    local MYCELL="$1"
    shift;
    [ "$MYCELL" ] || return 1
    [ "$1" ] && local SUBJECT="&eventName=`encodeForPOST "$1"`"
    shift
    # remove leading 0 for single digits
    local STDATE="$1"
    shift
    local STARTDATE="&CalendarStartDate=$(encodeForPOST "`date +%-m/%-d/%Y -d "$STDATE"`")"
    local STARTTIME="&LabelStartTime=Start+Date%2FTime%3A&startTime=$(encodeForPOST "`date "+%l:%M %p" -d "$STDATE"`")"
    if [ "$1" ]; then
        if [ `date +%s -d "$STDATE"` -gt `date +%s -d "$1"` ]; then
            local ENDDATE="&CalendarEndDate=$(encodeForPOST "`date +%-m/%-d/%Y -d "$STDATE"`")"
        else 
            local ENDDATE="&CalendarEndDate=$(encodeForPOST "`date +%-m/%-d/%Y -d "$1"`")"
        fi
        local ENDTIME="&LabelEndTime=End+Date%2FTime%3A&endTime=$(encodeForPOST "`date "+%l:%M %p" -d "$1"`")"
        shift
        #echo ======= $ENDDATE $ENDTIME; return
    else
        local ENDDATE="&CalendarEndDate=$(encodeForPOST "`date +%-m/%-d/%Y -d "$STDATE"`")"
        local ENDTIME="&LabelEndTime=End+Date%2FTime%3A&endTime=$(encodeForPOST "`date "+%l:%M %p" -d "$STDATE"`")"
    fi

#eventType=3&LabeleventName=Subject%3A&eventName=Alarm+Test&LabelLocation=Location%3A&eventLocation=lips+lab&LabelStartTime=Start+Date%2FTime%3A&newStartDate=Tue+5%2F24%2F2005&startTime=04%3A30+AM&LabelEndTime=End+Date%2FTime%3A&newEndDate=Tue+5%2F24%2F2005&endTime=03%3A00+PM&LabeleventAlarm=Alarm%3A&eventAlarm=ON&LabeleventAlarmTime=Alarm+Time%3A&eventAlarmTime=15&LabeleventRepeat=Repeat%3A&eventRepeat=NO&LabeleventNotes=Notes%3A&eventNotes=&txtMobileNumber=%2B15128258495&CalendarStartDate=5%2F24%2F2005&CalendarEndDate=5%2F24%2F2005&CalendarStartTime=&CalendarEndTime=&networkid=90&phoneid=86
    read -p "send nokiaEvent: $SUBJECT ($STARTDATE at $STARTTIME) to ($ENDDATE at $ENDTIME) ? " || return 1

    echo -e "sending nokiaEvent: $SUBJECT \n\t($STARTDATE at $STARTTIME) \n\tto ($ENDDATE at $ENDTIME)"
    { cat <<EOF
eventType=3&LabeleventName=Subject%3A$SUBJECT$STARTTIME$ENDTIME&LabeleventAlarm=Alarm%3A&eventAlarm=ON&LabeleventAlarmTime=Alarm+Time%3A&eventAlarmTime=$ALARM&LabeleventRepeat=Repeat%3A&eventRepeat=NO&txtMobileNumber=%2B$MYCELL$STARTDATE$ENDDATE&networkid=90&phoneid=86
---
EOF
    } | lynx -post_data "http://secure.mouse2mobile.com/clients/nokia/americas/vCal/send_single_vCal.asp" >> $HOME/nokia.log
}

MYNOKIANUMBER=15128258495
if [ "$#" -eq 1 ]; then
    CHOICE=sendExistingContact
    NAMEPATTERN="$1"
elif [ "$#" -gt 1 ]; then
    #expecting parameters: "Test subject" "5/24 10AM" ["5/24 3PM"]
    sendNokiaEvent $MYNOKIANUMBER "$@"
    exit 0
else
	. $MY_BINSRC/helperfuncs.src
	choose sendExistingContact sendNewContact sendNokiaEvent sendAllContacts
fi

case $CHOICE in
    sendAllContacts)
        toAbook.sh toNokia | { IFS=","
            while read NAME PHONE EMAIL; do        
                echo "sending NokiaContact in 5 seconds: $MYNOKIANUMBER \"$NAME\" \"$PHONE\" \"$EMAIL\" ..."
                sleep 5
                sendNokiaContact $MYNOKIANUMBER "$NAME" "$PHONE" "$EMAIL" 
            done
        }    
    ;;
    sendExistingContact)
        [ "$NAMEPATTERN" ] || read -p "Name pattern? " NAMEPATTERN
        toAbook.sh toNokia | { IFS=","
            while read NAME PHONE EMAIL; do
                if echo "$NAME" | grep -q "$NAMEPATTERN"; then                    
                    echo "sending NokiaContact in 5 seconds: $MYNOKIANUMBER \"$NAME\" \"$PHONE\" \"$EMAIL\" ..."
                    sleep 5
                    sendNokiaContact $MYNOKIANUMBER "$NAME" "$PHONE" "$EMAIL"
                else
                    echo "-- no match: $NAME $PHONE $EMAIL"
                fi
            done
        }    
    ;;
    sendNewContact)
        read -p "Name? " NAME
        read -p "Phone? " PHONE
        read -p "Email (can be empty)? " EMAIL
        sendNokiaContact $MYNOKIANUMBER "$NAME" "$PHONE" "$EMAIL" 
        exit 0
    ;;
    sendNokiaEvent)
        read -p "Subject? " SUBJECT
        read -p "Start date and time? " STARTTIME
        read -p "End date and time (can be empty)? " ENDTIME
        sendNokiaEvent $MYNOKIANUMBER "$SUBJECT" "$STARTTIME" "$ENDTIME"
    ;;
    *) echo "Unsupported!!"
        exit 1
    ;;
esac

