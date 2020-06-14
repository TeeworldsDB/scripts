#!/bin/bash

META_FILE="${1:-readme.txt}"
dupes=0

for dupe_sha in $(grep sha1 "$META_FILE" | \
    awk '{ print $2}' | \
    sort | uniq -D | uniq)
do
    grep -B 4 "$dupe_sha" "$META_FILE"
    dupes="$((dupes+1))"
    echo "+-------------------------------------------------+"
done

echo "total sha1sum duplicates: $dupes"

