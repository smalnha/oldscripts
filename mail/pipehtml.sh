#!/bin/bash

# used by mutt to view individual emails

TMPFILE=`tempfile -d ~/.mutt/cache/ --prefix=email- --suffix=.html`
cat > $TMPFILE

#sed -i -e '1i<pre>' -e '/<html/i</pre>' -e '/=$/{N; s/=\n//;}' -e 's/3D//g' $TMPFILE

xterm -title "email message" -e "swiftfox $TMPFILE && sleep 10 && rm -vif $TMPFILE" &

