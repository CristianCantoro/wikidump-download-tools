#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

year=''
month=''
url=''
BASEURL="https://dumps.wikimedia.org/other/pagecounts-raw"


for year in {2007..2015}; do
    for month in {01..12}; do

        if [ "$year" -eq "2007" -a "$month" -lt "12" ]; then continue; fi

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
