#!/usr/bin/env bash

dump_url=''

eval "$(docopts -V - -h - : "$@" <<EOF
Usage: wikidump-download.sh [options] <dump_url>
       wikidump-download.sh --kill
       wikidump-download.sh ( -h | --help )
       wikidump-download.sh --version

Arguments:
  <dump>                      URL with files to download.

Options:
  -c, --continue              Continue the previous download.
  -d, --debug                 Enable debug mode (incompatible with --quiet).
  -f, --ext <ext>             Extension of the files to filter [default: .7z].

  -k, --kill                  Kill connection.
  -q, --quiet                 Suppress output (incompatible with --debug).
  -t, --filetype <filetype>   Type of files to filter
                              [default: pages-meta-history].
  -h, --help                  Show this help message and exits.
  --version                   Print version and copyright information.

Example:
wikidump-download.sh https://dumps.wikimedia.org/enwiki/20210201/

----
wikidump-download.sh 0.3.0
copyright (c) 2021 Cristian Consonni
MIT License
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
EOF
)"

# bash strict mode
# shellcheck disable=SC2128
SOURCED=false && [ "$0" = "$BASH_SOURCE" ] || SOURCED=true

if ! $SOURCED; then
  set -euo pipefail
  IFS=$'\n\t'
fi

# script base directory
SCRIPTS_DIR="$(realpath \
  "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"\
)"
SIZES_DIR="$(realpath "$SCRIPTS_DIR/../sizes/" )"
DOWNLOADLISTS_DIR="$(realpath "$SCRIPTS_DIR/../downloadlists/" )"


#################### Utils
if $debug; then
  echodebug() {
    (>&2 echo "[$(date '+%F %H:%M:%S')][debug] $@" )
  }
  echodebug "debugging enabled."
else
  echodebug() { true; }
fi
####################

# --debug implies not --quiet
if $debug; then quiet=false; fi

if $kill; then
  "${SCRIPTDIR}"/download.sh --kill
  exit 0
fi

# 2021-03-06
#   * FIXME: pass optional arguments to each command below.

# 1. download size files for a given dump
#    $ ./sizes/download_sizes.sh \
#          https://dumps.wikimedia.org/eswiki/20210201/
#      -> sizes.2021-02-01.eswiki.pages-meta-history.txt
sizes_outfilename="$("${SIZES_DIR}"/download_sizes.sh "$dump_url" \
                     | sed -re 's#-> (.+)#\1#g')"
sizes_outfile="${SIZES_DIR}/${sizes_outfilename}"
echodebug "sizes_outfile: $sizes_outfile"

# 2. make lists of files to download
#    $ ./downloadlists/make_lists.sh \
#          sizes/sizes.2021-02-01.ptwiki.pages-meta-history.txt
#      -> downloadlists.sizes.2021-02-01.ptwiki.pages-meta-history.txt
dl_outfilename="$("${DOWNLOADLISTS_DIR}"/make_lists.sh "${sizes_outfile}" \
                  | sed -re 's#-> (.+)#\1#g')"
dl_outfile="${DOWNLOADLISTS_DIR}/${dl_outfilename}"
echodebug "dl_outfile: $dl_outfile"

# 3. download the actual dump files
#    $ ./scripts/download.sh \
#          downloadlists/downloadlists.2021-02-01.ptwiki.pages-meta-history.txt
"${SCRIPTS_DIR}"/download.sh "$dl_outfile"

exit 0
