#!/bin/sh

# environment variables used by gs, which is called by ps2pdf
GS_OPTIONS=""
GS_DEVICE=""

case "$1" in 
	*.ps)
		BASENAME=`basename "$1" .ps`
		echo "-------- Converting ${BASENAME}.ps to pdf ..."
		echo "    if pdf font looks bad, \\usepackage{pslatex} and/or {mathptmx}"
		echo "    If you \usepackage{times} or -Ppdf, ligatures (like fi, ff, fl etc.) are mapped incorrectly. To remedy this, add -G0 (that's a zero) to the dvips command line switches. Fixed in dvips v. 5.90"
		# Level 1.2 Compatibility causes extra space after "fi" ligatures in times font
		ps2pdf -dCompatibilityLevel=1.3 -dPDFSETTINGS=/prepress -dMaxSubsetPct=100 \
			-dSubsetFonts=true -dEmbedAllFonts=true \
			-dEncodeColorImages=true -dAutoFilterColorImages=false -dColorImageFilter=/FlateEncode \
			-dEncodeGrayImages=true -dAutoFilterGrayImages=false -dGrayImageFilter=/FlateEncode \
			-dEncodeMonoImages=true -dAutoFilterMonoImages=false -dMonoImageFilter=/FlateEncode "${BASENAME}.ps"
	;;
	*)
		echo "Unknown extension"
	;;
esac

