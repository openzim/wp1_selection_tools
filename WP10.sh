#!/usr/bin/env bash

######################################################################
# CONFIGURATION                                                      # 
######################################################################

# Parse command line
WIKI=$1

# Update PATH
SCRIPT_PATH=$0
SCRIPT_DIR=`dirname $SCRIPT_PATH`
export PATH=$PATH:$SCRIPT_DIR

# Setup global variables
DIR=$SCRIPT_DIR/${WIKI}_`date +"%Y-%m-%d"`

# Perl and sort(1) have locale issues, which can be avoided by
# disabling locale handling entirely.
LANG=C
export LANG

######################################################################
# CHECK COMMAND LINE ARGUMENTS                                       # 
######################################################################

usage() {
    echo "Usage: WP1.sh <wikiname> <command>"
    echo "  <wikiname> - such as enwiki, frwiki, ..."
    echo "  <command>  can be 'all', 'indexes', 'counts' or 'upload'"
    exit
}

if [ "$WIKI" = '' ]
then
  usage;
fi

######################################################################
# COMPUTE INDEXES                                                    # 
######################################################################
    
function pipe_query_to_xz() {
    
    # Get function arguments
    QUERY=$1
    NAME=$2
    HEADER=$3

    # Variables
    FILE=$DIR/$NAME.xz
    
    # Update README
    echo "$NAME: $HEADER" >> "$DIR/README"
    
    # Execute SQL request and compress result
    if [ -e $FILE ]
    then
	echo "...$FILE exists already"
    else
	echo "Piping SQL following query to $FILE"
	echo "    $QUERY"
	echo "    ..."
	mysql --defaults-file=~/replica.my.cnf --quick -e "$QUERY" -N -h ${WIKI}.labsdb ${WIKI}_p |
	xz -9 > $FILE
    fi
}

echo "Gather data"

# Create directory
mkdir $DIR

# Pages
pipe_query_to_xz \
    "SELECT page_id, page_title, page_is_redirect FROM page WHERE page_namespace = 0" \
    pages "page_id page_title is_redirect"

# Page links
pipe_query_to_xz \
    "SELECT pl_from, pl_title FROM pagelinks WHERE pl_namespace = 0 AND pl_from_namespace = 0" \
    pagelinks "source_page_id target_page_title"

# Language links
pipe_query_to_xz \
    "SELECT ll_from, ll_lang, ll_title FROM langlinks, page WHERE langlinks.ll_from = page.page_id AND page.page_namespace = 0" \
    langlinks "source_page_id language_code target_page_title"

# Redirects
pipe_query_to_xz \
    "SELECT rd_from, rd_title FROM redirect WHERE rd_namespace = 0" \
    redirects "source_page_id target_page_title"

######################################################################
# UPLOAD to wp1.kiwix.org                                            # 
######################################################################

echo "Upload $DIR to wp1.kiwix.org"
DIRNAME=`basename $DIR`
FTP_USER=`cat ftp.credentials | cut -d, -f1`
FTP_PASSWORD=`cat ftp.credentials | cut -d, -f2`
ftp -vinp <<EOF
open wp1.kiwix.org
user $FTP_USER $FTP_PASSWORD
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

echo "Delete directory $DIR"
rm -rf $DIR
