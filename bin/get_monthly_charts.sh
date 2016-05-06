#!/bin/sh

export LC_ALL=C

DATADIR=$1
BINDIR=`dirname $0`
BINDIR=`cd $BINDIR; pwd`/

cd $DATADIR

# Get the months
MONTHS=`for FILE in \`find . -name "*bz2"\`; do echo $FILE | cut -b 3,4,5,6,7,8 ; done | sort -u`;

# current month
CURRENT_MONTH=`date "+%Y%m"`

# Get through the months
for MONTH in $MONTHS
do
    if [ $MONTH -lt $CURRENT_MONTH ]
    then
	$BINDIR/mergesort.pl ./$MONTH*bz2 | $BINDIR/simplify_charts.pl | lzma -c > $MONTH.lzma
	rm $MONTH*.bz2
    fi
done
