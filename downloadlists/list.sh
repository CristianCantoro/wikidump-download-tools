#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

BASEURL_WM='https://dumps.wikimedia.org/other/pagecounts-raw'
BASEURL_CRC='http://wikimedia.crc.nd.edu/other/pagecounts-raw'
BASEURL_YOUR='http://dumps.wikimedia.your.org/other/pagecounts-raw'

url_wm="${BASEURL_WM}/$2/$2-$3/$1"
url_crc="${BASEURL_CRC}/$2/$2-$3/$1"
url_your="${BASEURL_YOUR}/$2/$2-$3/$1"

echo -e "$url_wm\t$url_crc\t$url_your"
