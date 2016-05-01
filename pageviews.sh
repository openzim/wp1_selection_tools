#!/bin/bash

# Download pageview dump for all project for a month
wget -c https://dumps.wikimedia.org/other/pagecounts-ez/merged/pagecounts-2016-04-views-ge-5-totals.bz2

# Get namespaces
curl -s "https://en.wikipedia.org/w/api.php?action=query&meta=siteinfo&siprop=namespaces&formatversion=2&format=xml" | \
    xml2 | \
    grep "@canonical" | \
    sed "s/.*@canonical=//" | \
    sed "s/ /_/g" | \
    tr '\n' '|' | \
    sed "s/^/^(/" | \
    sed "s/.\$/):/" > /tmp/ns

# Extract the content by filtering out the
cat pagecounts-2016-04-views-ge-5-totals.bz2 | \
    bzcat | \
    grep "^en.z" | \
    cut -d " " -f2,3 | \
    egrep -v `cat /tmp/ns` | \
    sort -t " " -k1,1 -d -i | \
    perl -ne '($title, $count) = split(" ", $_); if ($title eq $last) { $last_count += $count } else { print "$last $last_count\n"; $last=$title; $last_count=$count;}' > pageviews

# Clean
rm /tmp/ns