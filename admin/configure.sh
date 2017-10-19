#!/bin/bash

echo "Need to have src/usrlocalsrc.autosource call this script"

. $MY_BINSRC/helperfuncs.src # need ask

conf-mrxvt(){
   ./configure --enable-minimal --enable-selectionscrolling --enable-mousewheel --enable-mouseslipwheel --enable-utmp --enable-wtmp --enable-cursor-blink --enable-transparency --enable-fading --enable-tinting --enable-xft --enable-xim --enable-backspace-key --enable-ttygid --enable-delete-key --enable-resources --enable-swapscreen --disable-dependency-tracking --with-save-lines=300 --with-max-term=8
}

conf-fluxbox(){
	echo "Configuring fluxbox"
	./autogen.sh
	echo "--------------------------------------"
	ask "Enable xinerama? "
	if [ $? -eq 1 ] ; then
		./configure --enable-imlib2
	else
		./configure --enable-imlib2 --enable-xinerama
	fi
}

conf-aterm1(){
	echo "Configuring aterm"
	./configure --enable-transparency --enable-fading --enable-background-image --enable-menubar --enable-utmp --with-x --enable-xgetdefault --with-xpm --with-term="xterm"
	# rxvt causes problem in ssh, but is useful in pine "Home" and "End" keys
	# aterm is not popularly recognized
}

conf-grub(){
	echo "Configuring grub"
	echo To be done
}

app=${PWD##*/}
if [ "$1" ] ; then
	conf-$1
elif [ "$app" ] ; then
	conf-$app 	# can call anything except aliases
else
	echo "Usage: configure.sh APPNAME"
	echo -n "  where APPNAME is one of the following:"
fi

ask "make && sudo make install?" 0
if [ $? -eq 1 ] ; then
	echo "Not building."
else
	make && sudo make install
fi

