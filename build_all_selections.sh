#!/usr/bin/env bash

# Stop if any problem
set -e
set -o pipefail

# Parse command line
WIKI_LANG_OFFSET=$1

for WIKI_LANG in $(./build_biggest_wikipedia_list.sh 0 | cut -d " " -f1 )
do
    if [ x$WIKI_LANG_OFFSET == x$WIKI_LANG ]
    then
        unset WIKI_LANG_OFFSET
    fi

    if [ x$WIKI_LANG_OFFSET == x ]
    then
        RUN=1
        while [ $RUN -lt 5 ]
        do
            echo "Run $RUN for $WIKI_LANG"
            ./build_selections.sh $WIKI_LANG
            if [ $? -eq 0 ]
            then
                RUN=5
            else
                ((RUN=RUN+1))
            fi
            sleep 1
        done
     fi
done
