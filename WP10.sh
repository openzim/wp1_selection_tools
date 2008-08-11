#!/bin/sh

WIKI=$1
CMD=$2

####################################
## CONFIGURATION

# Perl and sort(1) have locale issues, which can be avoided 
# by disabling locale handling entirely. 
LANG=C
export LANG

# Used by /bin/sort to store temporary files
TMPDIR=./$WIKI/target
export TMPDIR

##### END CONFIGURATION
####################################

usage() 
{
    echo "Usage: WP1.sh <wikiname> <command>"
    echo "  <wikiname> - such as enwiki, frwiki, ..."
    echo "  <command>  can be 'download', 'indexes', or 'counts'"
    exit
}

## Check command line arguments
if [ "$WIKI" = '' ]; then
  usage;
fi

case $CMD in
  indexes)   echo "Making indexes for $WIKI"  ;;
  download)  echo "Downloading files for $WIKI" ;;
  counts)    echo "Making overall counts for $WIKI"   ;;
  *)         usage                ;;
esac

####################################
if [ "$CMD" = "download" ]; then

CURRENT_VERSION=`curl -s http://download.wikimedia.org/$WIKI/latest/$WIKI-latest-abstract.xml-rss.xml | grep "</link>" | tail -n 1 | sed -e 's/<//g' | cut -d "/" -f 5 `

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

createDirIfNecessary ./$WIKI
createDirIfNecessary ./$WIKI/source
createDirIfNecessary ./$WIKI/target
createDirIfNecessary ./$WIKI
createDirIfNecessary ./$WIKI/source
createDirIfNecessary ./$WIKI/target

if [ -e ./$WIKI/date ]
then
    LAST_VERSION=`cat ./$WIKI/date`
    if [ $LAST_VERSION != $CURRENT_VERSION ] ; 
        then
        rm ./$WIKI/date
        rm ./$WIKI/source/* >& /dev/null
    fi
fi

echo $CURRENT_VERSION > ./$WIKI/date

## GET SQL DUMPS FROM download.wikimedia.org
wget -nc --continue -O ./$WIKI/source/$WIKI-latest-page.sql.gz \
      http://download.wikimedia.org/$WIKI/latest/$WIKI-latest-page.sql.gz
wget -nc --continue -O ./$WIKI/source/$WIKI-latest-pagelinks.sql.gz  \
      http://download.wikimedia.org/$WIKI/latest/$WIKI-latest-pagelinks.sql.gz
wget -nc --continue -O ./$WIKI/source/$WIKI-latest-langlinks.sql.gz \
      http://download.wikimedia.org/$WIKI/latest/$WIKI-latest-langlinks.sql.gz
wget -nc --continue -O ./$WIKI/source/$WIKI-latest-redirect.sql.gz \
      http://download.wikimedia.org/$WIKI/latest/$WIKI-latest-redirect.sql.gz
wget -nc --continue -O ./$WIKI/source/$WIKI-latest-categorylinks.sql.gz \
      http://download.wikimedia.org/$WIKI/latest/$WIKI-latest-categorylinks.sql.gz

# End CMD = download

fi

####################################
if [ "$CMD" = "indexes" ]; then

## BUILD PAGES INDEXES
  echo ./$WIKI/target/main_pages_sort_by_ids.lst.gz
  if [ -e ./$WIKI/target/main_pages_sort_by_ids.lst.gz ]; then
    echo "...file already exists"
  else 
    cat ./$WIKI/source/$WIKI-latest-page.sql.gz | gzip -d | tail -n +38 \
     | ./bin/pages_parser \
     | egrep "^[0-9]+ 0 " \
     | sort -T$TMPDIR -n -t " " -k 1,1 \
     | gzip > ./$WIKI/target/main_pages_sort_by_ids.lst.gz
  fi

## BUILD TALK INDEXES
  echo  ./$WIKI/target/talk_pages_sort_by_ids.lst.gz
  if [ -e ./$WIKI/target/talk_pages_sort_by_ids.lst.gz ]; then 
    echo "...file already exists"
  else  
    cat ./$WIKI/source/$WIKI-latest-page.sql.gz \
     | gzip -d | tail -n +38 \
     | ./bin/pages_parser \
     | egrep "^[0-9]+ 1 " \
     | sort -T$TMPDIR -n -t " " -k 1,1 \
     | gzip > ./$WIKI/target/talk_pages_sort_by_ids.lst.gz
  fi

# Categories may not be needed, so to save time they are disabled by default
## BUILD CATEGORIES INDEXES
#  echo ./$WIKI/target/categories_sort_by_ids.lst.gz
#  if [ -e ./$WIKI/target/categories_sort_by_ids.lst.gz ]; then
#    echo "...file already exists"
#  else
#    cat ./$WIKI/source/$WIKI-latest-page.sql.gz \
#     | gzip -d \
#     | tail -n +38 \
#     | ./bin/pages_parser  \
#     | egrep "^[0-9]+ 14 " \
#     | sort -T$TMPDIR -n -t " " -k 1,1 \
#     | gzip > ./$WIKI/target/categories_sort_by_ids.lst.gz
#  fi

## BUILD PAGELINKS INDEXES - replaced by the next two files
#echo ./$WIKI/target/pagelinks.lst.gz
#if [ -e ./$WIKI/target/pagelinks.lst.gz ]; then 
#  echo "...file already exists"
#else
#  cat ./$WIKI/source/$WIKI-latest-pagelinks.sql.gz \
#   | gzip -d \
#   | tail -n +28 \
#   | ./bin/pagelinks_parser \
#   | gzip > ./$WIKI/target/pagelinks.lst.gz
#fi

## BUILD PAGELINKS COUNTS
  echo ./$WIKI/target/pagelinks_main_sort_by_ids.lst.gz
  if [ -e ./$WIKI/target/pagelinks_main_sort_by_ids.lst.gz ]; then 
    echo "...file already exists"
  else
    cat ./$WIKI/source/$WIKI-latest-pagelinks.sql.gz \
     | gzip -d \
     | tail -n +28 \
     | ./bin/pagelinks_parser2 \
     | gzip > ./$WIKI/target/pagelinks_main_sort_by_ids.lst.gz
  fi

  echo ./$WIKI/target/pagelinks.counts.lst.gz 
  if [ -e ./$WIKI/target/pagelinks.counts.lst.gz ]; then 
    echo "...file already exists"
  else
  time ( \
    ./bin/catpagelinks.pl ./$WIKI/target/main_pages_sort_by_ids.lst.gz \
                        ./$WIKI/target/pagelinks_main_sort_by_ids.lst.gz \
      | sort -T$TMPDIR -t " " \
      | uniq -c  \
      | perl -lane 'print $F[1] . " " . $F[0] if ( $F[0] > 1 );' \
      | sort -T$TMPDIR \
      | gzip > ./$WIKI/target/pagelinks.counts.lst.gz 
    )
  fi

## BUILD LANGLINKS INDEXES
  echo ./$WIKI/target/langlinks_sort_by_ids.lst.gz
  if [ -e ./$WIKI/target/langlinks_sort_by_ids.lst.gz ]; then 
    echo "...file already exists"
  else
    cat ./$WIKI/source/$WIKI-latest-langlinks.sql.gz \
     | gzip -d \
     | tail -n +28 \
     | ./bin/langlinks_parser \
     | sort -T$TMPDIR -n -t " " -k 1,1 \
     | gzip > ./$WIKI/target/langlinks_sort_by_ids.lst.gz
  fi

## BUILD REDIRECT INDEXES
  echo ./$WIKI/target/redirects_sort_by_ids.lst.gz
  if [ -e ./$WIKI/target/redirects_sort_by_ids.lst.gz ]; then 
    echo "...file already exists"
  else
    cat ./$WIKI/source/$WIKI-latest-redirect.sql.gz \
     | gzip -d \
     | tail -n +28 \
     | ./bin/redirects_parser \
     | sort -T$TMPDIR -n -t " " -k 1,1 \
     | gzip > ./$WIKI/target/redirects_sort_by_ids.lst.gz
  fi

  echo ./$WIKI/target/redirects_targets.lst.gz 
  if [ -e ./$WIKI/target/redirects_targets.lst.gz ]; then 
    echo "...file already exists"
  else
    perl bin/join_redirects.pl ./$WIKI/target/main_pages_sort_by_ids.lst.gz \
                               ./$WIKI/target/redirects_sort_by_ids.lst.gz \
                        ./$WIKI/target/pagelinks_main_sort_by_ids.lst.gz \
    | sort -T$TMPDIR \
    | gzip > ./$WIKI/target/redirects_targets.lst.gz
  fi

## Commented out because it's very large, but may not be needed
## BUILD CATEGORYLINKS INDEXES
#echo ./$WIKI/target/categorylinks_sort_by_ids.lst.gz
#if [ -e ./$WIKI/target/categorylinks_sort_by_ids.lst.gz ]; then 
#  echo "...file already exists"
#else
#cat ./$WIKI/source/$WIKI-latest-categorylinks.sql.gz  \
#  | gzip -d \
#  | tail -n +28 \
#  | ./bin/categorylinks_parser \
#  | sort -T$TMPDIR -n -t " " -k 1,1 \
#  | gzip > ./$WIKI/target/categorylinks_sort_by_ids.lst.gz
#fi

## BUILD LANGLINKS COUNTS
  echo ./$WIKI/target/langlinks.counts.lst.gz      
  if [ -e  ./$WIKI/target/langlinks.counts.lst.gz ]; then 
    echo "...file already exists"
  else
    ./bin/count_langlinks.pl  ./$WIKI/target/main_pages_sort_by_ids.lst.gz \
                              ./$WIKI/target/langlinks_sort_by_ids.lst.gz \
    | sort -T$TMPDIR -t " "\
    | gzip > ./$WIKI/target/langlinks.counts.lst.gz      
  fi

## BUILD LIST OF MAIN PAGES
  echo ./$WIKI/target/main_pages.lst.gz 
  if [ -e  ./$WIKI/target/main_pages.lst.gz ]; then 
    echo "...file already exists"
  else
    cat ./$WIKI/target/main_pages_sort_by_ids.lst.gz \
     | gzip -d \
     | perl -lane 'print $F[2]' \
     | sort -T$TMPDIR -t " " \
     | gzip > ./$WIKI/target/main_pages.lst.gz
  fi

# END if [ "$CMD" = "indexes" ];
fi  

####################################

## BUILD OVERALL COUNTS
if [ "$CMD" = "counts" ]; then 

  if [ ! -e ./$WIKI/source/hitcounts.raw.gz ]; then
   echo 
    echo "Error: You must obtain or create the file hitcounts.raw.gz"
   echo  "Place it in the directory ./$WIKI/source"
    exit
  fi

  echo ./$WIKI/target/counts.lst.gz
  if [ -e ./$WIKI/target/counts.lst.gz ]; then
    echo "...file already exists"
  else
    ./bin/merge_counts.pl ./$WIKI/target/main_pages.lst.gz \
                          ./$WIKI/target/langlinks.counts.lst.gz \
                          ./$WIKI/target/pagelinks.counts.lst.gz \
                          ./$WIKI/source/hitcounts.raw.gz \
     | ./bin/merge_redirects.pl ./$WIKI/target/redirects_targets.lst.gz \
     | sort -T$TMPDIR -t " "\
     | ./bin/merge_tally.pl \
     | gzip > ./$WIKI/target/counts.lst.gz
  fi
fi 
