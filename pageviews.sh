#!/bin/bash

# Get namespaces
curl -s "https://en.wikipedia.org/w/api.php?action=query&meta=siteinfo&siprop=namespaces&formatversion=2&format=xml" | \
    xml2 | \
    grep "@canonical" | \
    sed "s/.*@canonical=//" | \
    sed "s/ /_/g" | \
    tr '\n' '|' | \
    sed "s/^/^(/" | \
    sed "s/.\$/):/" > /tmp/ns

# Get the list of tarball to download
curl -s https://dumps.wikimedia.org/other/pagecounts-ez/merged/ | \
    xml2 | \
    grep "a=.*totals.bz2" | \
    sed "s/.*a=//" | \
    grep -v pagecounts-2012-01 > \
    /tmp/bz2

# Download pageview dump for all project for a month
cat /dev/null > /tmp/files
for FILE in `cat /tmp/bz2`
do
    OLD_SIZE=`ls -la $FILE | cut -d " " -f5`
    wget -c https://dumps.wikimedia.org/other/pagecounts-ez/merged/$FILE
    NEW_SIZE=`ls -la $FILE | cut -d " " -f5`

    if [ x$OLD_SIZE != x$NEW_SIZE -o ! -f pageviews ]
    then
	echo "$FILE NEW" >> /tmp/files
    else
	echo "$FILE OLD" >> /tmp/files
    fi
done

# Extract the content by filtering by project
cat /dev/null > pageviews
for FILE in `cat /tmp/files | grep NEW | cut -d " " -f1`
do
    echo "Parsing $FILE..."
    cat $FILE | \
	bzcat | \
	grep "^en.z" | \
	cut -d " " -f2,3 | \
	egrep -v `cat /tmp/ns` \
	> pageviews.tmp
    cat pageviews pageviews.tmp | \
	sort -t " " -k1,1 -i | \
	perl -ne '($title, $count) = split(" ", $_); if ($title eq $last) { $last_count += $count } else { print "$last $last_count\n"; $last=$title; $last_count=$count;}' \
	> pageviews.new
    mv pageviews.new pageviews
    rm pageviews.tmp
    ENTRY_COUNT=`wc pageviews | tr -s ' ' | cut -d " " -f2`
    echo "   'pageviews' has $ENTRY_COUNT entries."
done

# Clean
rm /tmp/ns
rm /tmp/bz2