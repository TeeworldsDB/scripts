#!/bin/bash

RESET='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'

if [ "$#" == "0" ] || [ "$1" == "--help" ] || [ "$1" == "-h" ]
then
    echo "usage: $(basename "$0") <path> [OPTION]"
    echo "option:"
    echo "  -v      verbose output"
    echo "description: checks recursivley for bad filenames"
    exit 0
fi

is_verbose=0
err=0
err_files=0
wrn=0
wrn_files=0

DIR="$1"
if [ "$2" == "-v" ] || [ "$2" == "--verbose" ]
then
    is_verbose=1
fi

if [ ! -d "$DIR" ]
then
    echo "Error: path does not exist '$DIR'"
    exit 1
fi

function err() {
    echo -e "[${RED}-${RESET}] $1"
}

function ok() {
    echo -e "[${GREEN}+${RESET}] $1"
}

function wrn() {
    echo -e "[${YELLOW}!${RESET}] $1"
}

function check_files() {
    local match=$1
    local mode=$2
    lines="$(find "$DIR" -name "$match" | wc -l)"
    if [ "$lines" != "0" ]
    then
        if [ "$is_verbose" == "1" ]
        then
            find "$DIR" -name "$match"
        else
            find "$DIR" -name "$match" | head -n 3
            if [ "$lines" -gt "3" ]
            then
                echo "..."
            fi
        fi
        if [ "$mode" == "warning" ]
        then
            wrn "Warning: found $lines invalid file names matching '$match'"
            wrn_files="$((wrn_files + lines))"
            wrn="$((wrn + 1))"
        else
            err "Error: found $lines invalid file names matching '$match'"
            err_files="$((err_files + lines))"
            err="$((err + 1))"
        fi
    fi
}

for ((i=0;i<10;i++))
do
    check_files "*($i).png"
done
check_files "* Kopie.*"
check_files "*invalid encoding*"
check_files "* *" "warning"

dupe_case="$(find . | tr '[:upper:]' '[:lower:]' | sort | uniq -d | wc -l)"
if [ "$dupe_case" -ne "0" ]
then
    err "found $dupe_case duplicated filenames when ignoring case:"
    err_files="$((err_files + dupe_case))"
    err="$((err + 1))"
    if [ "$is_verbose" == "1" ]
    then
        find . | tr '[:upper:]' '[:lower:]' | sort | uniq -d
    else
        find . | tr '[:upper:]' '[:lower:]' | sort | uniq -d | head -n 3
        if [ "$dupe_case" -gt "3" ]
        then
            echo "..."
        fi
    fi
fi

if [ "$wrn" != "0" ]
then
    wrn "$wrn_files wrong files names ($wrn warnings)"
fi
if [ "$err" != "0" ]
then
    err "$err_files wrong files names ($err errors)"
    exit 1
fi

ok "all file names valid"
exit 0

