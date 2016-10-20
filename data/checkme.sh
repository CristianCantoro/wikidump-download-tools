#!/usr/bin/env bash

workdir=''
quiet=false
debug=false

eval "$(docopts -V - -h - : "$@" <<EOF
Usage: checkme.sh [options] <workdir>

      <workdir>
      -d, --debug       Enable debug mode (incompatible with --quiet).
      -q, --quiet       Suppress output (incompatible with --debug).
      -h, --help        Show this help message and exits.
      --version         Print version and copyright information.
----
checkme.sh 0.1.0
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

echoq() { echo "$@"; }
progress_opt='--progress'
if $quiet; then
    echoq() { true; }
    progress_opt=''
fi

if $quiet && $debug; then
    (>&2 echo "Error: options --debug (-d) and --quiet (-q) are incompatible.")
    (>&2 echo "See help (-h, --help) for more info")
    exit 1
fi

workdirname="$(echo "$workdir" | tr -d '/')"
checkdir="../checksums/check"

echoq "$workdirname";

mkdir -p "${checkdir}/${workdirname}/"

if $debug; then
  awk "{ printf \"%s ${workdirname}/%s\n\", \$1,\$2}" "${workdirname}/md5sums.txt" | \
      "$HOME/.linuxbrew/bin/parallel" \
          --progress \
          --joblog "${checkdir}/${workdirname}/joblog" \
          --results "${checkdir}/${workdirname}/md5sums/" \
          "echo {} | md5sum -c"
else
  awk "{ printf \"%s ${workdirname}/%s\n\", \$1,\$2}" "${workdirname}/md5sums.txt" | \
    "$HOME/.linuxbrew/bin/parallel" \
        $progress_opt \
        --joblog "${checkdir}/${workdirname}/joblog" \
        --results "${checkdir}/${workdirname}/md5sums/" \
        "echo {} | md5sum -c" 1>/dev/null
fi
