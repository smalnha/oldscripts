
function uncomment(){
	let FIRSTLINE=`grep -n "$1" $3 | cut -d ':' -f 1`+1
	let LASTLINE=`grep -n "$2" $3 | cut -d ':' -f 1`-1
	echo $FIRSTLINE,${LASTLINE}s/^# //g
	sed '$FIRSTLINE,${LASTLINE}s/^# //g' $3
}
function comment(){
	sed '/^ .*$1.*{/,/^# }/s/^# //g' fstab 
}
