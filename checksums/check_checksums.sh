#!/usr/bin/env bash

quiet=false
debug=false
checkdir=''
sizesdir=''

eval "$(docopts -V - -h - : "$@" <<EOF
Usage: check_uploads.sh [options] <checkdir>

      <checkdir>           Directory to check
      -d, --debug          Enable debug mode (incompatible with --quiet).
      -q, --quiet          Suppress output (incompatible with --debug).
      -h, --help           Show this help message and exits.
      --version            Print version and copyright information.
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

year=$(basename $checkdir | cut -c 1-4 )
month=$(basename $checkdir | cut -c 6-8 )

if $debug; then
    echo -e "[DEBUG] checkdir: \t $checkdir"
    echo -e "[DEBUG] year: \t\t $year"
    echo -e "[DEBUG] month: \t\t $month"
fi


scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
checkdir=$(realpath "${scriptdir}/../checksums/check/${year}-${month}")
sizesdir=$(realpath "${scriptdir}/../sizes/")

if $debug; then
    echo -e "[DEBUG] scriptdir: \t $scriptdir"
    echo -e "[DEBUG] checkdir: \t $checkdir"
    echo -e "[DEBUG] sizesdir: \t $sizesdir"
fi

####
# cat md5sums/1/*/stdout | grep -c "OK$"
# grep -c ../../../sizes/${year}-${month}.txt
# grep -c gz joblog 
####
num_cat=$(find "${checkdir}/md5sums/" -type f -name 'stdout' -exec cat {} \; | \
	grep pagecounts | \
	grep -c "OK$")
num_sizes=$(grep -c 'gz' "${sizesdir}/${year}-${month}.txt")
num_joblog=$([ -f "${checkdir}/joblog" ] && \
    grep -c 'gz' "${checkdir}/joblog")

if $debug; then
    echo -e "[DEBUG] num_cat: \t $num_cat"
    echo -e "[DEBUG] num_sizes: \t $num_sizes"
    echo -e "[DEBUG] num_joblog: \t $num_joblog"
fi

if [ "$num_cat" -eq "$num_sizes" ] && \
		[ "$num_cat" -eq "$num_joblog" ]; then
    echoq "${year}-${month}: OK"
else
    (>&2 echoq "${year}-${month}: FAIL")
    exit 1
fi

exit 0
