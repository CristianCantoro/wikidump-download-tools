#!/usr/bin/env bash

sizefile=''
debug=false

eval "$(docopts -V - -h - : "$@" <<EOF
Usage: make_lists.sh [options] <sizefile>

Options:
  -d, --debug                 Enable debug mode.
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

#### temp file
tempfile=$(mktemp -t tmp.make_list.XXXXXXXXXX)
function finish {
  rm -rf "$tempfile"
}
trap finish EXIT

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
echodebug ''

name="$(basename "$sizefile")"
datestr="$(echo "$name"  | tr -d '.[:alpha:]')"
year=$(echo "$datestr"  | awk -F'-' '{print $1}')
month=$(echo "$datestr" | awk -F'-' '{print $2}')
day=$(echo "$datestr"   | awk -F'-' '{print $3}')


adate="${year}${month}${day}"
aproject="$(basename "$sizefile" | \
            sed -re 's/.+\.(.+)\..+\.txt/\1/g')"

echodebug "adate: $adate"
echodebug "aproject: $aproject"

touch "$tempfile"
awk '{print $1}' "$sizefile" | \
  $HOME/.linuxbrew/bin/parallel -j4 ./list.sh "$aproject" "$adate" {} >> "$tempfile"

sort -V "$tempfile" > "$name"

exit 0
