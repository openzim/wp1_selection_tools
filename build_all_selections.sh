#!/usr/bin/env bash

# Stop if any problem
set -e
set -o pipefail

for LANG in `./build_biggest_wikipedia_list.sh 0 | cut -d " " -f1`
do
    ./build_selections.sh $LANG || exit $?
done
