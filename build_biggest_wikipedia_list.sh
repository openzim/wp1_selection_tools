#!/usr/bin/env bash

curl -s "http://wikistats.wmflabs.org/api.php?action=dump&table=wikipedias&format=csv" | cut -d',' -f3,4 | tr ',' ' ' | sed  '1d' | sort -k 2,2 -n -r | perl -ne '($lang, $count) = split(" ", $_); if ($count > 500000) { print "$lang $count\n" }'
