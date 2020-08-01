#!/bin/bash

function usage() {
    echo "usage: $(basename "$0") <metadata file> <input dir> <output dir>"
}

if [ "$#" == "0" ] || [ "$1" == "--help" ] || [ "$1" == "-h" ]
then
    usage
    echo "description:"
    echo "  copies every file from the input dir to output dir"
    echo "  if the sha1sum of the file is not found in the metadata file"
    echo ""
    echo "  So this can act as a pre filter. Where metadata file is the readme.txt"
    echo "  input dir is a graphics pack and output dir will be created"
    echo "  then the output dir can be manually scimmed and the obvious dupes"
    echo "  are already filtered."
    echo "example:"
    echo "  $(basename "$0") mapres/readme.txt ~/Downloads/AwesomeMapresPack /tmp/mapres"
    exit 0
elif [ "$#" != "3" ]
then
    usage
    exit 1
fi

META_FILE="$1"
IN_DIR="$2"
OUT_DIR="$3"

if [ ! -f "$META_FILE" ]
then
    echo "Error: metedata file not found '$META_FILE'"
    exit 1
fi

if [ ! -d "$IN_DIR" ]
then
    echo "Error: input dir not found '$IN_DIR'"
    exit 1
fi

if [ "$OUT_DIR" == "" ]
then
    echo "Error: invalid output dir '$OUT_DIR'"
    exit 1
fi

if [ -d "$OUT_DIR" ]
then
    echo "Error: output dir should not exist yet '$OUT_DIR'"
    exit 1
fi

mkdir -p "$OUT_DIR" || exit 1

function is_dupe() {
    local sha
    sha="$1"
    for dupe_sha in $(grep sha1 "$META_FILE" | \
        awk '{ print $2}' | \
        sort | uniq)
    do
        if [ "$sha" == "$dupe_sha" ]
        then
            echo "dupe $sha"
            return 0
        fi
    done
    return 1
}

for img in "$IN_DIR"/*.png
do
    [[ -e "$img" ]] || break

    sha="$(sha1sum "$img" | cut -d ' ' -f1)"
    if ! is_dupe "$sha"
    then
        cp "$img" "$OUT_DIR" || exit 1
    fi
done

