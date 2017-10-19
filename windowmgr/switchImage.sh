IMAGEDIR=${1:-~/.fluxbox/backgrounds}
CURRENTIMG=${2:-$IMAGEDIR/../current.jpg}
ROTATELIST=${3:-$IMAGEDIR/../rotate.lst}

while [ ! -f $IMAGEDIR/$NEXTSPLASH ] ; do
	ls --color=none $IMAGEDIR > $ROTATELIST
	#M=`date +%N`
	numImages=`cat $ROTATELIST | wc -l`
	#echo $M $numImages
	N=$(($RANDOM % $numImages + 1))
	#echo $N
	# get the Nth line
	#NEXTSPLASH="`head -n $N $ROTATELIST | tail -n 1`"
	NEXTSPLASH="`sed --silent ${N}p $ROTATELIST`"
	echo "Next image =  $IMAGEDIR/$NEXTSPLASH"
	cp -f $IMAGEDIR/$NEXTSPLASH $CURRENTIMG
done
