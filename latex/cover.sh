#!/bin/bash

#[ "$MY_BIN" ] || { echo "MY_BIN is not set!"; exit 1; }
: ${MY_BIN_LATEX:="$MY_BIN/latex"}
[ -d "$MY_BIN_LATEX" ] || { echo "MY_BIN_LATEX=$MY_BIN_LATEX does not exists!  export MY_BIN or MY_BIN_LATEX."; exit 1; }

# requires pdftk
which pdftk || { echo "pdftk not found. Please install pdftk." ; exit 1; }

# You could use a tool like pdfinfo (part of xpdf) to discover how many pages each input PDF has
#LINE_SEPARATOR="NNN"
[ "$CLEANUP" ] || CLEANUP="true"

if [ ! -f "paperinfo.src" ] ; then 
	echo "Creating paperinfo.src"
	PDF_FILE="${INFILE:-`command ls *.pdf | head -1`}"
	cat <<EOF > "paperinfo.src"
#!/bin/bash

# cover page info
REPORT_ID="`basename $PDF_FILE .pdf`"
TITLE_STRING="Paper Title"
AUTHORS="A. B. Last"
EMAILS="\{email1,email2\}@mail.edu"
YEAR="2005"  # copyright year
DATE="December 10, 2004"

# header
HEADER_STRING="first line
second line" 

# FOOTER_STRING="Copyright "'\\\\'"copyright \$YEAR The University of Texas at Austin
# LIPS"

# pdf
PDF_FILE="\$REPORT_ID.pdf"
#OUT_FILE="final.pdf"

EOF
	echo "Edit paperinfo.src and run $0 again with the -h and/or -f options."
	exit 0
fi

if [ -f "paperinfo.src" ] ; then 
	. paperinfo.src
	INFILE=$PDF_FILE
else
	echo "paperinfo.src not found !!"
	exit 1
fi

while [ "$1" ]; do
	case $1 in
		-h)	shift
			HEADER_STRING=$1
			shift
			;;
		-f)	shift
			FOOTER_STRING=$1
			shift
			;;
		-o) shift
			OUT_FILE=$1
			shift
			;;
		--help)
			echo "Look at the file paperinfo.src.  INFILE=$INFILE"
			exit
		;;
		*)
			echo :$1
			[ -f "$1" ] && INFILE=$1
			shift
			;;
	esac
done

[ -f "$INFILE" ] || { echo "File not found $INFILE."; exit 1; }

export TEXINPUTS=.:$MY_BIN_LATEX:

replaceLineSeparator(){
#	echo ${1//$LINE_SEPARATOR/\\\\\\\\} && return 0;
	unset IFS
	local OUT
	echo "$1" | { while read ALINE; do [ "$ALINE" ] && OUT="$OUT $ALINE \\\\\\\\ "; done; echo $OUT; }
}

addHeader(){
	[ -f "$1-header.pdf" ] && rm -iv "$1-header.pdf"
	[ -f "$1-header.pdf" ] && return 1
	[ "$YEAR" ] || { echo "YEAR is not set"; return 1; }
	sed "s/%YEAR%/{$YEAR}/g" $MY_BIN_LATEX/header.tex > header.tex

	HEADER_STRING=`replaceLineSeparator "$HEADER_STRING"`
	if [ "$HEADER_STRING" ]; then
		sed -i "/%HEADER%/a \\
		\\\\renewcommand{\\\\headrulewidth}{0.2pt} \\
		\\\\chead{\\\\parbox{6in}{\\\\centering \\
			{$HEADER_STRING} \\
			\\\\vspace{5pt} \\
		}}" header.tex
	else
		sed -i "/%HEADER%/a  \\
		\\\\renewcommand{\\\\headrulewidth}{0pt}" header.tex
	fi

	FOOTER_STRING=`replaceLineSeparator "$FOOTER_STRING"`
	if [ "$FOOTER_STRING" ]; then
		sed -i "/%FOOTER%/a \\
		\\\\renewcommand{\\\\footrulewidth}{0.2pt} \\
		\\\\cfoot{\\\\parbox{6in}{\\\\centering \\
			{$FOOTER_STRING} \\
		}}" header.tex
	else
		sed -i "/%FOOTER%/a  \\
		\\\\renewcommand{\\\\footrulewidth}{0.2pt} \\
		\\\\cfoot{\\\\parbox{6in}{ \\\\centering \\
			Copyright \\\\copyright\\\\ \\\\copyrightYear\\\\ The University of Texas at Austin \\\\\\\\ \\
			The Laboratory for Intelligent Process and Systems \\
		}}" header.tex
	fi

	latex2pdf.sh header.tex && \
	echo "------------- Adding header to all pages in $1 ---------------" && \
	[ -f "header.pdf" ] && pdftk $1 background header.pdf output "$1-header.pdf"
	[ "$CLEANUP" = "true" ]  && rm header.*
	LAST_FILE="$1-header.pdf"
}

addCoverPage(){
	[ -f "$1-cover.pdf" ] && rm -iv "$1-cover.pdf"
	[ -f "$1-cover.pdf" ] && return 1
	[ "$YEAR" ] || { echo "YEAR is not set"; return 1; }

	TITLE_STRING=`replaceLineSeparator "$TITLE_STRING"`
	#eval sed \'s/%TITLE%/{$TITLE_STRING}/g\; s/%REPORT_ID%/{$REPORT_ID}/g\; s/%AUTHORS%/{$AUTHORS}/g\; s/%EMAILS%/{$EMAILS}/g\; s/%YEAR%/{$YEAR}/g\; s/%DATE%/{$DATE}/g \' $MY_BIN_LATEX/coverpage.tex > cover.tex
	sed "s/%TITLE%/{$TITLE_STRING}/g ; s/%REPORT_ID%/{$REPORT_ID}/g ; s/%AUTHORS%/{$AUTHORS}/g ; s/%EMAILS%/{$EMAILS}/g ; s/%YEAR%/{$YEAR}/g ; s/%DATE%/{$DATE}/g " $MY_BIN_LATEX/coverpage.tex > cover.tex

	latex2pdf.sh cover.tex && \
	echo "------------- Adding cover page to $1 ---------------" && \
	[ -f "cover.pdf" ] && pdftk cover.pdf $1 cat output "$1-cover.pdf"
	[ "$CLEANUP" = "true" ] && rm cover.*
	LAST_FILE="$1-cover.pdf"
}

addBoth(){
	addHeader "$1" && \
	addCoverPage "$LAST_FILE"
}


removeFirstPageAddBoth(){
	pdftk $1 cat 2-end output "$1-pg1removed.pdf" && \
	addBoth "$1-pg1removed.pdf"
}

choose(){
	DEFAULT_SELECTION="$1"
	echo "-) $DEFAULT_SELECTION (<Ctrl-D> default)"
	select CHOICE in "$@" "exit"; do
		[ "$CHOICE" == "exit" ] && return 1;
		break;
	done
	[ -z "$CHOICE"  -o -z "${CHOICE// }" ] && CHOICE="$DEFAULT_SELECTION" # if <Ctrl-D>, TASK=null
	# echo "You selected '$CHOICE'"
	return 0
}
choose addCoverPage addHeader addBoth removeFirstPageAddBoth || { echo "Quiting."; exit 0; }
echo "You selected $CHOICE"

if $CHOICE "$INFILE"; then
	if [ "$OUT_FILE" ] ; then
		mv -iv "$LAST_FILE" "$OUT_FILE" 
	else
		OUT_FILE=$LAST_FILE
	fi
	echo OUT_FILE=$OUT_FILE
	#open.sh "$OUT_FILE"
fi

