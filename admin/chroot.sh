#!/bin/bash

CHROOT=/tmp/chroot
mkdir -p $CHROOT/bin
mkdir -p $CHROOT/lib

for HOME_FILE in ~/.bash_profile ~/.bashrc; do
	cp -auv $HOME_FILE $CHROOT
done

for CH_FILE in /bin/bash /bin/ls; do
	cp -auv $CH_FILE $CHROOT/bin
done
for LIB_FILE in ld-*.so* libacl.so.* librt*.so* libc.so* libc-*.so* libdl*.so* libtermcap*.so* libpthread*.so* libncurses.so.* libselinux.so.* libattr.so.* libsepol.so.*; do
	cp -auv /lib/$LIB_FILE $CHROOT/lib
done

sudo chroot $CHROOT bash

