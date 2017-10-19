#!/bin/ash

[ -f test ] || touch test

for i in `seq 23`; do
        if tftp -p -l test ${USER}cell 6969; then
                for F in snaps-*.lzma; do
                        tftp -p -l "$F" ${USER}cell 6969 && rm "$F"
                done
                break
        fi
        #echo Sleeping 4
        sleep 3600
done

echo Done.

