#!/usr/bin/env bash

for LANG in `./build_biggest_wikipedia_list.sh | cut -d " " -f1`
do
    ./build_selections.sh $LANG
done
