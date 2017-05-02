#!/usr/bin/env bash
debug=false
date_start=''
date_end=''
eval "$(docopts -V - -h - : "$@" <<EOF
Usage: download_sizes.sh [options]

    -d, --debug                 Enable debug mode.
    --date-start YEAR_START     Starting year [default: 2007-12].
    --date-end YEAR_END         Starting year [default: 2016-12].
    -h, --help                  Show this help message and exits.
    --version                   Print version and copyright information.
----
download_sizes.sh 0.1.0
copyright (c) 2016 Cristian Consonni
MIT License
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
EOF
)"

set -euo pipefail
IFS=$'\n\t'

CHECKSUMS_DIR=$(realpath "../checksums")
if $debug; then
    function echodebug() {
        echo -n "[DEBUG] "
        echo "$@"
    }
    echodebug "debugging enabled."

    echodebug -e "date_start: \t $date_start"
    echodebug -e "date_end: \t $date_end"
fi

year_start="$(echo "$date_start" | cut -c 1-4)"
month_start="$(echo "$date_start" | cut -c 6-8)"
year_end="$(echo "$date_end" | cut -c 1-4)"
month_end="$(echo "$date_end" | cut -c 6-8)"

if $debug; then
    echodebug -e "year_start: \t $year_start"
    echodebug -e "month_start: \t $month_start"
    echodebug -e "year_end: \t $year_end"
    echodebug -e "month_end: \t $month_end"
fi

startdate=$(date -d "${year_start}-${month_start}-01" +%s)
enddate=$(date -d "${year_end}-${month_end}-01" +%s)

if [ "$startdate" -ge "$enddate" ]; then
    (>&2 echo "Error: end date must be greater than start date")
fi

function skip_years() {
    if [ "$1" -le "$year_start" -a "$2" -lt "$month_start" ]; then return 0; fi
    if [ "$1" -ge "$year_end" -a "$2" -gt "$month_end" ]; then return 0; fi

    return 1
}

year=''
month=''
for year in $(seq "$year_start" "$year_end"); do
    for month in {01..12}; do
        if skip_years "$year" "$month"; then continue; fi

    	md5file="${year}-${month}.md5sum.txt"
    	targetdir="${year}-${month}"

        if [ "$year" -eq "2007" -a "$month" -lt "12" ]; then continue; fi

        echo "${year}-${month}"

        cp "$CHECKSUMS_DIR/${md5file}" "${targetdir}/md5sums.txt"

    done
done
