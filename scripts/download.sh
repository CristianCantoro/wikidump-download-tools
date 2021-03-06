#!/usr/bin/env bash

continue=''
debug=false
quiet=false
kill=''
downloadlist=''
project='wiki'

eval "$(docopts -V - -h - : "$@" <<EOF
Usage: download.sh [options] <downloadlist>
       download.sh --kill
       download.sh ( -h | --help )
       download.sh --version

Arguments:
  <dowloadlist>               Date to download (e.g. 2018-03-01)

Options:
  -c, --continue              Continue the previous download.
  -d, --debug                 Enable debug mode (incompatible with --quiet).
  -k, --kill                  Kill connection.
  -q, --quiet                 Suppress output (incompatible with --debug).
  -h, --help                  Show this help message and exits.
  --version                   Print version and copyright information.
----
download.sh 0.3.0
copyright (c) 2021 Cristian Consonni
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

rundir="/var/run/user/${UID}/wikidump-download"
mkdir -pv "$rundir"
function finish {
  rm -rf "$rundir"
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

name="$(basename "$downloadlist")"
datestr="$(echo "$name"  | tr -d '.[:alpha:]')"
year=$(echo "$datestr"  | awk -F'-' '{print $1}')
month=$(echo "$datestr" | awk -F'-' '{print $2}')
day=$(echo "$datestr"   | awk -F'-' '{print $3}')

aproject="$(basename "$downloadlist" | \
            sed -re 's/.+\.(.+)\..+\.txt/\1/g')"

echodebug "year: $year"
echodebug "month: $month"
echodebug "day: $day"
echodebug "continue: $continue"
echodebug "debug: $debug"
echodebug "kill: $kill"
echodebug "aproject: $aproject"

# --debug implies not --quiet
if $debug; then quiet=false; fi

if $kill; then
    if [ -f "${rundir}/download.pid" ]; then
      echodebug "Killing process $(cat ${rundir}/download.pid)"
      kill -s TERM "$(cat ${rundir}/download.pid)"
    else
      echodebug "No process found, nothing to do."
    fi
    exit 0
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

download_dir="data/${aproject}/${year}${month}${day}/"
mkdir -p "$download_dir"

logfile="download"
logfile+=".${aproject}-${year}${month}${day}" \
logfile+=".$(date "+%Y-%d-%mT%H:%M:%S").log"

echodebug "logfile: $logfile"

set +e

function download_command {
  (
    stdbuf -i0 -o0 -e0 /usr/bin/timeout -s TERM "$timeout_time" \
      aria2c \
          -j 12 \
          --max-overall-download-limit="$max_overall_download_limit" \
          --max-overall-upload-limit=500k \
          --file-allocation=none \
          -d "$download_dir" \
          -i "$downloadlist" \
          $continue_opt \
          &

    # How does a Linux/Unix Bash script know its own PID?
    #   https://stackoverflow.com/a/2493659/2377454
    # How to get PID from forked child process in shell script
    #   https://stackoverflow.com/a/17356607/2377454
    echo "$!" > "${rundir}/download.pid"    
  )
}

if $quiet; then
  download_command 2>&1 > "${logfile}"
else
  download_command 2>&1 | tee "${logfile}"
fi

exit 0
