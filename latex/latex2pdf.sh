#!/bin/bash

#. $MY_BINSRC/functions.src

TEMP=`getopt -o ad:t: -- "$@"`
echo "Parameters: $TEMP"
eval set -- "$TEMP"
while true ; do
	case "$1" in
		-a) echo "will open in acrobat reader" ; READ=1 ; shift 1 ;;
		-t) echo "using paper type = $2" ; PAPEROPT="-t $2" ; shift 2 ;;
		-d) echo "using dvi options = $2" ; DVIOPT="$2" ;  shift 2 ;;
		--) shift ; break ;;
		*) echo "!Unknown parameter $1" ; sleep 10; return 1 ;;
	esac
done
FILEW="$1"
unset BASENAME
if [[ "$FILEW" == *.tex ]] ; then
	echo "-------- Converting ${BASENAME:=`basename "$FILEW" .tex`} to dvi ..."
	latex "$FILEW" || exit 1
	if grep '\\bibliography' "$FILEW"; then
		echo "--------  Creating bibliography for ${BASENAME:=`basename "$FILEW" .tex`} ..."
		bibtex "$BASENAME" && \
		latex "$FILEW" && \
		latex "$FILEW"
	fi
	FILEW="$BASENAME".dvi
	echo "--------> $FILEW"
fi

if [[ ! -z "$BASENAME"  || "$FILEW" == *.dvi ]] ; then
	echo "-------- Converting ${BASENAME:=`basename $FILEW .dvi`} to ps ..."
	echo "    use -G0 option if you see strange 'ff' ligatures"
	echo "    -Ppdf doesn't consistently work but -Pcmz -Pamz does (and you don't need to \\usepackage{times or pslatex}" 
	#echo "		if warning about your system does not have the fonts, it won't have the configuration file either; however, it might have the configuration file without the fonts. In either case, you need to install the fonts. http://www.tex.ac.uk/cgi-bin/texfaq2html?label=fuzzy-type3"
	echo "dvips ${DVIOPT:--Pcmz -Pamz} ${PAPEROPT:--t letter} -o '$BASENAME.ps' '$BASENAME.dvi'"
	      dvips ${DVIOPT:--Pcmz -Pamz} ${PAPEROPT:--t letter} -o "$BASENAME.ps" "$BASENAME.dvi" || exit 1
	FILEW="$BASENAME.ps"
	sed 's/^\(%%Title:.*\)\.dvi/\1/' -i "$FILEW"
	echo "--------> $FILEW"
fi

if [[ ! -z "$BASENAME"  || "$FILEW" == *.ps ]] ; then
	ps2pdf.sh "$FILEW" || exit 1
	FILEW="$BASENAME.pdf"
	echo "--------> $FILEW"
fi

if [ ${READ:-0} -eq 1 ] ; then
	if [ -f "$FILEW" ] ; then
		echo "Opening $FILEW in acroread"
		acroread "$FILEW" &
	else
		echo "File not found: $FILEW"
	fi
fi
