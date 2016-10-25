#!/usr/bin/env bash

sizefile=''

eval "$(docopts -V - -h - : "$@" <<EOF
Usage: make_lists.sh [options] <sizefile>

    -d, --debug                 Enable debug mode.
    -h, --help                  Show this help message and exits.
    --version                   Print version and copyright information.
----
make_lists.sh 0.1.0
copyright (c) 2016 Cristian Consonni
MIT License
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
EOF
)"

set -euo pipefail
IFS=$'\n\t'

name=$(basename "$sizefile")
year=$(echo "$name" | tr -d  '.tx' | awk -F'-' '{print $1}')
month=$(echo "$name" | tr -d '.tx' | awk -F'-' '{print $2}')

echo "$year-$month"

awk -F',' '{print $1}' "$sizefile" | parallel ./list.sh {} "$year" "$month" > "$name"
