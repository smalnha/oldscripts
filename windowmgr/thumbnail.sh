#!/bin/bash

CAPTURE="iconify"
VIEWER=feh

thumbnail(){
    local WINDOW_ID=$1
    local THUMBSIZE="${2:-50%}"
    local THUMBFILE="${MY_TRASH:-/tmp}/icon.tmp.$WINDOW_ID"

    if pgrep -f "iconify .*$THUMBFILE.png"; then
        iconify --iconify $WINDOW_ID
        return 1
    fi

    iconify --deiconify $WIN_ID
    case "$CAPTURE" in
        iconify)
            echo "iconify $1"
            iconify --snapshot "$THUMBFILE.png" "$WIN_ID" &
            ;;
        scrot)
            scrot "$THUMBFILE.png";;
        import)
            import -silent -window "$WINDOW_ID" -resize $THUMBSIZE -frame 1x1 -quality 0 "$THUMBFILE.png";;
        xwd)
            xwd -silent -id $WINDOW_ID > "$THUMBFILE.xwd" || exit 1;;
        *)
            read -p "Unsupported capture utility $CAPTURE"
            return 1
        ;;
    esac

    return 0

    iconify --iconify $WINDOW_ID

    if [ "$CAPTURE" = "xwd" ]; then
        convert -scale $THUMBSIZE -frame 1x1 -mattecolor black -quality 0 "$THUMBFILE.xwd" "$THUMBFILE.png"
    fi

    (
    echo "$VIEWER .*$WINDOW_ID.png" >> $MY_TRASH/thumbnail.lst
    $VIEWER "$THUMBFILE.png"

    iconify --deiconify $WINDOW_ID
    sed -i /"$VIEWER .*$WINDOW_ID.png"/d $MY_TRASH/thumbnail.lst
    rm -f "$THUMBFILE".???
    ) &
}

WIN_ID=$1
if [ "$1" == "all" ]; then
    CURR_DESKTOP=`wmctrl -d | grep "\*" | cut -d " " -f 1`
    wmctrl -l | grep -v "N/A" | grep "[:alphanum:]* $CURR_DESKTOP" | cut -d " " -f 1 | while read WIN_ID; do
        thumbnail $WIN_ID
    done
    exit 0
elif [ "$1" == "ALL" ]; then
    wmctrl -l | grep -v "N/A" | cut -d " " -f 1 | while read WIN_ID; do
        thumbnail $WIN_ID
    done
    exit 0
elif [ -z "$WIN_ID" ]; then
    WIN_ID=`xprop -root _NET_ACTIVE_WINDOW | cut -d \# -f 2`
    WIN_ID=`echo $WIN_ID`
    echo "thumbnail active_window $WIN_ID"
else
    if ! wmctrl -l | grep -v "N/A" | grep "$WIN_ID" > /dev/null; then
        echo "Not a WM client or already minimized! $WIN_ID."
        read
        exit 1
    fi
fi

thumbnail $WIN_ID


