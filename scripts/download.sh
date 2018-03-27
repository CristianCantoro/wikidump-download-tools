#!/usr/bin/env bash

continue=''
debug=false
quiet=false
kill=''
downloadlist=''
language='en'
project='wiki'

eval "$(docopts -V - -h - : "$@" <<EOF
Usage: download.sh [options] <downloadlist>
       download.sh --kill
       download.sh ( -h | --help )
       download.sh --version

Arguments:
  <dowloadlist>        Date to download (e.g. 2018-03-01)

Options:
  -c, --continue              Continue the previous download.
  -d, --debug                 Enable debug mode (incompatible with --quiet).
  -k, --kill                  Kill connection.
  -l, --language <language>   Wikimedia project language [default: en].
  -p, --project <project>     Wikimedia project name [default: wiki].
  -q, --quiet                 Suppress output (incompatible with --debug).
  -h, --help                  Show this help message and exits.
  --version                   Print version and copyright information.
----
download.sh 0.2.0
copyright (c) 2018 Cristian Consonni
MIT License
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
EOF
)"

# bash strict mode
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

workdir='scripts'

name="$(basename "$downloadlist")"
datestr="$(echo "$name"  | tr -d '.[:alpha:]')"
year=$(echo "$datestr"  | awk -F'-' '{print $1}')
month=$(echo "$datestr" | awk -F'-' '{print $2}')
day=$(echo "$datestr"   | awk -F'-' '{print $3}')

aproject="$(basename "$downloadlist" | \
            sed -re 's/.+\.(.+)\..+\.txt/\1/g')"

echodebug -e "year: \\t\\t $year"
echodebug -e "month: \\t\\t $month"
echodebug -e "day: \\t\\t\\t $day"

echodebug "continue: $continue"
echodebug "debug: $debug"
echodebug "kill: $kill"
echodebug "aproject: $aproject"

# --debug implies not --quiet
if $debug; then quiet=false; fi

if $kill; then
    if [ -f "${workdir}/download.pid" ]; then
        kill -s TERM "$(cat ${workdir}/download.pid)"
        rm "${workdir}/download.pid"
    fi
fi

continue_opt=''
if $continue; then continue_opt='--continue'; fi

hour=$(date "+%H")
timeout_time=""
max_overall_download_limit=""

if [ "$hour" -gt "7" ] && [ "$hour" -lt "18" ] ; then
    timeout_time="8h"
    max_overall_download_limit="25MB"
else
    timeout_time="10h"
    max_overall_download_limit="125MB"
fi

if $debug; then set +x; fi

download_dir="data/${language}${project}/${year}${month}${day}/"
mkdir -p "$download_dir"

set +e
if $quiet; then
  /usr/bin/unbuffer /usr/bin/timeout -s TERM "$timeout_time" \
      aria2c \
          -j 12 \
          --max-overall-download-limit="$max_overall_download_limit" \
          --max-overall-upload-limit=5M \
          --file-allocation=none \
          -d "$download_dir" \
          -i "$downloadlist" \
          $continue_opt \
            > "download.${aproject}.${year}${month}${day}.log"

else
  /usr/bin/unbuffer /usr/bin/timeout -s TERM "$timeout_time" \
      aria2c \
          -j 12 \
          --max-overall-download-limit="$max_overall_download_limit" \
          --max-overall-upload-limit=50k \
          --file-allocation=none \
          -d "$download_dir" \
          -i "$downloadlist" \
          $continue_opt \
            | tee "download.${aproject}.${year}${month}${day}.log"
fi

exit 0

