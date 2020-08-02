#!/bin/bash

RESET='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'

good_res=0
warning_res=0
error_res=0

error_files=""

if [ "$#" != "1" ] || [ "$1" == "--help" ] || [ "$1" == "-h" ]
then
    echo "usage: $(basename "$0") <config file>"
    echo "description:"
    echo "  checks each directory in the config file"
    echo "  for correct file type (PNG) and resolution (1024x1024)"
    echo "sample config:"
    echo "  # path/to/images    type"
    echo "  foo/tiles           tiles"
    echo "  foo/quads           quads"
    exit 0
fi

CFG_FILE="$1"
if [ ! -f "$CFG_FILE" ]
then
    echo "Error: config file not found '$CFG_FILE'"
    exit 1
fi

function check_dir() {
    local dir=$1
    local arg=$2
    local w=0, e=0
    echo -n "[*] checking directory '$dir' ($arg) ... "
    if [ ! -d "$dir" ]
    then
        echo ""
        echo "Error: directory not found '$dir'"
        echo "  is your current path and config correct?"
        exit 1
    fi
    for img in "$dir"/*.png
    do
        [[ -e "$img" ]] || break

        meta="$(file -b "$img")"
        meta_type="${meta%% *}"
        if [ ! "$meta_type" == "PNG" ]
        then
            echo ""
            echo "Error: invalid file type expected 'PNG' got '$meta_type'"
            echo "  $img"
            exit 1
        fi
        if [ "$arg" == "quads" ]
        then
            continue
        fi
        meta_resolution="$(echo "$meta" | cut -d',' -f2 | cut -c 2-)"
        if [ "$meta_resolution" == "1024 x 1024" ]
        then
            good_res="$((good_res + 1))"
        elif [ "$meta_resolution" == "1024 x 1024" ]
        then
            warning_res="$((warning_res + 1))"
            w=1
        else
            error_res="$((error_res + 1))"
            error_files+="${RED}$meta_resolution${RESET} $img\\n"
            e=1
        fi
    done
    if [ "$e" == "1" ]
    then
        echo -e "${RED}ERROR"
    elif [ "$w" == "1" ]
    then
        echo -e "${YELLOW}WARNING"
    else
        echo -e "${GREEN}OK"
    fi
    echo -en "${RESET}"
}

function show_stats() {
    echo -e "$error_files"
    echo ""
    echo "1024 x 1024: $good_res"
    echo "512 x 512: $warning_res"
    echo "other: $error_res"
    if [ "$error_res" -gt "0" ]
    then
        exit 1
    fi
}

while IFS= read -r line
do
    if [ "${line:0:1}" == "#" ]
    then
        continue
    fi
    if [ "$(echo "$line" | xargs)" == "" ]
    then
        continue
    fi
    dir="$(echo "$line" | awk '{print $1}')"
    arg="$(echo "$line" | awk '{print $2}')"
    check_dir "$dir" "$arg"
done < "$CFG_FILE"

show_stats

