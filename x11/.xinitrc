#

echo "Running ~/.xinitrc"

# Run xfce4-session if installed
if which xfce4-session >/dev/null 2>&1; then
    if [ ! -z "$LAUNCH_XFCE_WITH_CK" ]; then
       ck-launch-session dbus-launch --sh-syntax --exit-with-session xfce4-session
    else
       xfce4-session
    fi
fi




# if lsmod | grep nvidia > /dev/null && [ -f ~/.nvidia-settings-rc ]; then
#         nvidia-settings --load-config-only
# fi

[ -f "$HOME/.screenlayout/$HOSTNAME.sh" ] && . $HOME/.screenlayout/"$HOSTNAME".sh

# turn screen blanking to 600sec=10min
xset s 300
# turn on monitor energy star features: standby, suspend, off
xset dpms 900 1200 1800

# if xmodmap -p | grep "lock .* Caps_Lock"; then  # CapsLock still works
# 	xmodmap .Xmodmap
# fi

#export XMODIFIERS=@im=scim
#export GTK_IM_MODULE=scim

