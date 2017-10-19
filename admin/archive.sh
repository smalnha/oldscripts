#!/bin/bash

#alias copyFilesTo='cp -upL *'
# SYSARCHIVEDIR="/tmp/sysarchive"
# [ -d "$SYSARCHIVEDIR" ] || { mkdir -vp "$SYSARCHIVEDIR"; chmod 777 "$SYSARCHIVEDIR"; }
# 
# [ -d "/usr/local/src/sysarchive" ] || sudo ln -s "$SYSARCHIVEDIR" /usr/local/src/sysarchive

	cat >/dev/null <<-EOF 
		The directory should have the following structure:
		
		|
		|-- boot  (files for reference)
		|-- usr
		|   \-- local
		|       |-- bin  (my scripts)
		|       |-- sbin (my admin scripts)
		|       \-- src  (source tgz files for programs)
		|-- etc   (system configuration files)
		|   |-- init.d   (my service scripts)
		|   \-- ...
		\-- home
		    \-- $USER
		        |-- bin  (personal scripts)
		        \-- ...
EOF

# generic unpack and call autosource called by restore* functions
unpackTo(){
	if [ "$1" == "-dry" ]; then
		local DRY=true
		shift
	fi
	[ $# -gt 3 ] || return 1

	ARCHIVEFILE=${1:-sysarchive-$SECTION.tgz}
	OUTDIR="${2:-/tmp}"
	SUBDIR=$3
	TARARGS=$4

	if [ ! -f "$ARCHIVEFILE" ]; then
		echo "Run this script in the same directory as $ARCHIVEFILE"
		return 1
	fi

	if [ -d "$OUTDIR/$SUBDIR" ] ; then
		read -p "Directory $OUTDIR/$SUBDIR already exists.  Press Enter to remove it, or Ctrl-D to leave it." && \
		sudo rm -vrf "$OUTDIR/$SUBDIR" || echo "  Untarring (by default) overwrite files.  Current tar arguments are: $TARARGS"
	fi
	
	mkdir -p "$OUTDIR" && \
	read -p "About to extract $ARCHIVEFILE to $OUTDIR. Press Enter." && \
	# need sudo to set original ownership
	sudo tar $TARARGS -zxvf "$ARCHIVEFILE" --directory="$OUTDIR"

echo "-------------------------------------------------------"
	pushd "$OUTDIR/$SUBDIR" || { echo "Could not cd $OUTDIR/$SUBDIR !"; return 1; }
	[ "$CHECKFORFILES" ] && for EXPECTED in usr etc; do
		if [ ! -d "$EXPECTED" ] ; then
			echo "Directory not there: $EXPECTED"
			echo " Try in another terminal: tar -zxv --directory=\"$OUTDIR\" -f \"$ARCHIVEFILE\""
			read -p "Press Enter."
		fi
	done
	. autosource
	popd
}

tryTo(){
	echo -n "{"
	eval "$@"
	RETCODE=$?
	if [ $RETCODE -ne 0 ]; then
		echo "!!!!"
		read -p "Could not '$@'. RETVAL=$RETCODE.  Press Enter to continue, or Ctrl-C to quit." 
	fi
	echo "}"
	return $RETCODE
}
mksamedir(){
	tryTo $SUDO mkdir -vp "$1/$2"
	local FILEINFO=`command ls --directory --dereference -l "$2"` 
	local DIRUSER=`echo $FILEINFO | cut -d " " -f 3`
	local DIRGROUP=`echo $FILEINFO | cut -d " " -f 4`
	tryTo sudo chown $DIRUSER.$DIRGROUP "$1/$2"
}
archiveSystemFiles(){
	SECTION=${1:-common}
	ARCHIVEFILE=${2:-sysarchive-$SECTION.tgz}
	MAINFILELIST=${3:-/usr/local/src/sysarchive.lst.txt}
	[ -f "$MAINFILELIST" ] || { echo "File not there: $MAINFILELIST"; return 1; }
	OUTDIR="${4:-/tmp}"
	SUBDIR="sysarchive-$SECTION"
	ARCHIVEDIR="$OUTDIR/$SUBDIR"
	FILELIST="$ARCHIVEDIR/sysarchive-$SECTION.lst.txt"
	if [ -d "$ARCHIVEDIR" ]; then
		read -p "Press Enter to \'rm -rf $ARCHIVEDIR\' or Ctrl-D to continue." && \
		echo "  Removing directory $ARCHIVEDIR" && tryTo sudo rm -rf "$ARCHIVEDIR"
		echo ""
	fi
	tryTo mkdir -p "$ARCHIVEDIR" || return 1

	# extract Files from List "$SECTION" "$MAINFILELIST"
	sed --quiet "/\# ::: ${SECTION}/,/\# :::/p" "$MAINFILELIST" | sed '/^\#/d' > "$FILELIST" || return 2

	#sudo rsync -v --archive --files-from=$FILELIST / $ARCHIVEDIR # rsync doesn't allow '*' in the $FILELIST
	echo "Linking/Copying..."
    exec 3<> $FILELIST
    while read -u 3 FILESTR; do
		for AFILE in $FILESTR; do
			# skip backup files
			case "$AFILE" in
				*.sysarchive.bak | .\#*)
					echo "SKIPPING: $AFILE"
					continue
				;;
			esac
			
			local DIRNAME=`dirname "$AFILE"`
			[ -d "$ARCHIVEDIR/$DIRNAME" ] || SUDO=sudo mksamedir "$ARCHIVEDIR" "$DIRNAME"
			if [ -L "$AFILE" ]; then
				command ls -l "$AFILE" >> "$ARCHIVEDIR/links.txt"
			fi
			if [ -f "$AFILE" ]; then
				#sudo cp -uv --archive --parents $AFILE "$ARCHIVEDIR"				
				tryTo sudo ln -s "$AFILE" "$ARCHIVEDIR/$AFILE"
			elif [ -d "$AFILE" ]; then
				SUDO=sudo mksamedir "$ARCHIVEDIR" "$AFILE"
				# need sudo to get access to files for linking
				tryTo sudo ln -s "$AFILE" "$ARCHIVEDIR/$AFILE"
				if [ -f "$ARCHIVEDIR/$AFILE/Makefile" ]; then
					pushd "$ARCHIVEDIR/$AFILE"
					echo "{  Cleaning $ARCHIVEDIR/$AFILE"
					make clean > /dev/null >&2
					echo "}  done Cleaning"
					popd
				fi
			else
				echo "File not there: $AFILE"
			fi
		done
	done
    exec 3>&-  # close fd 3
	ls -l /etc/rc* > "$ARCHIVEDIR/rcDirs.txt"
	if [ "$checklinks" ]; then
		echo "--- Checking symbolic links ---"
		# list all links
		find "$ARCHIVEDIR" -type l | xargs -i ls -l {} | cut -d ">" -f 2 > "$ARCHIVEDIR/links.txt"
		NUMLINES=`wc -l "$ARCHIVEDIR/links.txt" | cut -d " " -f 1`
		{
		  errors=0
		  i=0
		  while [ $i -lt $NUMLINES ] ; do 
			read FULLFILE
			if [ ! -e $FULLFILE ]; then
				echo "!!! $FULLFILE does not exist; adding it to $MAINFILELIST"
				(echo "# ::: automatically added: "
				echo $FULLFILE ) >> "$MAINFILELIST"
				let errors++
			fi
			let i++
		  done 
		  if [ $errors -gt 0 ] ; then
			echo "$errors Error(s) found.  Try rerunning this."
		  fi
		} < $ARCHIVEDIR/links.txt
	fi

	cd "$OUTDIR" || return 3

	# autosource file for when this is untarred
	echo "#!/bin/bash" > "$SUBDIR/autosource"
	type compareSystemFiles | grep -v "^compareSystemFiles is a function" >> "$SUBDIR/autosource" 
	echo "compareSystemFiles ." >> "$SUBDIR/autosource"

	echo "--- Tarring $ARCHIVEFILE ---"
	# need root access for some files
	tryTo sudo tar --dereference -zvcf "$ARCHIVEFILE" "$SUBDIR" 
	sudo chown $USER "$ARCHIVEFILE"
	chmod a+rw "$ARCHIVEFILE"  || read -p "Could not chmod a+rw $ARCHIVEFILE!!"
	pwd
	tryTo mv -vi "$ARCHIVEFILE" ~/archives/
}
compareSystemFiles(){
	pushd $1 || return 1
    # the next 3 lines allows 'read' to read from file descriptor 3 instead of stdin, so that stdin can be used by sudo and read within while loop
    find . > sysarchive-find.log
    exec 3<> sysarchive-find.log
	while read -u 3 ASYSFILE; do
		case "$ASYSFILE" in
			./sysarchive-*.lst.txt | ./rcDirs.txt | ./links.txt | ./autosource | ./sysarchive-find.log)
				echo "IGNORING: $ASYSFILE"
				continue
				;;
		esac
		[ -d "$ASYSFILE" ] && continue
		if [ -e "/$ASYSFILE" ] ; then
			if sudo file --dereference "$ASYSFILE" | grep -q "text"; then
				if ! sudo diff "$ASYSFILE" "/$ASYSFILE" > /dev/null ; then
					echo "DIFFERENT: $ASYSFILE . Making backup:"
					sudo cp -iv "/$ASYSFILE"{,.sysarchive.bak}
					if [ "$DISPLAY" ] && which xxdiff > /dev/null ; then
						sudo xxdiff "$ASYSFILE" "/$ASYSFILE"
					elif [ -x usr/local/bin/xxdiff ]; then  # check in current directory tree
                        sudo usr/local/bin/xxdiff "$ASYSFILE" "/$ASYSFILE";
					elif which vimdiff > /dev/null; then
						echo vimdiff "/$ASYSFILE" "$ASYSFILE" >> sysarchive-vimdiff.log
					else
						sudo diff --width=$COLUMNS --side-by-side --left-column "$ASYSFILE" "/$ASYSFILE"
						read -p "About to vim /$ASYSFILE and $ASYSFILE"
						echo sudo vim "/$ASYSFILE" -c "split $ASYSFILE" >> sysarchive-vim.log
					fi
				else 
					echo "same: $ASYSFILE"
				fi
			else # probably a binary file
				if ! cmp "$ASYSFILE" "/$ASYSFILE"; then
					echo "DIFFERENT: (binary) $ASYSFILE .  Making backup:"
					sudo cp -iv "/$ASYSFILE"{,.sysarchive.bak} || read -p "Could not 'sudo cp -iv /$ASYSFILE{,.sysarchive.bak}'.  Press Enter to continue." 
					# ask to overwrite
					sudo cp -iv "$ASYSFILE" "/$ASYSFILE"
				else 
					echo "same binary: $ASYSFILE"
				fi
			fi
		else
			echo "Not found: /$ASYSFILE"
			sudo mkdir -pv "/`dirname "$ASYSFILE"`"
			[ ! "$DRY" ] && sudo cp -vp "$ASYSFILE" "/$ASYSFILE" || read -p "Could not 'sudo cp -vp $ASYSFILE /$ASYSFILE'.  Press Enter to continue." 
		fi
	done
    exec 3>&-  # close fd 3
	popd
}

DEBSTGZ="sysarchive-debs.tgz"
archivePackages(){
	local TMPDIR="/tmp/sysarchive-debs"
	local SUBDIR="archives"

	if [ -d "$TMPDIR/$SUBDIR" ]; then
		read -p "Press Enter to 'rm -rf $TMPDIR/$SUBDIR' or Ctrl-D to continue." && \
		echo "  Removing directory $TMPDIR/$SUBDIR" && tryTo sudo rm -rf "$TMPDIR/$SUBDIR"
		echo ""
	fi
	mkdir -vp "$TMPDIR/$SUBDIR"
	pushd "$TMPDIR/$SUBDIR" || return 1

#	local EXTRAPACKAGES="gkrellm2 idesk xfe xautolock"
# echo "-------------------------------------------------------"
# 	if [ "" ] && read -p "About to download packages.  Ctrl-D to skip."; then
# 		for package in $NEWPACKAGES $EXTRAPACKAGES; do
# 			#apt-get --download-only install $package
# 			WGETCOMMAND=`apt-get -qq --print-uris install $package | awk '{print "[ -f \"" $2 "\" ] || wget --output-document=" $2 " " $1}'`
# 			eval $WGETCOMMAND
# 		done
# 	fi

echo "-------------------------------------------------------"
	echo "Including program files ..."
	local PROGRAMS="/usr/local/src/{debs,autosource,fluxbox,smallutils,tablaunch,*.gz,NVIDIA*.run}"
	for ADIR in `eval echo $PROGRAMS`; do
		if [ -d "$ADIR" ]; then
			SUDO=sudo mksamedir . "$ADIR"
			tryTo sudo lndir -withrevinfo "$ADIR" "./$ADIR" 
			[ $? -gt 1 ] && read -p "$? Manually fix this.  Press Enter to contiue."
			if [ -f "./$ADIR/Makefile" ]; then
				pushd "./$ADIR"
				sudo make clean > /dev/null
				popd
			fi
		elif [ -f "$ADIR" ]; then
			SUDO=sudo mksamedir . "`dirname "$ADIR"`"
			tryTo sudo ln -vs $ADIR "./$ADIR"
			[ $? -gt 1 ] && read -p "$? Manually fix this.  Press Enter to contiue."
		else
			echo "Not there: $ADIR"
		fi
	done

	echo "--- Tarring $ARCHIVEFILE ---"
	cd .. # now, should be in $TMPDIR

	sudo chmod a+rw "$SUBDIR"
	# autosource file for when this is untarred
	echo "#!/bin/bash" > "$SUBDIR/autosource"
	type insertPackages | grep -v "^insertPackages is a function" >> "$SUBDIR/autosource" 
	echo "insertPackages ." >> "$SUBDIR/autosource"

	#pwd && read
	tryTo tar --dereference -zcvf "$DEBSTGZ" "$SUBDIR"
	chmod a+rw "$DEBSTGZ"
	tryTo mv -iv "$DEBSTGZ" ~/archives/
	popd
}
insertPackages(){
	sudo mkdir -p /usr/local/src
	sudo mv -iv ${1:-.}/usr/local/src/* /usr/local/src/ 

	# create links to debs so that apt will find them
	for DEB in /usr/local/src/debs/*; do
		ln -s $DEB /var/cache/apt/archives/
	done

}



restoreSystemFiles(){
	SECTION=${1:-common}
	echo "Restoring $1"
	unpackTo "sysarchive-$SECTION.tgz" /tmp "sysarchive-$SECTION" "--same-owner"
}
restorePackages(){  # install programs
	echo "Restoring Packages"
	unpackTo "$DEBSTGZ" /tmp "archives" "--keep-old-files"
}



# use this if user must select a choice
choose(){
	DEFAULT_SELECTION="$1"
	echo "-) $DEFAULT_SELECTION (<Ctrl-D> default)"
	select CHOICE in "$@" "exit"; do
		[ "$CHOICE" == "exit" ] && return 1;
		break;
	done
	[ -z "$CHOICE"  -o -z "${CHOICE// }" ] && CHOICE="$DEFAULT_SELECTION" # if <Ctrl-D>, TASK=null
	echo "You selected '$CHOICE'"
	return 0
}

if [ -f "$1" ]; then
	case "$1" in
		$DEBSTGZ) restorePackages
		;;
		sysarchive-*.tgz) 
			SECTION=${1#*-}
			SECTION=${SECTION%.tgz}
			restoreSystemFiles $SECTION
		;;
		*) echo "Unknown sysarchive!: $1"
		;;
	esac
elif [ "$#" -gt 1 ]; then
	TASK="$1"
	shift
	LOCATION="$1"
	shift
else
	choose restore archive || { echo "Quiting."; return 0; }
	TASK=$CHOICE
	choose common Packages myhome home lips laptop || { echo "Quiting."; return 0; }
	LOCATION=$CHOICE
fi

case "$LOCATION" in
	Packages)
		${TASK}${LOCATION}
	;;
	*)
		echo "Running \"${TASK}SystemFiles $LOCATION\""
		${TASK}SystemFiles $LOCATION
	;;
esac

#	alias archiveCommonFiles='archiveSystemFiles common'
#	alias archiveHomeFiles='archiveSystemFiles home'
#	alias archiveLipsFiles='archiveSystemFiles lips'
#	alias archiveLaptopFiles='archiveSystemFiles laptop'

