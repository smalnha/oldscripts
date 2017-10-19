#!/bin/bash

CONFIG_FILE=/usr/src/linux/.config
KERNEL_CONFIG=~/bin/src/kernel-config.txt
source $CONFIG_FILE

checkValue(){
	CONFIG_VAR=$1 

	# what it should be
	VAL=$2

	#current .config value
	CONF_VAL=$3
	if [ "$CONF_VAL" == "$VAL" ]; then
		echo "#     good $CONFIG_VAR=$VAL"
	elif [ "$VAL" == "y" -o "$VAL" == "m" ] && [ -z "$CONF_VAL" ]; then
		echo -e "# $CONFIG_VAR is not set;  should be \n$CONFIG_VAR=$VAL"
	elif [ "$VAL" == "n" ] ; then
		if [ "$CONF_VAL" ]; then
			echo -e "# $CONFIG_VAR=$CONF_VAL;  should not be set or \n$CONFIG_VAR=$VAL"
		else
			echo "#     good $CONFIG_VAR=$VAL"
		fi
	else
		echo -e "# $CONFIG_VAR=$CONF_VAL; should be \n$CONFIG_VAR=$VAL"
	fi
}
checkConfig(){
	CONFIG_VAR=$1 
	VAL=$2
	CONF_VAL=$(eval echo "\$$CONFIG_VAR")
	case $VAL in
		y | m | n) checkValue $CONFIG_VAR $VAL $CONF_VAL
			;; 
		.y | .m | .n) checkValue $CONFIG_VAR ${VAL/./} $CONF_VAL
			;;
		\?y | \?m | \?n) checkValue $CONFIG_VAR ${VAL/?/} $CONF_VAL
			;; 
		d | d, )
			echo "Hardware dependent: $CONFIG_VAR=$CONF_VAL"
			echo "  $MODULE $DESC"
			;;
		"" ) ;;
		* ) echo "- $CONFIG_VAR=$VAL"
			;;
	esac
}

cat $KERNEL_CONFIG | cut -f 3,4,5,6 | while read VAR VAL MODULE DESC; do 
	VAR=$(echo $VAR | sed s/\"//g )
	VAL=$(echo $VAL | sed s/\"//g | tr [A-Z] [a-z] )
	case $VAR in
	  *\*)
	  	VAR=`echo ${VAR} | sed s/\*//g`
		grep -o "CONFIG_${VAR}[^ =]*" $CONFIG_FILE | while read WILD_VAR WILD_VAR2; do
			[ "$WILD_VAR" == "\#" ] && WILD_VAR=$WILD_VAR2
			#echo wild: $WILD_VAR=$WILD_VAL
			checkConfig $WILD_VAR $VAL
		done
		;;
	  *) checkConfig `echo CONFIG_$VAR` $VAL
		;;
	esac
done



