#!/usr/bin/env bash

# Stop if any problem
set -e
set -o pipefail

# Get MIN_ARTICLE_COUNT
int_re='^[0-9]+$'
if [[ "$1" =~ $int_re ]]
then
    MIN_ARTICLE_COUNT=$1
    >&2 echo "Get only Wikipedias with more than $MIN_ARTICLE_COUNT articles"
else
    >&2 echo "Give the minimal article of article in the Wikipedias"
    exit 1
fi

# Request wikistats
curl -s "https://wikistats.wmcloud.org/api.php?action=dump&table=wikipedias&format=csv" | cut -d',' -f3,4 | tr ',' ' ' | sed  '1d' | sort -k 2,2 -n -r | perl -ne "(\$lang, \$count) = split(' ', \$_); if (\$count > $MIN_ARTICLE_COUNT) { print \"\$lang \$count\n\" }"
