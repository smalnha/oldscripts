#!/bin/ash

(
[ -f /tmp/current ] || date +%Y-%m-%d > /tmp/current
while true; do
        if ls /mnt/tmpfs/*.jpg; then
                mkdir /stm/disk/0/p1/snapshots
                mv /mnt/tmpfs/*.jpg /stm/disk/0/p1/snapshots
        fi

        date +%Y-%m-%d > /tmp/today
        if ! cmp /tmp/current /tmp/today > /dev/null; then
                #echo "Different day: `cat /tmp/current`"
                cd /stm/disk/0/p1/
                mv snapshots snapshots-`cat /tmp/current`
                tar -caf snaps-`cat /tmp/current`.lzma snapshots-`cat /tmp/current`
                echo "Done tar"
                rm -rf snapshots-`cat /tmp/current`
                mv /tmp/today /tmp/current
                /stm/disk/0/p1/toCellPhone.sh &
        fi
        sleep 600
done
) &

