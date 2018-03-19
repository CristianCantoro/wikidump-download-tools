#!/usr/bin/env bash

sizefile=''
debug=false
language='en'
project='wiki'

eval "$(docopts -V - -h - : "$@" <<EOF
Usage: make_lists.sh [options] <sizefile>

Options:
  -d, --debug                 Enable debug mode.
  -l, --language <language>   Wikimedia project language [default: en].
  -p, --project <project>     Wikimedia project name [default: wiki].
  -h, --help                  Show this help message and exits.
  --version                   Print version and copyright information.

----
make_lists.sh 0.2.0
copyright (c) 2018 Cristian Consonni
MIT License
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
EOF
)"

# shellcheck disable=SC2128
SOURCED=false && [ "$0" = "$BASH_SOURCE" ] || SOURCED=true

if ! $SOURCED; then
  set -euo pipefail
  IFS=$'\n\t'
fi

#################### Utils
if $debug; then
  echodebug() {
    echo -en "[$(date '+%F %k:%M:%S')][debug]\\t"
    echo "$@" 1>&2
  }
  echodebug "debugging enabled."
else
  echodebug() { true; }
fi
####################

echodebug "Arguments:"
echodebug "  * sizefile: $sizefile"
echodebug "Options:"
echodebug "  * debug: $debug"
echodebug "  * language: $language"
echodebug "  * project: $project"
echodebug ''

name="$(basename "$sizefile")"
datestr="$(echo "$name"  | tr -d '.[:alpha:]')"
year=$(echo "$datestr"  | awk -F'-' '{print $1}')
month=$(echo "$datestr" | awk -F'-' '{print $2}')
day=$(echo "$datestr"   | awk -F'-' '{print $3}')


adate="${year}${month}${day}"
aproject="${language}${project}"

echodebug "adate: $adate"
echodebug "aproject: $aproject"

rm -rf "$name"
touch "$name"
awk '{print $1}' "$sizefile" | \
  parallel -j4 ./list.sh "$aproject" "$adate" {} >> "$name"

#sort -V "$name" | sponge "$name"

exit 0
