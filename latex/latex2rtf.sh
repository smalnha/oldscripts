
DESTDIR=rtf
rm -rf $DESTDIR
mkdir $DESTDIR
# cp *.png $DESTDIR/
cp *.aux $DESTDIR/
for TEXFILE in $1.tex ;  do
	echo "preprocessing -> $DESTDIR/$TEXFILE"
	$MY_BIN/latex/latex4rtf.sed $TEXFILE > $DESTDIR/$TEXFILE
done

cd $DESTDIR
FILEBASE=$1
# latex $FILEBASE.tex
# bibtex $FILEBASE
# makeindex $FILEBASE
#latex $FILEBASE.tex
#latex $FILEBASE.tex
$MY_BIN/latex/latex2rtf -P ~/work/dung_lam/latex2rtf/cfg $FILEBASE.tex
echo " ====================  Post-processing $FILEBASE.rtf file"

# $FILEBASE.rtf
# {{\qc{ {\field{\fldinst{INCLUDEPICTURE "approach.gif"}}}}\par
sed "s/\(\\\pict\)/\1{\\\*\\\picprop{\\\sp{\\\sn fLockAspectRatio}{\\\sv 0}}}\\\picscalex100\\\picscaley100/" $FILEBASE.rtf | \
sed "s/{{{$/\\\qc {{{/" | \
sed "s/\(\\\qc \\\fi0 [{]Figure\)/\\\par \1/" > $FILEBASE.final.rtf

