#!/bin/bash

function showFields(){
echo ---------------------------------------------
echo First=$First
echo Middle=$Middle
echo Last=$Last
echo Nickname=$Nickname
echo Email=$Email
echo Category=$Category
echo DistributionLists=$DistributionLists
echo YahooID=$YahooID
echo Home=$Home
echo Work=$Work
echo Pager=$Pager
echo Fax=$Fax
echo Mobile=$Mobile
echo Other=$Other
echo YahooPhone=$YahooPhone
echo Primary=$Primary
echo AlternateEmail1=$AlternateEmail1
echo AlternateEmail2=$AlternateEmail2
echo PersonalWebsite=$PersonalWebsite
echo BusinessWebsite=$BusinessWebsite
echo Title=$Title
echo Company=$Company
echo -e "WorkAddress=$WorkAddress"
echo WorkCity=$WorkCity
echo WorkState=$WorkState
echo WorkZIP=$WorkZIP
echo WorkCountry=$WorkCountry
echo -e "HomeAddress=$HomeAddress"
echo HomeCity=$HomeCity
echo HomeState=$HomeState
echo HomeZIP=$HomeZIP
echo HomeCountry=$HomeCountry
echo Birthday=$Birthday
echo Anniversary=$Anniversary
echo Custom1=$Custom1
echo Custom2=$Custom2
echo Custom3=$Custom3
echo Custom4=$Custom4
echo Comments=$Comments
echo Extra=$Extra
}

function showShortForm(){
    echo ---------------------------------------------
    echo "$Last, $First $Middle \"$Nickname\" ($Title)"
    echo -n $Email
    [ "$AlternateEmail1" ] && echo -n "   $AlternateEmail1"
    [ "$AlternateEmail2" ] && echo -n "   $AlternateEmail2"
    echo ""
    echo [$Category] $DistributionLists
    [ "$PersonalWebsite" ] && echo -n " $PersonalWebsite"
    [ "$YahooID"     ] && echo -n "  YahooID=$YahooID"
    [ "$YahooPhone"  ] && echo -n "  YahooPhone=$YahooPhone"
    [ "$Birthday"    ] && echo -n "  Birthday=$Birthday"
    [ "$Anniversary" ] && echo -n "  Anniversary=$Anniversary"
    echo ""
    echo Primary=$Primary
    [ "$Home"   ] && echo "  home=$Home"
    [ "$Work"   ] && echo "  work=$Work"
    [ "$Mobile" ] && echo "  mobile=$Mobile"
    [ "$Pager"  ] && echo "  pager=$Pager"
    [ "$Fax"    ] && echo "  fax=$Fax"
    [ "$Other"  ] && echo "  other=$Other"
    [ "$HomeAddress$HomeCity" ] && echo $HomeAddress, $HomeCity, $HomeState $HomeZIP $HomeCountry
    [ "$Company$BusinessWebsite" ] && echo $Company $BusinessWebsite
    [ "$WorkAddress$WorkCity" ] && echo $WorkAddress, $WorkCity, $WorkState $WorkZIP $WorkCountry
    [ "$Custom1" ] && echo Custom1=$Custom1
    [ "$Custom2" ] && echo Custom2=$Custom2 
    [ "$Custom3" ] && echo Custom3=$Custom3 
    [ "$Custom4" ] && echo Custom4=$Custom4 
    [ "$Comments" ] && echo Comments=$Comments
}

toPine(){
echo -ne "$Nickname\t$Last, $First $Middle\t$Email\t\t"
echo " [$Category] YahooID=$YahooID home=$Home work=$Work mobile=$Mobile pager=$Pager fax=$Fax other=$Other, $Company $BusinessWebsite $PersonalWebsite $AlternateEmail1 $AlternateEmail2"
}

toNokia(){
    case "$Category" in
        Family | Friends | [0-3].* )
            
        ;;
        *) echo "-- Skipping $First $Last in category $Category" >&2
           return 1
    esac
    APHONE=$Mobile
    [ "$APHONE" ] || APHONE=$Home
    [ "$APHONE" ] || APHONE=$Work
    [ "$APHONE" ] || APHONE=$Pager
    [ "$APHONE" ] && echo -e "$First $Last,$APHONE,$Email"
}

toAbook(){
    echo ""
    echo "# ($Nickname) $First $Middle $Last"
    let i=$i+1
    echo "[$i]"
    echo name=$Last, $First $Middle
    echo -n email=$Email
    [ "$AlternateEmail1" ] && echo -n ",$AlternateEmail1"
    [ "$AlternateEmail2" ] && echo -n ",$AlternateEmail2"
    echo ""
    echo address=$HomeAddress
    echo city=$HomeCity
    echo state=$HomeState
    echo zip=$HomeZIP
    echo country=$HomeCountry
    echo phone=$Home
    echo workphone=$Work
    echo fax=$Fax
    echo mobile=$Mobile
    echo nick=$Nickname
    echo url=$PersonalWebsite
    echo notes=$Comments
    echo custom1=$YahooID
    echo custom2=$Category
    echo custom3=$Company
    echo custom4=$BusinessWebsite
    echo custom5=$Title

    # echo DistributionLists=$DistributionLists
    # echo Pager=$Pager
    # echo Other=$Other
    # echo YahooPhone=$YahooPhone
    # echo Primary=$Primary
    # echo WorkAddress=$WorkAddress
    # echo WorkCity=$WorkCity
    # echo WorkState=$WorkState
    # echo WorkZIP=$WorkZIP
    # echo WorkCountry=$WorkCountry
    # echo Birthday=$Birthday
    # echo Anniversary=$Anniversary
    # echo Custom1=$Custom1
    # echo Custom2=$Custom2
    # echo Custom3=$Custom3
    # echo Custom4=$Custom4
}

toGMail(){
    echo -n "$First $Middle $Last,$Email,\""
    [ "$Birthday" ] && echo -en "\nDOB: $Birthday"
    [ "$Anniversary" ] && echo -en "\nAnniversary: $Anniversary"
    [ "$Category" ] && echo -en "\nCategory: $Category"
    [ "$Custom1" ] && echo -en "\n$Custom1"
    [ "$Custom2" ] && echo -en "\n$Custom2"
    [ "$Custom3" ] && echo -en "\n$Custom3"
    [ "$Custom4" ] && echo -en "\n$Custom4"
    [ "$Comments" ] && echo -en "\n$Comments"
    echo -n "\",Home,"
    echo -n "$AlternateEmail1"
    [ "$AlternateEmail2" ] && echo -n " ::: "
    echo -n "$AlternateEmail2"
    echo -n ",$YahooID"
   #phone
    echo -n ",$Home"
    echo -n ",$Mobile"
    echo -n ",$Pager"
    echo -n ",$Fax"
   #company
    echo -n ","
   #title
    echo -n ",$Nickname,"
   #other
    [ "$PersonalWebsite" ] && echo -n "URL: $PersonalWebsite"
    [ "$Other" ] && echo -n " ::: $Other"
    echo -n ",\""
   if [ "$HomeAddress$HomeCity$HomeState$HomeZIP$HomeCountry" ]; then
    [ "$HomeAddress" ] && echo -en "$HomeAddress\n"
    [ "$HomeCity" ] && echo -n "$HomeCity, "
    echo -n "$HomeState $HomeZIP"
    [ "$HomeCountry" ] && echo -n ", $HomeCountry"
   fi
    echo -n "\","
   # Section 2
    echo -n "Work,$AlternateEmail1"
   # IM
    echo -n ","
    echo -n ",$Work" #phone
   # mobile, pager, fax
    echo -n ",$YahooPhone,,"
    echo -n ",$Company"
    echo -n ",$Title,"
   #other
    [ "$BusinessWebsite" ] && echo -n "URL: $BusinessWebsite"
   echo -n ",\""
   if [ "$WorkAddress$WorkCity$WorkState$WorkZIP$WorkCountry" ]; then
    [ "$WorkAddress" ] && echo -en "$WorkAddress\n"
    [ "$WorkCity" ] && echo -n "$WorkCity, "
    echo -n "$WorkState $WorkZIP"
    [ "$WorkCountry" ] && echo -n ", $WorkCountry"
   fi
    echo -n "\""

   # Section 3
    # echo DistributionLists=$DistributionLists
    # echo Primary=$Primary
    echo ""
}

function find(){
	if [ "$1" ] ; then
		if echo "$First$Middle$Last$Nickname$Email" | grep -q -i "$1" ; then
			showShortForm
		fi
	else 
		echo "\'find\' should be followed by first, middle, last, nickname, or email"
	fi
}


if [ -z "$INFILE" ]; then
	INFILE=$TMP/google.csv
	for GMAILCSV in {$HOME,$HOME/NOBACKUP,$HOME/NOBACKUP/Download}/*oogle.csv; do
		if [ -f "$GMAILCSV" ]; then
			tr -cd '\11\12\40-\176' < "$GMAILCSV" >| "$INFILE"
			rm -f "$GMAILCSV"
			break
		fi
	done
fi

if [ -z "$INFILE" ]; then
    INFILE=$TMP/Yahoo.csv
    for YAHOOFILE in {$HOME/,$HOME/bin/pim/,$HOME/Desktop/}yahoo_ab.csv $HOME/NOBACKUP/{,download/}yahoo*.csv ; do
        if [ -f "$YAHOOFILE" ]; then
         #sed 's/\r\n$/\\\\\\\\n/g' "$YAHOOFILE" > "$INFILE"
           sed 's/\(,"[^"]*\)\r/\1\\\\n\\/' "$YAHOOFILE" > "$INFILE"
           dos2unix "$INFILE"
           rm -fv "$YAHOOFILE"
        fi
    done
fi

if [ -f "$INFILE" ]; then
	echo "Input file: $INFILE"
else
	echo "Can't find an input file!"
	exit 2
fi

if [ "$1" ]; then
   AUTOMATED="T"
	CHOICE="$1"
   shift
elif [ "do toAbook by default" ]; then
	CHOICE="toAbook"
else
	. $MY_BINSRC/helperfuncs.src
	choose toAbook toPine toMozilla toGMail list showFields
fi

CLEANUP=""
case $CHOICE in
    toMozilla)
        rm mozilla.addressbook.csv
        $MY_BIN/pim/mozilla.sed Yahoo.csv > mozilla.addressbook.csv
        exit 0
    ;;
    toPine) #alias Yahoo2Pine='rm ~/.addressbook; ./pine.sed Yahoo.csv | tr --delete \" > ~/.addressbook'
        functor=$CHOICE
        OUTFILE="$HOME/.addressbook"
    ;;
    toAbook)
        functor=$CHOICE
        OUTFILE="$HOME/.abook/addressbook"
        #CLEANUP="abook"
    ;;
    toGMail)
        functor=$CHOICE
        OUTFILE="$HOME/NOBACKUP/gmailAddress.csv"
        CLEANUP="cat $OUTFILE"
        HEADER='Name,E-mail,Notes,Section 1 - Description,Section 1 - Email,Section 1 - IM,Section 1 - Phone,Section 1 - Mobile,Section 1 - Pager,Section 1 - Fax,Section 1 - Company,Section 1 - Title,Section 1 - Other,Section 1 - Address,Section 2 - Description,Section 2 - Email,Section 2 - IM,Section 2 - Phone,Section 2 - Mobile,Section 2 - Pager,Section 2 - Fax,Section 2 - Company,Section 2 - Title,Section 2 - Other,Section 2 - Address'
    ;;
    find)
        functor=$CHOICE
        OUTFILE="/tmp/abookfind-$USER"
        CLEANUP="cat $OUTFILE; rm $OUTFILE"
    ;;
    toNokia)
        functor=$CHOICE
        OUTFILE="/tmp/abook-$USER"
        CLEANUP="cat $OUTFILE; rm $OUTFILE"
    ;;
    list)
        functor=showShortForm
        OUTFILE="/tmp/abook-$USER"
        CLEANUP="cat $OUTFILE; rm $OUTFILE"
    ;;
    showFields)
        functor=showFields
        OUTFILE="/tmp/abook-$USER"
        CLEANUP="cat $OUTFILE; rm -iv $OUTFILE"
    ;;
    exit)
        exit 0
    ;;
    *)
        echo "Unsupported!!"
        exit 1
esac

if [ -f "$OUTFILE" ] ; then
    mv -fv $OUTFILE{,.bak} || read -p "Could not create backup file. Press Enter to continue or Ctrl-C to quit." || exit 1
fi

case "$INFILE" in
	*Yahoo.csv)
{
echo "$HEADER"
IFS='"'
while read comma First comma Middle comma Last comma Nickname comma Email comma Category comma DistributionLists comma YahooID comma Home comma Work comma Pager comma Fax comma Mobile comma Other comma YahooPhone comma Primary comma AlternateEmail1 comma AlternateEmail2 comma PersonalWebsite comma BusinessWebsite comma Title comma Company comma WorkAddress comma WorkCity comma WorkState comma WorkZIP comma WorkCountry comma HomeAddress comma HomeCity comma HomeState comma HomeZIP comma HomeCountry comma Birthday comma Anniversary comma Custom1 comma Custom2 comma Custom3 comma Custom4 comma Comments Extra; do
    if [ "$First$Middle$Last$Nickname" ] && [ "$First$Middle$Last$Nickname" != ",,,," ] ; then
        if [ -z "$DEBUG" ]; then
            [ "$First" != "First" ] && $functor $*            
        else
            $functor $*
        fi
    fi
done < $INFILE 
} > $OUTFILE
;;

	contacts.vcf)
	perl /usr/share/doc/abook/examples/vcard2abook.pl $INFILE $HOME/.abook/addressbook
;;
	*oogle.csv)
echo "<root>" > $INFILE.xml
csv2xml < $INFILE >> $INFILE.xml
echo "</root>" >> $INFILE.xml
xsltproc $MY_BIN/online/pim/gmail2abook.xsl $INFILE.xml >| $OUTFILE
rm -f "$INFILE.xml"
;;

	*) echo "Unsupported format"
esac

eval $CLEANUP

