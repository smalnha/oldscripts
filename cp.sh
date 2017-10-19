#!/bin/sh

# copies files to destination
# if exists and different, calls xxdiff
# TODO:recursion

# trap BREAKs?

DEBUG=":" # "echo"
VERBOSE="-v"
BACKUP="true"
ARGS="$@"
SOURCEFILES="${ARGS% *}"
DEST="${ARGS##* }"

#get absolute path
pushd $DEST > /dev/null
DEST=$PWD
popd > /dev/null

#[ "$VERBOSE" ] && echo DEST=$DEST SOURCE=$SOURCEFILES
askForTask(){
	select TASK in "mv -f \"$1\" \"$2\"" "cp -f \"$1\" \"$2\""  "cp -f \"$1\" \"$2.bak\"" "skip" ; do
		[ "$TASK" == "skip" ] && echo "" && return 0
		# if you want to quit upon bad user input: [ -z "$TASK" ] && echo "Quiting." && return 0;
		#echo $?=$REPLY task=$TASK
		break;
	done
	[ -z "$TASK" ] && echo "" && return 0
	echo "$TASK"
}
for AFILE in $SOURCEFILES; do
	if [ ! -d "$AFILE" ] ; then
		#[ "$VERBOSE" ] && echo "Exists?: $DEST/$AFILE"
		if [ -e "$DEST/$AFILE" ] ; then
			ls -l "$AFILE"
			ls -l "$DEST/$AFILE"
			# echo Comparing $AFILE "$DEST/$AFILE"
			if ! diff -q "$AFILE" "$DEST/$AFILE" > /dev/null ; then
				$DEBUG "DIFFERENT: $DEST/$AFILE"
				TASK=`askForTask "$AFILE" "$DEST"`
				if [ "$TASK" ] ; then
					echo "Overwriting $DEST/$AFILE with $AFILE"
					eval $TASK 
				else
					echo "Skipping $AFILE"
				fi

				#[ "$BACKUP" ] && cp -ip $VERBOSE "$DEST/$AFILE"{,.bak}
				#xxdiff $AFILE "$DEST/$AFILE"
			else 
				$DEBUG 
				echo "same $DEST/$AFILE"
			fi
		else
			[ "$VERBOSE" ] && echo "new: $DEST/$AFILE"
			cp -ip $VERBOSE "$AFILE" "$DEST"
		fi
	else
		$DEBUG "Recursing into directory $AFILE" 
		[ ! -d "$DEST/$AFILE" ] && mkdir $VERBOSE "$DEST/$AFILE"
		cd "$AFILE"
		#cp.sh "$AFILE"/* "$DEST/$AFILE"
		cp.sh * "$DEST/$AFILE"
		cd ..
		$DEBUG "Up to directory $PWD" 
	fi
done

