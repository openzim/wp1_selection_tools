#!/usr/bin/env bash

######################################################################
# CONFIGURATION                                                      # 
######################################################################
 
# Perl and sort(1) have locale issues, which can be avoided by
# disabling locale handling entirely.
PERL=`whereis perl | cut -f2 -d " "`
LANG=C
export LANGPERL=`whereis perl | cut -f2 -d " "`
LANG=C
export LANG

######################################################################
# BUILD list                                                         # 
######################################################################

curl -s "http://wikistats.wmflabs.org/api.php?action=dump&table=wikipedias&format=csv" | cut -d',' -f3,4 | tr ',' ' ' | sed  '1d' | sort -k 2,2 -n -r | perl -ne '($lang, $count) = split(" ", $_); if ($count > 500000) { print "$lang $count\n" }'

