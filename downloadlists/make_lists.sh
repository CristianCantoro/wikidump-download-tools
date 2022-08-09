#!/usr/bin/env bash

sizefile=''
debug=false

eval "$(docopts -V - -h - : "$@" <<EOF
Usage: make_lists.sh [options] <sizefile>

Options:
  -d, --debug                         Enable debug mode.
  -h, --help                          Show this help message and exits.
  -p, --parallel-bin PARALLEL_BIN     Parallel executable [default: /usr/local/bin/parallel].
  --version                           Print version and copyright information.

----
make_lists.sh 0.3.0
copyright (c) 2021 Cristian Consonni
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

# script base directory
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

#### temp file
tempfile=$(mktemp -t tmp.make_list.XXXXXXXXXX)
function finish {
  rm -rf "$tempfile"
}
trap finish EXIT

#################### Utils
if $debug; then
  echodebug() {
    (>&2 echo "[$(date '+%F %H:%M:%S')][debug] $@" )
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

outname="downloadlists.$(basename "$sizefile")"
output="${SCRIPTDIR}/${outname}"

datestr="$(echo "$outname"  | tr -d '.[:alpha:]')"
year=$(echo "$datestr"  | awk -F'-' '{print $1}')
month=$(echo "$datestr" | awk -F'-' '{print $2}')
day=$(echo "$datestr"   | awk -F'-' '{print $3}')


adate="${year}${month}${day}"
aproject="$(basename "$sizefile" | \
            sed -re 's/.+\.(.+)\..+\.txt/\1/g')"

echodebug "adate: $adate"
echodebug "aproject: $aproject"
echodebug "parallel_bin: ${parallel_bin}"

touch "$tempfile"
awk '{print $1}' "$sizefile" | \
  ${parallel_bin} -j4 "${SCRIPTDIR}"/list.sh "$aproject" "$adate" {} >> "$tempfile"

sort -V "$tempfile" > "$output"

echo "-> ${outname}"

exit 0
