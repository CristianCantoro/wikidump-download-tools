#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

BASEURL_WM='https://dumps.wikimedia.org'
#BASEURL_YOUR='http://dumps.wikimedia.your.org'
BASEURL_CU='https://wikimedia.mirror.clarkson.edu'

url_wm="${BASEURL_WM}/$1/$2/$3"
#url_your="${BASEURL_YOUR}/$1/$2/$3"
url_cu="${BASEURL_CU}/$1/$2/$3"

#echo -e "${url_wm}\\t${url_your}\\t${url_cu}"
echo -e "${url_wm}\\t${url_cu}"
