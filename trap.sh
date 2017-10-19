#!/bin/bash

# purpose: test trap functionality
SOMEVAR="MYVAR"
echo "$? blah bla" >> tmp.bak

case "$1" in
1) 
trap "echo 'Running trap SOMEVAR=$SOMEVAR'; rm -vf tmp.bak; exit; " TERM KILL QUIT EXIT
sleep 30
echo "end"
;;
2)
{
trap "echo 'Running trap SOMEVAR=$SOMEVAR'; rm -vf tmp.bak; exit; " TERM KILL QUIT EXIT
sleep 30  # must send kill signal to sleep PID
echo end block
exit  
} & 
echo "$$,$!"
echo end
;;
3)
{
trap "echo \"Running trap SOMEVAR=$SOMEVAR\"; rm -vf tmp.bak;" TERM KILL QUIT EXIT
sleep 30  # must send kill signal to sleep PID
echo end block
exit  
} & 
echo "$$,$!"
SLEEPERPID=$!
echo end
echo killing
pkill -P $SLEEPERPID
;;
sleeper)
trap "echo 'Running trap SOMEVAR=$SOMEVAR'; cat tmp.bak; rm -vf tmp.bak; exit; " TERM KILL QUIT EXIT
sleep 30 # must send kill signal to sleep PID
echo end sleeper
exit  
;;
4)
./trap.sh sleeper &
echo "$$,$!"
echo end
;;
esac
