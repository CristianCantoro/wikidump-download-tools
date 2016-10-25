#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

year=''
month=''
url=''
BASEURL="https://dumps.wikimedia.org/other/pagecounts-raw"

YEAR_START=2007
YEAR_END=2016

for year in $(seq "$YEAR_START" "$YEAR_END"); do
    for month in {01..12}; do
        if [ "$year" -eq "2007" -a "$month" -lt "12" ]; then continue; fi
        if [ "$year" -eq "2016" ] && [ "$month" -gt "08" ]; then continue; fi


        url="$BASEURL/${year}/${year}-${month}/"
	output="${year}-${month}.txt"
	tmp_output="${output}.tmp"

        echo "wget -O ${tmp_output} $url"
        wget -O "${tmp_output}" "$url" 

	 [ -f "${tmp_output}" ] && \
            xidel --extract "//li" "${tmp_output}" > "${output}"

	rm "${tmp_output}"
    done
done
