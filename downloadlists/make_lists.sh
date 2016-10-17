#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

name=$(basename "$1")
year=$(echo "$name" | tr -d  '.tx' | awk -F'-' '{print $1}')
month=$(echo "$name" | tr -d '.tx' | awk -F'-' '{print $2}')

echo "$year-$month"

awk -F',' '{print $1}' "$1" | parallel ./list.sh {} "$year" "$month" > "$name"
