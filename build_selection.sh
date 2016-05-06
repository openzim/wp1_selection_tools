#!/bin/bash

LANG=C
LANGUAGE=$1
WIKI=$LANGUAGE"wiki"

if [ "$LANGUAGE" = '' ];
then
    echo "usage: build_selection.sh <lang> (en for 'en' for example)"
    exit
fi

CURRENT_VERSION=`curl -s http://dumps.wikimedia.org/$WIKI/latest/$WIKI-latest-abstract.xml-rss.xml | grep "</link>" | tail -n 1 | sed -e 's/<//g' | cut -d "/" -f 5`

if [ "$CURRENT_VERSION" = '' ];
then
    echo "error: no dump are available for this name."
    exit
fi

createDirIfNecessary()
{
  if [ ! -e $1 ]
  then
    mkdir $1
  fi
}

createDirIfNecessary ./tmp/$WIKI
createDirIfNecessary ./tmp/$WIKI/source
createDirIfNecessary ./tmp/$WIKI/target

if [ -e ./tmp/$WIKI/date ]
then
    LAST_VERSION=`cat ./tmp/$WIKI/date`
    if [ ! $LAST_VERSION = $CURRENT_VERSION ]
    then
	rm -f ./tmp/$WIKI/date >& /dev/null
	rm -f ./tmp/$WIKI/source/* >& /dev/null
	rm -f ./tmp/$WIKI/target/* >& /dev/null
	rm -f ./tmp/$WIKI/target/.* >& /dev/null
    fi
fi

echo $CURRENT_VERSION > ./tmp/$WIKI/date

## GET SQL DUMPS FROM dumps.wikimedia.org
echo "Downloading $WIKI-latest-page.sql.gz..."
wget --no-verbose --continue -O ./tmp/$WIKI/source/$WIKI-latest-page.sql.gz http://dumps.wikimedia.org/$WIKI/latest/$WIKI-latest-page.sql.gz

echo "Downloading $WIKI-latest-pagelinks.sql.gz..."
wget --no-verbose --continue -O ./tmp/$WIKI/source/$WIKI-latest-pagelinks.sql.gz http://dumps.wikimedia.org/$WIKI/latest/$WIKI-latest-pagelinks.sql.gz

echo "Downloading $WIKI-latest-langlinks.sql.gz..."
wget --no-verbose --continue -O ./tmp/$WIKI/source/$WIKI-latest-langlinks.sql.gz http://dumps.wikimedia.org/$WIKI/latest/$WIKI-latest-langlinks.sql.gz

echo "Download $WIKI-latest-redirect.sql.gz..."
wget --no-verbose --continue -O ./tmp/$WIKI/source/$WIKI-latest-redirect.sql.gz http://dumps.wikimedia.org/$WIKI/latest/$WIKI-latest-redirect.sql.gz

## BUILD PAGES INDEXES
echo "Computing ./tmp/$WIKI/target/main_pages_sort_by_ids.lst.gz..."
if [ ! -f ./tmp/$WIKI/target/.main_pages_sort_by_ids.lst.gz.finished ]
then
    cat ./tmp/$WIKI/source/$WIKI-latest-page.sql.gz | gzip -d | tail -n +38 | ./bin/pages_parser | egrep "^[0-9]+ 0 " | sort -n -t " " -k 1,1 | gzip > ./tmp/$WIKI/target/main_pages_sort_by_ids.lst.gz
    touch ./tmp/$WIKI/target/.main_pages_sort_by_ids.lst.gz.finished
else
    echo "./tmp/$WIKI/target/main_pages_sort_by_ids.lst.gz already computed."
fi

## BUILD PAGELINKS INDEXES
echo "Computing ./tmp/$WIKI/target/pagelinks.lst.gz..."
if [ ! -f ./tmp/$WIKI/target/.pagelinks.lst.gz.finished ]
then
    cat ./tmp/$WIKI/source/$WIKI-latest-pagelinks.sql.gz| gzip -d | tail -n +28 | ./bin/pagelinks_parser | gzip > ./tmp/$WIKI/target/pagelinks.lst.gz
    touch ./tmp/$WIKI/target/.pagelinks.lst.gz.finished
else
    echo "./tmp/$WIKI/target/pagelinks.lst.gz already computed."
fi

## BUILD LANGLINKS INDEXES
echo "Computing ./tmp/$WIKI/target/langlinks_sort_by_ids.lst.gz..."
if [ ! -f ./tmp/$WIKI/target/.langlinks_sort_by_ids.lst.gz.finished ]
then
    cat ./tmp/$WIKI/source/$WIKI-latest-langlinks.sql.gz | gzip -d | tail -n +28 | ./bin/langlinks_parser | sort -n -t " " -k 1,1 | gzip > ./tmp/$WIKI/target/langlinks_sort_by_ids.lst.gz
    touch "./tmp/$WIKI/target/.langlinks_sort_by_ids.lst.gz.finished"
else
    echo "./tmp/$WIKI/target/langlinks_sort_by_ids.lst.gz already computed."
fi

## BUILD REDIRECT INDEXES
echo "Computing ./tmp/$WIKI/target/redirects_sort_by_ids.lst.gz..."
if [ ! -f ./tmp/$WIKI/target/.redirects_sort_by_ids.lst.gz.finished ]
then
    cat ./tmp/$WIKI/source/$WIKI-latest-redirect.sql.gz | gzip -d | tail -n +28 | ./bin/redirects_parser | sort -n -t " " -k 1,1 | gzip > ./tmp/$WIKI/target/redirects_sort_by_ids.lst.gz
    touch "./tmp/$WIKI/target/.redirects_sort_by_ids.lst.gz.finished"
else
    echo "./tmp/$WIKI/target/redirects_sort_by_ids.lst.gz already computed."
fi

exit

## BUILD CHARTS INDEXES
./bin/filter_charts.pl --chartsDirectory=./tmp/charts/ --language=$LANGUAGE | gzip > ./tmp/$WIKI/target/charts.lst.gz

## BUILD COUNTS
./bin/build_counts.pl --pagesFile=./tmp/$WIKI/target/main_pages_sort_by_ids.lst.gz --pagelinksFile=./tmp/$WIKI/target/pagelinks.lst.gz --langlinksFile=./tmp/$WIKI/target/langlinks_sort_by_ids.lst.gz --redirectsFile=./tmp/$WIKI/target/redirects_sort_by_ids.lst.gz --chartsFile=./tmp/$WIKI/target/charts.lst.gz | gzip > ./tmp/$WIKI/target/counts_sort_by_ids.lst.gz

## BUILD IMPORTANCE SCORES
./bin/build_importance_scores.pl --countsFile=./tmp/$WIKI/target/counts_sort_by_ids.lst.gz | gzip > ./tmp/$WIKI/target/importance_scores.lst.gz