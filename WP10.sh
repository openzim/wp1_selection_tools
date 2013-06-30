#!/usr/bin/env bash

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

# This used to download the dumps from download.wikimedia.org, but
# they're available on Tool Labs already so we just symlink them.

if [ ! -e "/public/datasets/public/$WIKI" ];
then
    echo "error: no dump are available for wiki '$WIKI'."
    exit
fi

mkdir -p ./$WIKI/source
mkdir -p ./$WIKI/target

LATEST=`ls -1 /public/datasets/public/$WIKI|sort|tail -n1` # Latest version

for file in pagelinks langlinks redirect categorylinks; do
	ln -fs /public/datasets/public/$WIKI/$LATEST/$WIKI-$LATEST-$file.sql.gz \
		./$WIKI/source/$WIKI-latest-$file.sql.gz
done

# End CMD = download

fi

####################################
if [ "$CMD" = "indexes" ]; then

function pipe_query_to_gzip() {
	query=$1
	file=$2
	
	echo ./$WIKI/target/$file.gz
	if [ -e ./$WIKI/target/$file.gz ]; then
		echo "...file already exists"
	else
		# --quick option prevents out-of-memory errors
		mysql --defaults-file=~/replica.my.cnf --quick -e "$query" -N -h ${WIKI}.labsdb ${WIKI}_p |
		 tr '\t' ' ' | # MySQL outputs tab-separated; file needs to be space-separated.
		 gzip > ./$WIKI/target/$file.gz
	fi
}

function build_namespace_indexes() {
	namespace=$1
	name=$2
	
	# XXX BEWARE: This query was imputed based on what the old program seemed to be trying to do.
	# It may not be correct; we'll see what happens later on.
	pipe_query_to_gzip "SELECT page_id, page_namespace, page_title, page_is_redirect FROM page WHERE page_namespace = $namespace ORDER BY page_id ASC;" ${name}_sort_by_ids.lst
}

## BUILD PAGES INDEXES
build_namespace_indexes 0 main_pages

## BUILD TALK INDEXES
build_namespace_indexes 1 talk_pages

# Categories may not be needed, so to save time they are disabled by default
## BUILD CATEGORIES INDEXES
#build_namespace_indexes 14 categories

## BUILD PAGELINKS INDEXES - replaced by the next two files
#pipe_query_to_gzip "SELECT pl_from, pl_namespace, pl_title FROM pagelinks;" pagelinks.lst.gz

## BUILD PAGELINKS COUNTS
pipe_query_to_gzip "SELECT pl_from, pl_title FROM pagelinks ORDER BY pl_from ASC;" pagelinks_main_sort_by_ids.lst

# get a list of how many times each page is linked to; only for pages that
#	exist (pl_title=page_title)
#	are linked to more than once (HAVING COUNT(*) > 1)
pipe_query_to_gzip "SELECT pl_title, COUNT(*) FROM page, pagelinks WHERE pl_title=page_title AND page_namespace = 0 GROUP BY pl_title HAVING COUNT(*) > 1 ORDER BY pl_title;" pagelinks.counts.lst

## BUILD LANGLINKS INDEXES
pipe_query_to_gzip "SELECT ll_from, ll_lang, ll_title FROM langlinks ORDER BY ll_from ASC;" langlinks_sort_by_ids.lst

## BUILD REDIRECT INDEXES
pipe_query_to_gzip "SELECT rd_from, rd_namespace, rd_title FROM redirect ORDER BY rd_from ASC;" redirects_sort_by_ids.lst

# Find redirect targets by looking in the redirect table, falling back to
# pagelinks if that fails.
pipe_query_to_gzip "SELECT page_title,
        IF ( rd_from = page_id,
            rd_title,
        /*ELSE*/IF (pl_from = page_id,
            pl_from,
        /*ELSE*/
            NULL -- Can't happen, due to WHERE clause below
        ))
    FROM page, redirect, pagelinks
    WHERE (rd_from = page_id OR pl_from = page_id)
        AND page_is_redirect = 1
        AND page_namespace = 0 /* main */
    ORDER BY page_id ASC;" redirects_targets.lst # TODO does this stuff *really* need to be sorted?

## Commented out because it's very large, but may not be needed
## BUILD CATEGORYLINKS INDEXES
#pipe_query_to_gzip "SELECT cl_from, cl_to FROM categorylinks ORDER BY cl_from ASC;" categorylinks_sort_by_ids.lst

## BUILD LANGLINKS COUNTS
pipe_query_to_gzip "SELECT page_title, COUNT(*) FROM page, langlinks WHERE ll_from=page_id AND page_namespace = 0 GROUP BY page_id ORDER BY page_title ASC;" langlinks.counts.lst

## BUILD LIST OF MAIN PAGES
pipe_query_to_gzip "SELECT page_title FROM page ORDER BY page_title ASC;" main_pages.lst

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
