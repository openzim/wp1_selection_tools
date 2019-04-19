#!/usr/bin/env bash

# Stop if any problem
set -e
set -o pipefail

# Parse command line
WIKI_LANG=$1
WIKI_LANG_SHORT=`echo $WIKI_LANG | sed 's/\(^..\).*/\1/'`
WIKI=${WIKI_LANG}wiki

# Update PATH
SCRIPT_PATH=`readlink -f $0`
SCRIPT_DIR=`dirname $SCRIPT_PATH | sed -e 's/.$//'`
export PATH=$PATH:$SCRIPT_DIR

# Setup global variables
TMP=$SCRIPT_DIR/tmp
DIR=$2

# Perl and sort(1) have locale issues, which can be avoided by
# disabling locale handling entirely.
PERL=`whereis perl | cut -f2 -d " "`
LANG=C
export LANG

######################################################################
# CHECK COMMAND LINE ARGUMENTS                                       # 
######################################################################

usage() {
    echo "Usage: $0 <lang> <dir>"
    echo "  <lang> - such as en, fr, ..."
    echo "  <dir>  - enwiki_2018-01"
    exit
}

if [ "$WIKI_LANG" = '' -o "$DIR" = '' ]
then
  usage;
fi

######################################################################
# CREATE SELECTIONS                                                  # 
######################################################################
