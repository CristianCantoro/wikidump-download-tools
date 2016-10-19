#!/usr/bin/env bash

quiet=false
debug=false
logfile=''

eval "$(docopts -V - -h - : "$@" <<EOF
Usage: check_uploads.sh [options] <logfile>

      <year>        Year to check
      <month>       Month to check
      -d, --debug   Enable debug mode (incompatible with --quiet).
      -q, --quiet   Suppress output (incompatible with --debug).
      -h, --help    Show this help message and exits.
      --version     Print version and copyright information.
----
check_uploads.sh 0.1.0
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

if $quiet && $debug; then
  (>&2 echo "Error: options --debug (-d) and --quiet (-q) are incompatible.")
  (>&2 echo "See help (-h, --help) for more info")
  exit 1
fi

echoq() { echo "$@"; }
if $quiet; then
  echoq() { true; }
fi

logfilename=$(basename "${logfile}")
year=$(echo "$logfilename" | awk -F'.' '{print $2}' | cut -c 1-4 )
month=$(echo "$logfilename" | awk -F'.' '{print $2}' | cut -c 5-6 )

if $debug; then
    echo -e "[DEBUG] logfile: \t $logfile"
    echo -e "[DEBUG] logfilename: \t $logfilename"
    echo -e "[DEBUG] year: \t\t $year"
    echo -e "[DEBUG] month: \t\t $month"
fi

scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
checkdir=$(realpath "${scriptdir}/../checksums/check/${year}-${month}")

if $debug; then
    echo -e "[DEBUG] scriptdir: \t $scriptdir"
    echo -e "[DEBUG] checkdir: \t $checkdir"
fi

num_check="-1"
if [ -f "${checkdir}/joblog" ]; then
  num_check=$(grep -c gz "${checkdir}/joblog")
else
  (>&2 echoq "Error: ${checkdir}/joblog not found")
fi

num_script="0"
if [ -f "${scriptdir}/${logfilename}" ]; then
  num_script=$( sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" "${scriptdir}/${logfilename}" | \
      grep -A5 "name.*pagecounts-.*.gz" | \
      grep -c "command OK$")
else
  (>&2 echoq "Error: ${scriptdir}/${logfilename} not found")
fi

if $debug; then
    echo -e "[DEBUG] num_script: \t $num_script"
    echo -e "[DEBUG] num_check: \t $num_check"
fi

if [ "$num_script" -eq "$num_check" ]; then
    echoq "${year}-${month}: OK"
else
    (>&2 echoq "${year}-${month}: FAIL")
    exit 1
fi

exit 0
