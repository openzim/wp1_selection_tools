#!/usr/bin/env bash

######################################################################
# CONFIGURATION                                                      # 
######################################################################

# Stop if any problem
set -e
set -o pipefail

# Parse command line
WIKI_LANG=$1
WIKI_LANG_SHORT=`echo $WIKI_LANG | sed 's/\(^..\).*/\1/'`
WIKI=${WIKI_LANG}wiki
PAGEVIEW_CODE=${WIKI_LANG}.z

# WIKI DB
DB_HOST=${WIKI_LANG_SHORT}wiki.analytics.db.svc.eqiad.wmflabs
DB=`echo ${WIKI} | sed 's/-/_/g'`_p

# WP1 DB
WP1_DB_HOST=tools.db.svc.eqiad.wmflabs
WP1_DB=s51114_enwp10

# Update PATH
SCRIPT_PATH=$0
SCRIPT_DIR=`dirname $SCRIPT_PATH`
export PATH=$PATH:$SCRIPT_DIR

# Setup global variables
DIR=$SCRIPT_DIR/${WIKI}_`date +"%Y-%m"`
TMP=$SCRIPT_DIR/tmp
README=$DIR/README

# Create directories
if [ ! -d $DIR ]; then mkdir $DIR &> /dev/null; fi
if [ ! -d $DIR ]; then mkdir $TMP &> /dev/null; fi

# Perl and sort(1) have locale issues, which can be avoided by
# disabling locale handling entirely.
PERL=`whereis perl | cut -f2 -d " "`
LANG=C
export LANG

######################################################################
# CHECK COMMAND LINE ARGUMENTS                                       # 
######################################################################

usage() {
    echo "Usage: $0 <lang>"
    echo "  <lang> - such as en, fr, ..."
    exit
}

if [ "$WIKI_LANG" = '' ]
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

    OLD_SIZE=0
    if [ -f $TMP/$FILE ]
    then
	OLD_SIZE=`ls -la $TMP/$FILE 2> /dev/null | cut -d " " -f5`
    fi
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
	$PERL -ne '($title, $count) = split(" ", $_); if ($title eq $last) { $last_count += $count } else { print "$last\t$last_count\n"; $last=$title; $last_count=$count;}' \
	> $PAGEVIEWS.new
    mv $PAGEVIEWS.new $PAGEVIEWS
    rm $PAGEVIEWS.tmp
    ENTRY_COUNT=`wc $PAGEVIEWS | tr -s ' ' | cut -d " " -f2`
    echo "   '$PAGEVIEWS' has $ENTRY_COUNT entries."
done
NEW_SIZE=`ls -la $PAGEVIEWS 2> /dev/null | cut -d " " -f5`

# Copy the result
cp $PAGEVIEWS $DIR/pageviews

# Update README
echo "pageviews: page_title view_count" > $README

######################################################################
# GATHER pages key values                                            # 
######################################################################

# Pages
echo "Gathering pages..."
echo "pages: page_id page_title page_size is_redirect" >> $README
rm -f $DIR/pages
touch $DIR/pages
NEW_SIZE=0
UPPER_LIMIT=0;
while [ 42 ]
do
    OLD_SIZE=$NEW_SIZE
    LOWER_LIMIT=$UPPER_LIMIT
    UPPER_LIMIT=$((UPPER_LIMIT + 100000))
    echo "   from page_id $LOWER_LIMIT to $UPPER_LIMIT..."
    mysql --defaults-file=~/replica.my.cnf --quick -e \
        "SELECT page.page_id, page.page_title, revision.rev_len, page.page_is_redirect FROM page, revision WHERE page.page_namespace = 0 AND revision.rev_id = page.page_latest AND page.page_id >= $LOWER_LIMIT AND page.page_id < $UPPER_LIMIT" \
        -N -h ${DB_HOST} ${DB} >> $DIR/pages
    NEW_SIZE=`ls -la $DIR/pages 2> /dev/null | cut -d " " -f5`
    if [ x$OLD_SIZE = x$NEW_SIZE ]
    then
        break
    fi
done

# Page links
echo "Gathering page links..."
echo "pagelinks: source_page_id target_page_title" >> $README
rm -f $DIR/pagelinks
touch $DIR/pagelinks
NEW_SIZE=0
UPPER_LIMIT=0;
while [ 42 ]
do
    OLD_SIZE=$NEW_SIZE
    LOWER_LIMIT=$UPPER_LIMIT
    UPPER_LIMIT=$((UPPER_LIMIT + 10000))
    echo "   from pl_from from $LOWER_LIMIT to $UPPER_LIMIT..."
    mysql --defaults-file=~/replica.my.cnf --quick -e \
	"SELECT pl_from, pl_title FROM pagelinks WHERE pl_namespace = 0 AND pl_from_namespace = 0 AND pl_from >= $LOWER_LIMIT AND pl_from < $UPPER_LIMIT" \
	-N -h ${DB_HOST} ${DB} >> $DIR/pagelinks
    NEW_SIZE=`ls -la $DIR/pagelinks 2> /dev/null | cut -d " " -f5`
    if [ x$OLD_SIZE = x$NEW_SIZE ]
    then
        break
    fi
done

# Language links
echo "Gathering language links..."
echo "langlinks: source_page_id language_code target_page_title" >> $README
mysql --defaults-file=~/replica.my.cnf --quick -e \
    "SELECT ll_from, ll_lang, ll_title FROM langlinks, page WHERE langlinks.ll_from = page.page_id AND page.page_namespace = 0" \
    -N -h ${DB_HOST} ${DB} | sed 's/ /_/g' > $DIR/langlinks

# Redirects
echo "Gathering redirects..."
echo "redirects: source_page_id target_page_title" >> $README
mysql --defaults-file=~/replica.my.cnf --quick -e \
    "SELECT rd_from, rd_title FROM redirect WHERE rd_namespace = 0" \
    -N -h ${DB_HOST} ${DB} > $DIR/redirects

######################################################################
# GATHER WP1 ratings for WPEN                                        #
######################################################################

if [ $WIKI = 'enwiki' ]
then
    echo "Gathering WP1 ratings..."
    rm -f $DIR/ratings
    touch $DIR/ratings

    echo "ratings: page_title project quality importance" >> $README

    echo "Gathering importances..."
    IMPORTANCES=`mysql --defaults-file=~/replica.my.cnf --quick -e "SELECT DISTINCT r_importance FROM ratings WHERE r_importance IS NOT NULL" -N -h ${WP1_DB_HOST} ${WP1_DB} | tr '\n' ' ' | sed -e 's/[ ]*$//'`
    IFS=$' '
    for IMPORTANCE_RATING in $IMPORTANCES
    do
	echo "Gathering ratings with importance '$IMPORTANCE_RATING'..."
	mysql --defaults-file=~/replica.my.cnf --quick -e \
	    "SELECT r_article, r_project, r_quality, r_importance FROM ratings WHERE r_importance = \"$IMPORTANCE_RATING\"" \
	    -N -h ${WP1_DB_HOST} ${WP1_DB} >> $DIR/ratings
    done
    unset IFS

    echo "Gathering ratings with importance IS NULL..."
    mysql --defaults-file=~/replica.my.cnf --quick -e \
	"SELECT r_article, r_project, r_quality, r_importance FROM ratings WHERE r_importance IS NULL" \
	-N -h ${WP1_DB_HOST} ${WP1_DB} >> $DIR/ratings
fi

######################################################################
# GATHER Vital Articles for WPEN                                     #
######################################################################

if [ $WIKI = 'enwiki' ]
then
    echo "Gathering vital articles..."

    echo "vital: level page_title" >> $README
    $SCRIPT_DIR/build_en_vital_articles_list.sh > $DIR/vital
fi

######################################################################
# MERGE lists                                                        #
######################################################################

echo "Merging lists..."
echo "all: page_title page_id page_size pagelinks_count langlinks_count pageviews_count [rating1] [rating2] ..." >> $README
$PERL $SCRIPT_DIR/merge_lists.pl $DIR > $DIR/all

######################################################################
# COMPUTE scores                                                    #
######################################################################

echo "Computing scores..."
echo "scores: page_title score ..." >> $README
$PERL $SCRIPT_DIR/build_scores.pl $DIR/all | sort -t$'\t' -k2 -n -r > $DIR/scores

######################################################################
# Split scores by wikiproject for WPEN                               #
######################################################################

if [ $WIKI = 'enwiki' ]
then
    echo "Creating wikiprojet score..."
    ulimit -n 3000
    $PERL $SCRIPT_DIR/build_projects_lists.pl $DIR
fi

######################################################################
# COMPRESS all files                                                 #
######################################################################

echo "Compressing all files..."
cat $DIR/pages     | lzma -9 > $DIR/pages.lzma
cat $DIR/pageviews | lzma -9 > $DIR/pageviews.lzma
cat $DIR/pagelinks | lzma -9 > $DIR/pagelinks.lzma
cat $DIR/langlinks | lzma -9 > $DIR/langlinks.lzma
cat $DIR/redirects | lzma -9 > $DIR/redirects.lzma
cat $DIR/scores    | lzma -9 > $DIR/scores.lzma
cat $DIR/all       | lzma -9 > $DIR/all.lzma
if [ -f $DIR/ratings ] ; then cat $DIR/ratings | lzma -9 > $DIR/ratings.lzma; fi
if [ -f $DIR/vital ] ; then cat $DIR/vital | lzma -9 > $DIR/vital.lzma; fi
rm -f $DIR/vital $DIR/ratings $DIR/pages $DIR/pageviews \
    $DIR/pagelinks $DIR/langlinks $DIR/redirects $DIR/all $DIR/scores
if [ -d $DIR/projects ]
then
    cd $DIR
    7za a -tzip -mx9 -mmt6 projects.zip projects -mmt
    rm -rf projects
    cd ..
fi

######################################################################
# UPLOAD to wp1.kiwix.org                                            # 
######################################################################

echo "Upload $DIR to download.kiwix.org"
scp -r $DIR `cat remote`

######################################################################
# CLEAN DIRECTORY                                                    # 
######################################################################

if [ $? -eq 0 ]
then
    rm -rf $DIR
    rm $NAMESPACES
    rm $PAGEVIEW_FILES
    rm $NEW_PAGEVIEW_FILES
fi
