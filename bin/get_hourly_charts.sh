#!/bin/sh
DIR=$1
cd $DIR
rm index.html
wget -nc -r -l 2 -nd  http://dammit.lt/wikistats/
