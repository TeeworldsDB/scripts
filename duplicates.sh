#!/bin/bash

META_FILE="${1:-readme.txt}"
dupes=0

if [ ! -f "$META_FILE" ]
then
    echo "Error: meta file not found '$META_FILE'"
    exit 1
fi

for dupe_sha in $(grep sha1 "$META_FILE" | \
    awk '{ print $2}' | \
    sort | uniq -D | uniq)
do
    grep -B 4 "$dupe_sha" "$META_FILE"
    dupes="$((dupes+1))"
    echo "+-------------------------------------------------+"
done

if [ "$dupes" == "0" ]
then
    echo "no sha1sum duplicates found"
    echo ""
    echo "it is a good idea to now test a bit more manually using imgdupe:"
    tput bold
    echo "  pip install imgdupes"
    echo "  imgdupes -r . dhash 0"
    tput sgr0
    exit 0
else
    echo "total sha1sum duplicates: $dupes"
    exit 1
fi

