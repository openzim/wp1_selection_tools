#!/usr/bin/env bash

######################################################################
# CONFIGURATION                                                      # 
######################################################################

# Parse command line
WIKI_LANG=$1
WIKI=${WIKI_LANG}wiki
PAGEVIEW_CODE=${WIKI_LANG}.z

# Update PATH
SCRIPT_PATH=$0
SCRIPT_DIR=`dirname $SCRIPT_PATH`
export PATH=$PATH:$SCRIPT_DIR

# Setup global variables
DIR=$SCRIPT_DIR/${WIKI}_`date +"%Y-%m"`
TMP=$SCRIPT_DIR/tmp
README=$DIR/README

# Create directories
mkdir $DIR &> /dev/null
mkdir $TMP &> /dev/null

# Perl and sort(1) have locale issues, which can be avoided by
# disabling locale handling entirely.
LANG=C
export LANG

######################################################################
# CHECK COMMAND LINE ARGUMENTS                                       # 
######################################################################

usage() {
    echo "Usage: WP1.sh <lang>"
    echo "  <lang> - such as en, fr, ..."
    exit
}

if [ "$WIKI" = '' ]
then
  usage;
fi

######################################################################
# COMPUTE PAGEVIEWS                                                  # 
######################################################################

# Get namespaces
NAMESPACES=$TMP/namespaces_$WIKI
curl -s "https://$WIKI_LANG.wikipedia.org/w/api.php?action=query&meta=siteinfo&siprop=namespaces&formatversion=2&format=xml" | \
    xml2 2> /dev/null | \
    egrep "@(canonical|ns)=.+" | \
    sed "s/.*=//" | \
    sed "s/ /_/g" | \
    sort -u | \
    tr '\n' '|' | \
    sed "s/^/^(/" | \
    sed "s/.\$/):/" > $NAMESPACES

# Get the list of tarball to download
PAGEVIEW_FILES=$TMP/pageview_files_$WIKI
curl -s https://dumps.wikimedia.org/other/pagecounts-ez/merged/ | \
    html2 2> /dev/null | \
    grep "a=.*totals.bz2" | \
    sed "s/.*a=//" | \
    grep -v pagecounts-2012-01 | \
    grep -v pagecounts-2011 | \
    grep -v pagecounts-2012 | \
    grep -v pagecounts-2013 | \
    grep -v pagecounts-2014 | \
    grep -v pagecounts-2015 > \
    $PAGEVIEW_FILES

# Download pageview dump for all project for a month
NEW_PAGEVIEW_FILES=$TMP/new_pageview_files_$WIKI
PAGEVIEWS=$TMP/pageviews_$WIKI
cat /dev/null > $NEW_PAGEVIEW_FILES
for FILE in `cat $PAGEVIEW_FILES`
do
    OLD_SIZE=`ls -la $TMP/$FILE 2> /dev/null | cut -d " " -f5`
    wget -c https://dumps.wikimedia.org/other/pagecounts-ez/merged/$FILE -O $TMP/$FILE
    NEW_SIZE=`ls -la $TMP/$FILE 2> /dev/null | cut -d " " -f5`

    if [ x$OLD_SIZE != x$NEW_SIZE -o ! -f $PAGEVIEWS ]
    then
	echo "$FILE NEW" >> $NEW_PAGEVIEW_FILES
    else
	echo "$FILE OLD" >> $NEW_PAGEVIEW_FILES
    fi
done

# Extract the content by filtering by project
if [ ! -f $PAGEVIEWS ]
then
    cat /dev/null > $PAGEVIEWS
fi

OLD_SIZE=`ls -la $PAGEVIEWS 2> /dev/null | cut -d " " -f5`
for FILE in `cat $NEW_PAGEVIEW_FILES | grep NEW | cut -d " " -f1`
do
    echo "Parsing $TMP/$FILE..."
    cat $TMP/$FILE | \
	bzcat | \
	grep "^$PAGEVIEW_CODE" | \
	cut -d " " -f2,3 | \
	egrep -v `cat $NAMESPACES` \
	> $PAGEVIEWS.tmp
    cat $PAGEVIEWS $PAGEVIEWS.tmp | \
	sort -t " " -k1,1 -i | \
	perl -ne '($title, $count) = split(" ", $_); if ($title eq $last) { $last_count += $count } else { print "$last\t$last_count\n"; $last=$title; $last_count=$count;}' \
	> $PAGEVIEWS.new
    mv $PAGEVIEWS.new $PAGEVIEWS
    rm $PAGEVIEWS.tmp
    ENTRY_COUNT=`wc $PAGEVIEWS | tr -s ' ' | cut -d " " -f2`
    echo "   '$PAGEVIEWS' has $ENTRY_COUNT entries."
done
NEW_SIZE=`ls -la $PAGEVIEWS 2> /dev/null | cut -d " " -f5`

# Compress the result
COMPRESSED_PAGEVIEWS=$DIR/pageviews.gz
cat $PAGEVIEWS | gzip -9 > $COMPRESSED_PAGEVIEWS

# Update README
echo "pageviews: page_title view_count" > $README

######################################################################
# COMPUTE INDEXES                                                    # 
######################################################################

echo "Gathering wiki data..."

# Pages
echo "pages: page_id page_title is_redirect" >> $README
mysql --defaults-file=~/replica.my.cnf --quick -e \
    "SELECT page_id, page_title, page_is_redirect FROM page WHERE page_namespace = 0" \
    -N -h ${WIKI}.labsdb ${WIKI}_p | gzip -9 > $DIR/pages.gz

# Page links
echo "pagelinks: source_page_id target_page_title" >> $README
mysql --defaults-file=~/replica.my.cnf --quick -e \
    "SELECT pl_from, pl_title FROM pagelinks WHERE pl_namespace = 0 AND pl_from_namespace = 0" \
    -N -h ${WIKI}.labsdb ${WIKI}_p | gzip -9 > $DIR/pagelinks.gz

# Language links
echo "langlinks: source_page_id language_code target_page_title" >> $README
mysql --defaults-file=~/replica.my.cnf --quick -e \
    "SELECT ll_from, ll_lang, ll_title FROM langlinks, page WHERE langlinks.ll_from = page.page_id AND page.page_namespace = 0" \
    -N -h ${WIKI}.labsdb ${WIKI}_p | sed 's/ /_/g' | gzip -9 > $DIR/langlinks.gz

# Redirects
echo "redirects: source_page_id target_page_title" >> $README
mysql --defaults-file=~/replica.my.cnf --quick -e \
    "SELECT rd_from, rd_title FROM redirect WHERE rd_namespace = 0" \
    -N -h ${WIKI}.labsdb ${WIKI}_p | gzip -9 > $DIR/redirects.gz

######################################################################
# SELECT WP1 evaluations                                             # 
######################################################################

if [ $WIKI = 'enwiki' ]
then
    echo "ratings: page_title project quality importance" >> $README
    mysql --defaults-file=~/replica.my.cnf --quick -e \
	"SELECT r_article, r_project, r_quality, r_importance FROM ratings" \
	-N -h enwiki.labsdb p50380g50494_data | gzip -9 > $DIR/ratings.gz
fi

######################################################################
# MERGE lists                                                        # 
######################################################################

$SCRIPT_DIR/merge_lists.pl $DIR | gzip -9 > $DIR/all.gz

######################################################################
# UPLOAD to wp1.kiwix.org                                            # 
######################################################################

echo "Upload $DIR to wp1.kiwix.org"
DIRNAME=`basename $DIR`
FTP_USER=`cat ${SCRIPT_DIR}/ftp.credentials | cut -d "," -f "1"`
FTP_PASS=`cat ${SCRIPT_DIR}/ftp.credentials | cut -d "," -f "2"`
ftp -vinp <<EOF
open wp1.kiwix.org
user $FTP_USER $FTP_PASS
mdel $DIRNAME/*
mkdir $DIRNAME
cd $DIRNAME
lcd $DIR
mput *
close
bye
EOF

######################################################################
# CLEAN DIRECTORY                                                    # 
######################################################################

# Clean
rm -rf $DIR
rm $NAMESPACES
rm $PAGEVIEW_FILES
rm $NEW_PAGEVIEW_FILES
