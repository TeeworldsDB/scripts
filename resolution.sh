#!/bin/bash

RESET='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'

is_skins=0
skins_good_res=0
skins_warning_res=0
skins_error_res=0

is_mapres=0
good_res=0
okay_res=0
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
    echo "  foo/skins 		skins"
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
	local w=0 e=0
	local width=0 height=0
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
		meta_resolution="$(echo "$meta" | cut -d',' -f2 | cut -c 2-)"
		if [ "$arg" == "quads" ]
		then
			is_mapres=1
			continue
		elif [ "$arg" == "skins" ]
		then
			is_skins=1
			if [ "$meta_resolution" == "256 x 128" ]
			then
				skins_good_res="$((skins_good_res + 1))"
			else
				width="$(echo "$meta_resolution" | awk '{print $1}')"
				height="$(echo "$meta_resolution" | awk '{print $3}')"
				if [ "$width" -lt "256" ] || [ "$((width / 2 ))" != "$height" ]
				then
					skins_error_res="$((skins_error_res + 1))"
					error_files+="${RED}$meta_resolution${RESET} $img\\n"
					e=1
				else
					skins_warning_res="$((skins_warning_res + 1))"
				fi
			fi
		elif [ "$arg" == "tiles" ]
		then
			is_mapres=1
			if [ "$meta_resolution" == "1024 x 1024" ]
			then
				good_res="$((good_res + 1))"
			elif [ "$meta_resolution" == "512 x 512" ]
			then
				okay_res="$((okay_res + 1))"
				w=1
			else
				width="$(echo "$meta_resolution" | awk '{print $1}')"
				height="$(echo "$meta_resolution" | awk '{print $3}')"
				if [ "$width" -lt "512" ] || [ "$width" != "$height" ]
				then
					error_res="$((error_res + 1))"
					error_files+="${RED}$meta_resolution${RESET} $img\\n"
					e=1
				else
					warning_res="$((warning_res + 1))"
				fi
			fi
		else
			echo "Error: invalid type '$arg'"
			exit 1
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
	if [ "$is_mapres" == "1" ]
	then
		echo "[ mapres ]"
		echo "1024 x 1024: $good_res"
		echo "512 x 512: $okay_res"
		echo "warning: $warning_res"
		echo "error: $error_res"
	fi
	if [ "$is_skins" == "1" ]
	then
		echo "[ skins ]"
		echo "256 x 128: $skins_good_res"
		echo "warning: $skins_warning_res"
		echo "error: $skins_error_res"
	fi
	if [ "$error_res" -gt "0" ] || [ "$skins_error_res" -gt "0" ]
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

