ls --color=none /boot/grub/splash/ > /boot/grub/splash.lst
M=`date +%N`
numImages=`cat /boot/grub/splash.lst  | wc -l`
#echo $M $numImages
N=$(($M / 1000 % $numImages + 1))
#echo $N
NEXTSPLASH="`head -n $N /boot/grub/splash.lst | tail -n 1`"
echo "Next grub splash screen = $NEXTSPLASH"
cp -f /boot/grub/splash/$NEXTSPLASH /boot/grub/splash.xpm.gz
