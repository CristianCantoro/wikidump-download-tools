#!/usr/bin/env bash

continue=''
debug=false
quiet=false
kill=''
year=''
month=''

eval "$(docopts -V - -h - : "$@" <<EOF
Usage: download.sh [options] <year> <month>
       download.sh --kill

      <year>               year to download (2007-2016)
      <month>              month to download (01-12)
      -c, --continue       Continue the previous download.
      -d, --debug          Enable debug mode (incompatible with --quiet).
      -k, --kill           Kill connection.
      -q, --quiet          Suppress output (incompatible with --debug).
      -h, --help           Show this help message and exits.
      --version            Print version and copyright information.
----
download.sh 0.1.0
copyright (c) 2016 Cristian Consonni
MIT License
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
EOF
)"

# bash strict mode
# See:
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

workdir='scripts'

if $debug; then
    echo -e "year: \t\t $year"
    echo -e "month: \t\t $month"
 
    echo -e "continue: \t $continue"
    echo -e "debug: \t\t $debug"
    echo -e "kill: \t\t $kill"
fi


# --debug implies --verbose
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

if [ "$hour" -gt "7" -a "$hour" -lt "18" ] ; then
    timeout_time="8h"
    max_overall_download_limit="6MB"
else
    timeout_time="10h"
    max_overall_download_limit="50MB"
fi

if $debug; then set +x; fi

set +e
if $quiet; then
  unbuffer timeout -s TERM "$timeout_time" \
      aria2c \
          -j 12 \
          --max-overall-download-limit="$max_overall_download_limit" \
          --max-overall-upload-limit=50k \
          --file-allocation=none \
          -d "data/${year}-${month}/" \
          -i "downloadlists/${year}-${month}.txt" \
          $continue_opt \
            > "download.${year}${month}.txt"

else
  unbuffer timeout -s TERM "$timeout_time" \
      aria2c \
          -j 12 \
          --max-overall-download-limit="$max_overall_download_limit" \
          --max-overall-upload-limit=50k \
          --file-allocation=none \
          -d "data/${year}-${month}/" \
          -i "downloadlists/${year}-${month}.txt" \
          $continue_opt \
            | tee "download.${year}${month}.txt"
fi
