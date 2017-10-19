
# http://richard.jones.name/google-hacks/gmail-filesystem/gmail-filesystem.html
#  sudo apt-get install fuse-source
#   cd /usr/src; untgz fuse.tar.gz
#   cd fuse*; ./configure && make && make install
#  from web page: fuse-python.tar.gz and libgmail and gmailfs.tar.gz
#   untgz and install
#   cp libgmail.py constants.py /usr/local/lib/python2.3/site-packages/
#   cp gmailfs.py /usr/local/bin/

mountGMail(){
	[ ! "$SNOTES" ] && local SNOTES=~/.mysnotes.asc
	[ ! "$ypwd" ] && local ypwd=`gpg --quiet -r $GPGID --decrypt $SNOTES | grep --ignore-case "gmail.com:$EMAIL_USERNAME:"`
	echo "Now, sudo:"
	sudo mount -t gmailfs /usr/local/bin/gmailfs.py /mnt/gmail -o username=$EMAIL_USERNAME,password=${ypwd##*:},fsname=gmark
}

unmountGMail(){
	sudo umount /mnt/gmail
}
