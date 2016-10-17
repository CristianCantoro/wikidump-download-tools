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

        url="$BASEURL/${year}/${year}-${month}/md5sums.txt"
	output="${year}-${month}.md5sum.txt"

        echo "wget -O ${output} $url"
        wget -O "${output}" "$url" 
    done
done
