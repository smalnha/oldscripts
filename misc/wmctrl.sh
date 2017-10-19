

#echo 'wmctrl -ia `wmctrl -l |grep -v " -1 " - |zenity --list --column Window |cut -d' ' -f1`'

INCREMENT=${1:-1}

NUM_DESKTOPS=`xprop -root | grep ^_NET_NUMBER_OF_DESKTOPS | awk '{print $3}'`
CURR_DESKTOP=`xprop -root | grep ^_NET_CURRENT_DESKTOP | awk '{print $3}'`
echo $NUM_DESKTOPS $CURR_DESKTOP
let CURR_DESKTOP+=$INCREMENT
[ $CURR_DESKTOP -ge $NUM_DESKTOPS ] || [ $CURR_DESKTOP -lt -$NUM_DESKTOPS ] && let CURR_DESKTOP%=$NUM_DESKTOPS
while [ $CURR_DESKTOP -lt 0 ]; do # should only loop 1 time due to %= above
    let CURR_DESKTOP+=$NUM_DESKTOPS
    echo $CURR_DESKTOP
done;
wmctrl -s $CURR_DESKTOP

