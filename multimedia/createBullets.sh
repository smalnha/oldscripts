
SIDE=16
SIZE=${SIDE}x${SIDE}
let HALFSIDE=${SIDE}/2
CIRCLE=${HALFSIDE},${HALFSIDE}
let RADIUS=${HALFSIDE}-1
let RADIUSHL=${HALFSIDE}/2
let ROUNDED=${SIDE}/3

HIGHLIGHTBRIGHT=0x7
echo convert -size $SIZE xc:none -draw "translate $CIRCLE circle 0,0 $RADIUSHL,0" -negate -channel A -gaussian-blur $HIGHLIGHTBRIGHT highlight.png
convert -size $SIZE xc:none -draw "translate $CIRCLE circle 0,0 $RADIUSHL,0" -negate -channel A -gaussian-blur $HIGHLIGHTBRIGHT highlight.png

SHAPE=ball
S=100  # vivid to white
B=100
H=0

#for SHAPE in ball square rounded diamond hourglass sideHourglass rotHourglass; do
for SHAPE in 1ball 2square 3diamond 4hourglass 6sideHourglass 5rounded; do
#testing: for (( S=100; S>=20; S-=10 )); do
for ORDER in 1 2; do
for S in 100; do
#for (( B=100; B>=20; B-=30 )); do  # use 2 digit numbers for easier sorting
#for B in 100 60 30; do
for B in 100 45; do
	#testing: for (( H=0; H<90; H+=8 )); do
	#for H in 0 8 16 32 48 64 72 80 90; do
	case $ORDER in
		1) H_options="0 16 48 64 88"
			;;
		2) H_options="8 32 72"
			;;
	esac

	for H in $H_options ; do


		COLOR="hsb($H%,$S%,$B%)"

		case $SHAPE in
			?ball)
				echo "Creating ball with $COLOR"
				echo convert -size $SIZE xc:none -fill "$COLOR" -draw "translate $CIRCLE circle 0,0 $RADIUS,0" shape.png
				convert -size $SIZE xc:none -fill "$COLOR" -draw "translate $CIRCLE circle 0,0 $RADIUS,0" shape.png
			;;
			?square)
				echo "Creating square with $COLOR"
				echo convert -size $SIZE xc:none -fill "$COLOR" -draw "rectangle 0,0 $SIDE,$SIDE" shape.png
				convert -size $SIZE xc:none -fill "$COLOR" -draw "rectangle 0,0 $SIDE,$SIDE" shape.png
			;;
			?diamond)
				convert -size $SIZE xc:none -fill "$COLOR" -draw "polygon 0,$HALFSIDE $HALFSIDE,$SIDE $SIDE,$HALFSIDE $HALFSIDE,0" shape.png
			;;
			?rounded)
				echo convert -size $SIZE xc:none -fill "$COLOR" -draw "roundRectangle 0,0 $SIDE,$SIDE $ROUNDED,$ROUNDED" shape.png
				convert -size $SIZE xc:none -fill "$COLOR" -draw "roundRectangle 0,0 $SIDE,$SIDE $ROUNDED,$ROUNDED" shape.png
			;;
			?hourglass)
				convert -size $SIZE xc:none -fill "$COLOR" -draw "polygon 0,0 $SIDE,0 0,$SIDE $SIDE,$SIDE" shape.png			
			;;
			?sideHourglass)
				convert -size $SIZE xc:none -fill "$COLOR" -draw "polygon 0,0 $SIDE,$SIDE $SIDE,0 0,$SIDE" shape.png			
			;;
			?rotHourglass)
				convert -size $SIZE xc:none -fill "$COLOR" -draw "polygon 0,$HALFSIDE $SIDE,$HALFSIDE $HALFSIDE,$SIDE $HALFSIDE,0" shape.png
			;;
		esac

		let Binverse=-$B/10+10
		let Hdivided=($H+9)/10
		let Ssorted=100-$S

		# for seeing all the colors and there differences
		SUFFIX1=$Hdivided-$Ssorted-${Binverse}-${SHAPE}_$H-$S-$B
		# for ordering so that colors are sufficiently different
		SUFFIX=$Binverse-$Ssorted-$SHAPE-$ORDER-${Hdivided}_$H-$S-$B
		case $SHAPE in
			SKIP?ball|SKIP?rounded)
				composite -compose atop -geometry -10-12 highlight.png shape.png gen-$SUFFIX.png
			;;
			*)
				mv shape.png gen-$SUFFIX.png
			;;
		esac

		mv gen-$SUFFIX.png SightingStyle-$Binverse-$SHAPE-$ORDER-$Hdivided.png

	done
done
done
done
done
