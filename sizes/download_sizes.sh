#!/usr/bin/env bash

debug=false
dump_url=''
ext=''
filetype=''

eval "$(docopts -V - -h - : "$@" <<EOF
Usage: download_sizes.sh [options] <dump_url>
       download_sizes.sh ( -h | --help )
       download_sizes.sh --version

Arguments:
    <dump_url>                The wikidump base url
                              e.g. https://dumps.wikimedia.org/enwiki/20180301/
Options:
    -d, --debug               Enable debug mode.
    -f, --ext <ext>           Extension of the files to filter [default: .7z].
    -t, --filetype <filetype> Type of files to filter
                              [default: pages-meta-history].
    -h, --help                Show this help message and exits.
    --version                 Print version and copyright information.
----
download_sizes.sh 0.2.0
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

echodebug "dump_url: $dump_url"
echodebug "Options:"
echodebug "  * debug: $debug"
echodebug "  * ext: $ext"
echodebug "  * filetype: $filetype"

# create a temporary drectory and set an exit trap to remove it
tmpdir=$(mktemp -d -t tmp.download_sizes.XXXXXXXXXX)
function finish {
  rm -rf "$tmpdir"
}
trap finish EXIT

dump_date="$(basename "$dump_url" | \
            sed -re 's/([0-9]{4})([0-9]{2})([0-9]{2})/\1-\2-\3/g')"
dump_projectname="$(echo "$dump_url" | \
                    sed -re 's#https?://.+/(.+)/.+/?#\1#g')"

output="$dump_date.$dump_projectname.$filetype.txt"
tmp_output="$tmpdir/${output}"

if $debug; then
  set -x
  wget -O "${tmp_output}.tmp" "$dump_url"
  set +x
else
  wget -q -O "${tmp_output}.tmp" "$dump_url"
fi

sed -r 's#(</?ul>)#\n\1#g' "${tmp_output}.tmp" > "${tmp_output}.sed.tmp"

[ -f "${tmp_output}.sed.tmp" ] && \
      xidel -s --extract "//li" "${tmp_output}.sed.tmp" | \
      grep 'pages-meta-history' | \
      grep "$ext" | \
      sort -V | \
      uniq > "${output}"
