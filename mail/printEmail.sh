#!/bin/bash
echo "printEmail.sh called: $0 $* in directory $PWD"
if [ "" ] && which gv; then
	# 2-up
	a2ps -Email --medium=Letter --output=- | gv -
else
	# 1-up
	a2ps -Email -1 --medium=Letter --output=$HOME/email.ps
fi

