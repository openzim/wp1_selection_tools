#!/usr/bin/env bash

# Stop if any problem
set -e
set -o pipefail

LIST_CATEGORY_SCRIPT_PATH=mediawiki/scripts/listCategoryEntries.pl

for LEVEL in $(echo "1 2 3 4" | tr ' ' '\n')
do
    $LIST_CATEGORY_SCRIPT_PATH --host=en.wikipedia.org --path=w --explorationDepth=5 --namespace=1 --category=Wikipedia_level-${LEVEL}_vital_articles | sed "s/Talk:/$LEVEL\t/"
done
