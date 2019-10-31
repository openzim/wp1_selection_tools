#!/usr/bin/env bash

######################################################################
# CONFIGURATION                                                      #
######################################################################

# Stop if any problem
set -e
set -o pipefail

# Parse command line
WIKI_LANG=$1
if [ $WIKI_LANG == 'be-tarask' ]
then
    WIKI_LANG_SHORT='be_x_old'
else
    WIKI_LANG_SHORT=$(echo $WIKI_LANG | sed 's/\(^[[:alpha:]]{2,3}\).*/\1/' | sed 's/-/_/g')
fi
WIKI=${WIKI_LANG}wiki

# Wikipedia and WP1 databases
WP1_DB_HOST=tools.db.svc.eqiad.wmflabs
WP1_DB=s51114_enwp10
DB_HOST=${WIKI_LANG_SHORT}wiki.analytics.db.svc.eqiad.wmflabs
DB=${WIKI_LANG_SHORT}wiki_p
MYSQL='mysql --defaults-file=~/replica.my.cnf --ssl-mode=DISABLED --compress --execute'
$MYSQL "SELECT 42 FROM page LIMIT 1" -N -h ${DB_HOST} ${DB} > /dev/null || \
    ( echo "Unable to connect to DB host '${DB_HOST}' and DB '${DB}'" && exit 1 )

# Update $PATH
SCRIPT_PATH=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT_PATH | sed -e 's/\/$//')
export PATH=$PATH:$SCRIPT_DIR

# Setup global variables
DATA=$SCRIPT_DIR/data
TMP=$DATA/tmp
DIR=$TMP/${WIKI}_$(date +"%Y-%m")
README=$DIR/README

# Create directories
if [ ! -d $DATA ]; then mkdir $DATA &> /dev/null; fi
if [ ! -d $TMP  ]; then mkdir $TMP &> /dev/null; fi
if [ ! -d $DIR  ]; then mkdir $DIR &> /dev/null; fi

# To execute things in parallel
PARALLEL='parallel -j8'

# Perl and sort(1) have locale issues, which can be avoided by
# disabling locale handling entirely.
PERL=$(whereis perl | cut -f2 -d " ")
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

if [ "$WIKI_LANG" == '' ]
then
  usage
fi

######################################################################
# COMPUTE PAGEVIEWS                                                  #
######################################################################

# Get namespaces
NAMESPACES=$TMP/namespaces_$WIKI
curl -s "https://$WIKI_LANG.wikipedia.org/w/api.php?action=query&meta=siteinfo&siprop=namespaces&formatversion=2&format=xml" | \
    xml2 2> /dev/null | \
    grep -E "@(canonical|ns)=.+" | \
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
    grep -v pagecounts-2015 | \
    grep -v pagecounts-2016 > \
    $PAGEVIEW_FILES

# Download pageview dumps for all projects
NEW_PAGEVIEW_FILES=$TMP/new_pageview_files_$WIKI
PAGEVIEWS=$DATA/pageviews_$WIKI
cat /dev/null > $NEW_PAGEVIEW_FILES
for FILE in $(cat $PAGEVIEW_FILES)
do
    OLD_SIZE=0
    if [ -f $DATA/$FILE ]
    then
        OLD_SIZE=$(ls -la $DATA/$FILE 2> /dev/null | cut -d " " -f5)
    fi
    wget -c https://dumps.wikimedia.org/other/pagecounts-ez/merged/$FILE -O $DATA/$FILE
    NEW_SIZE=$(ls -la $DATA/$FILE 2> /dev/null | cut -d " " -f5)

    if [ x$OLD_SIZE != x$NEW_SIZE ] || [ ! -f $PAGEVIEWS ]
    then
        echo "$FILE NEW" >> $NEW_PAGEVIEW_FILES
    else
        echo "$FILE OLD" >> $NEW_PAGEVIEW_FILES
    fi
done

# Extract the content by filtering by project
PAGEVIEW_CODE=${WIKI_LANG}.z
PAGEVIEWS_TMP=$TMP/pageviews_$WIKI.tmp
PAGEVIEWS_NEW=$TMP/pageviews_$WIKI.new
if [ ! -f $PAGEVIEWS ]
then
    cat /dev/null > $PAGEVIEWS
fi

OLD_SIZE=$(ls -la $PAGEVIEWS 2> /dev/null | cut -d " " -f5)
for FILE in $(grep NEW $NEW_PAGEVIEW_FILES | cut -d " " -f1)
do
    echo "Parsing $DATA/$FILE..."
    bzcat < "$DATA/$FILE" | \
        grep "^$PAGEVIEW_CODE" | \
        cut -d " " -f2,3 | \
        grep -vE $(cat $NAMESPACES) \
        > $PAGEVIEWS_TMP
    cat $PAGEVIEWS $PAGEVIEWS_TMP | \
        sort -t " " -k1,1 -i | \
        $PERL -ne '($title, $count) = split(" ", $_); if ($title eq $last) { $last_count += $count } else { print "$last\t$last_count\n"; $last=$title; $last_count=$count;}' \
        > $PAGEVIEWS_NEW
    mv $PAGEVIEWS_NEW $PAGEVIEWS
    rm $PAGEVIEWS_TMP
    ENTRY_COUNT=$(wc $PAGEVIEWS | tr -s ' ' | cut -d " " -f2)
    echo "   '$PAGEVIEWS' has $ENTRY_COUNT entries."
done
NEW_SIZE=$(ls -la $PAGEVIEWS 2> /dev/null | cut -d " " -f5)

# Copy the result
cp $PAGEVIEWS $DIR/pageviews.tsv

# Update README
echo "pageviews.tsv: page_title view_count" > $README

######################################################################
# GATHER PAGES KEYS VALUES                                           #
######################################################################

# Pages
echo "Gathering pages..."
echo "pages.tsv: page_id page_title page_size is_redirect" >> $README
PAGES=$DIR/pages.tsv
cat /dev/null > $PAGES
OLD_SIZE=
NEW_SIZE=0
UPPER_LIMIT=0;
while [ x$OLD_SIZE != x$NEW_SIZE ]
do
    OLD_SIZE=$NEW_SIZE
    LOWER_LIMIT=$UPPER_LIMIT
    UPPER_LIMIT=$((UPPER_LIMIT + 100000))
    echo "   from page_id $LOWER_LIMIT to $UPPER_LIMIT..."
    $MYSQL \
        "SELECT page.page_id, page.page_title, revision.rev_len, page.page_is_redirect FROM page, revision WHERE page.page_namespace = 0 AND revision.rev_id = page.page_latest AND page.page_id >= $LOWER_LIMIT AND page.page_id < $UPPER_LIMIT" \
        -N -h ${DB_HOST} ${DB} >> $PAGES
    NEW_SIZE=$(ls -la $PAGES 2> /dev/null | cut -d " " -f5)
done

# Page links
echo "Gathering page links..."
echo "pagelinks.tsv: source_page_id target_page_title" >> $README
PAGELINKS=$DIR/pagelinks.tsv
cat /dev/null > $PAGELINKS
OLD_SIZE=
NEW_SIZE=0
UPPER_LIMIT=0;
while [ x$OLD_SIZE != x$NEW_SIZE ]
do
    OLD_SIZE=$NEW_SIZE
    LOWER_LIMIT=$UPPER_LIMIT
    UPPER_LIMIT=$((UPPER_LIMIT + 10000))
    echo "   from pl_from from $LOWER_LIMIT to $UPPER_LIMIT..."
    $MYSQL \
        "SELECT pl_from, pl_title FROM pagelinks WHERE pl_namespace = 0 AND pl_from_namespace = 0 AND pl_from >= $LOWER_LIMIT AND pl_from < $UPPER_LIMIT" \
        -N -h ${DB_HOST} ${DB} >> $PAGELINKS
    NEW_SIZE=$(ls -la $PAGELINKS 2> /dev/null | cut -d " " -f5)
done

# Language links
echo "Gathering language links..."
echo "langlinks.tsv: source_page_title language_code target_page_title" >> $README
LANGLINKS=$DIR/langlinks.tsv
$MYSQL \
    "SELECT page_title, ll_lang, ll_title FROM langlinks, page WHERE langlinks.ll_from = page.page_id AND page.page_namespace = 0" \
    -N -h ${DB_HOST} ${DB} | sed 's/ /_/g' > $LANGLINKS

# Redirects
echo "Gathering redirects..."
echo "redirects.tsv: source_page_id target_page_title" >> $README
REDIRECTS=$DIR/redirects.tsv
$MYSQL \
    "SELECT rd_from, rd_title FROM redirect WHERE rd_namespace = 0" \
    -N -h ${DB_HOST} ${DB} > $REDIRECTS

######################################################################
# GATHER WP1 RATINGS FOR WPEN                                        #
######################################################################

RATINGS=$DIR/ratings.tsv
if [ $WIKI == 'enwiki' ]
then
    echo "Gathering WP1 ratings..."
    cat /dev/null > $RATINGS

    echo "ratings.tsv: page_title project quality importance" >> $README

    echo "Gathering importances..."
    IMPORTANCES=$($MYSQL "SELECT DISTINCT r_importance FROM ratings WHERE r_importance IS NOT NULL" -N -h ${WP1_DB_HOST} ${WP1_DB} | tr '\n' ' ' | sed -e 's/[ ]*$//')
    IFS=$' '
    for IMPORTANCE_RATING in $IMPORTANCES
    do
        echo "Gathering ratings with importance '$IMPORTANCE_RATING'..."
        $MYSQL \
            "SELECT r_article, r_project, r_quality, r_importance FROM ratings WHERE r_importance = \"$IMPORTANCE_RATING\"" \
            -N -h ${WP1_DB_HOST} ${WP1_DB} >> $RATINGS
    done
    unset IFS

    echo "Gathering ratings with importance IS NULL..."
    $MYSQL \
        "SELECT r_article, r_project, r_quality, r_importance FROM ratings WHERE r_importance IS NULL" \
        -N -h ${WP1_DB_HOST} ${WP1_DB} >> $RATINGS
fi

######################################################################
# GATHER VITAL ARTICLES FOR WPEN                                     #
######################################################################

VITAL=$DIR/vital.tsv
if [ $WIKI == 'enwiki' ]
then
    echo "Gathering vital articles..."

    echo "vital.tsv: level page_title" >> $README
    $SCRIPT_DIR/build_en_vital_articles_list.sh > $VITAL
fi

######################################################################
# MERGE LISTS                                                        #
######################################################################

echo "Merging lists..."
echo "all.tsv: page_title page_id page_size pagelinks_count langlinks_count pageviews_count [rating1] [rating2] ..." >> $README
ALL=$DIR/all.tsv
$PERL $SCRIPT_DIR/merge_lists.pl $DIR > $ALL

######################################################################
# COMPUTE SCORES                                                     #
######################################################################

echo "Computing scores..."
SCORES=$DIR/scores.tsv
echo "scores.tsv: page_title score" >> $README
$PERL $SCRIPT_DIR/build_scores.pl $ALL | sort -t$'\t' -k2 -n -r > $SCORES

######################################################################
# COMPUTE TOP SELECTIONS                                             #
######################################################################

echo "Creating TOP selections..."
echo "tops/*tsv: page_title (one file per TOP selection)" >> $README

MAX=$(wc -l $SCORES | cut -d ' ' -f1)
LAST_TOP=0
if [ ! -d "$DIR/tops" ]
then
    mkdir "$DIR/tops" &> /dev/null
fi

for TOP in 10 50 100 500 1000 5000 10000 50000 100000 500000 1000000
do
    if [ "$MAX" -gt "$TOP" ]
    then
        head -n $TOP $SCORES | cut -f 1 > "$DIR/tops/$TOP.tsv"
        LAST_TOP=$TOP
    else
        rm -f "$DIR/tops/$LAST_TOP.tsv"
        break
    fi
done

######################################################################
# COMPUTE PROJECT SELECTIONS                                         #
######################################################################

echo "Creating wikiprojet selections..."
echo "projects/*tsv: page_title (one file per project)" >> $README
ulimit -n 3000

EN_NEEDED=$DATA/en.needed
WIKI_LANGLINKS=$TMP/$WIKI_LANG.langlinks.tsv

if [ $WIKI == 'enwiki' ]
then
    $PERL $SCRIPT_DIR/build_projects_lists.pl $DIR
    rm -rf $EN_NEEDED
    mkdir $EN_NEEDED
    cp -r $DIR/projects $EN_NEEDED
    cp $PAGES $EN_NEEDED
    cp $LANGLINKS $EN_NEEDED
else
    grep -P "\t$WIKI_LANG\t" $EN_NEEDED/langlinks.tsv > $WIKI_LANGLINKS || :
    grep -P "\t$WIKI_LANG\t" $EN_NEEDED/medicine.langlinks.tsv >> $WIKI_LANGLINKS || :
    sort -u -o $WIKI_LANGLINKS $WIKI_LANGLINKS
    rm -rf $DIR/projects
    mkdir $DIR/projects
    find $EN_NEEDED/projects/ -type f | \
        $PARALLEL "$PERL $SCRIPT_DIR/build_translated_list.pl {} $WIKI_LANG $SCORES > $DIR/projects/\$(basename {})"
fi

######################################################################
# CUSTOM selections                                                  #
######################################################################

echo "Creating custom selections..."
echo "customs/*tsv: page_title (one file per custom selection)" >> $README

if [ ! -d "$DIR/customs" ]
then
    mkdir "$DIR/customs" &> /dev/null
fi

$SCRIPT_DIR/build_custom_selections.sh $WIKI_LANG $DIR/customs
if [ $WIKI == 'enwiki' ]
then
    cp -r $DIR/customs $EN_NEEDED/customs
fi

######################################################################
# COMPRESS all files                                                 #
######################################################################

echo "Compressing all files..."
ZIP="7za a -tzip"
find $DIR -not -name README -maxdepth 1 -mindepth 1 | \
    $PARALLEL "$ZIP {}.zip {} && rm -rf {}"

######################################################################
# UPLOAD to wp1.kiwix.org                                            #
######################################################################

echo "Upload $DIR to download.kiwix.org"
scp -o StrictHostKeyChecking=no -r $DIR $(cat $SCRIPT_DIR/remote)
REMOTE_DIR=$(sed s/.*:// < $SCRIPT_DIR/remote)$(basename $DIR);
find $DIR -name "customs.tsv.zip" -o -name "tops.tsv.zip" -o -name "projects.tsv.zip" | \
    $PARALLEL "ssh -o StrictHostKeyChecking=no \$(sed s/:.*// < $SCRIPT_DIR/remote) unzip -o $REMOTE_DIR/\$(basename {}) -d $REMOTE_DIR"

######################################################################
# CLEAN DIRECTORY                                                    #
######################################################################

echo "Remove temporary data"
rm -rf $DIR
rm $NAMESPACES
rm $PAGEVIEW_FILES
rm $NEW_PAGEVIEW_FILES
rm -f $WIKI_LANGLINKS

echo "Process finished for $WIKI"
