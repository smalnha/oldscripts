

if [ "$1" = "checkCaptions" ]; then
	for ADIR in 2004-*/; do
		if [ ! -f "$ADIR/captions.txt" ] ; then
			echo "No captions.txt in $ADIR."
		fi
	done
	exit 0
fi

if [ "$1" = "checkOrigCaptions" ]; then
	for ADIR in 2004-*/; do
		[ ! -f "$ADIR/orig/captions.txt" ] && echo "No captions $ADIR" && continue
		if cmp $ADIR/captions.txt $ADIR/orig/captions.txt; then
			echo "Same $ADIR"
		else
			xxdiff $ADIR/captions.txt $ADIR/orig/captions.txt		
		fi
		rm -iv $ADIR/orig/captions.txt
	done
	exit 0
fi

if [ "$1" = "missing" ]; then
	echo "Checking for missing originals"
	mv -iv missing missing.bak
	for ADIR in 2004-*/; do
		[ ! -d "$ADIR/images" ] && exit 1;
		cd $ADIR/images
		echo "---------" >> ../../missing
		echo "[ $ADIR ]" >> ../../missing
		for JPG in *.thumb.jpg *.thumb.JPG; do 
			case $JPG in
				'*.thumb.jpg' | '*.thumb.JPG' )
					continue
				;;
			esac
			JPGIMG=${JPG//thumb.}; 
			if [ ! -f ../orig/$JPGIMG ]; then
				echo "$JPGIMG" >> ../../missing
			fi
		done
		cd ../..
	done
	echo "done." >> missing
	exit 0
fi

ORIG_DIR=~/public_html/protected/orig

cd $1
mkdir orig
cd images
mv -v $ORIG_DIR/$1/*.txt ../orig/
mv -v $ORIG_DIR/$1/*.mp3 ../orig/
mv -v $ORIG_DIR/$1/*/ ../orig/
for JPG in *.thumb.jpg *.thumb.JPG; do 
	case $JPG in
		'*.thumb.jpg' | '*.thumb.JPG' )
			continue
		;;
	esac
	JPGIMG=${JPG//thumb.}; 
	if [ -f $ORIG_DIR/$1/$JPGIMG ]; then
		mv -v $ORIG_DIR/$1/$JPGIMG ../orig/
	else 
		echo "Looking for $JPGIMG"; 
		echo find $ORIG_DIR -iname "$JPGIMG"
		FOUNDJPG=`find $ORIG_DIR -iname "$JPGIMG"`
		if [ "$FOUNDJPG" ] ; then
			mv -v $FOUNDJPG ../orig
		else
			echo "!!!!!! $JPGIMG"
		fi
		echo "-----------------"
	fi
done


