#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

CHECKSUMS_DIR=$(realpath "../checksums")

year=''
month=''


for year in {2007..2015}; do
    for month in {01..12}; do

    	md5file="${year}-${month}.md5sum.txt"
    	targetdir="${year}-${month}"

        if [ "$year" -eq "2007" -a "$month" -lt "12" ]; then continue; fi

        echo "${year}-${month}"

        cp "$CHECKSUMS_DIR/${md5file}" "${targetdir}/md5sums.txt"

    done
done
