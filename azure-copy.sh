#!/usr/bin/env bash

dir=''
dry_run=false
continue=false
quiet=false
debug=false

eval "$(docopts -V - -h - : "$@" <<EOF
Usage: azure-copy.sh [options] <dir>

      <dir>                Directory to upload.
      -c, --continue       Continue the previous download.
      -d, --debug          Debug mode (incompatible with --quiet).
      -n, --dry-run        Do not upload files or create containers.
      -q, --quiet          Suppress output (incompatible with --debug).
      -h, --help           Show this help message and exits.
      --version            Print version and copyright information.
----
azure-copy.sh 0.1.0
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

containsElement () {
  local el
  for el in "${@:2}"; do [[ "$el" == "$1" ]] && return 0; done
  return 1
}

echoq() { echo "$@"; }
if $quiet; then
    echoq() { true; }
fi

export AZURE_STORAGE_ACCOUNT='pagecountsstorage'
export AZURE_STORAGE_ACCESS_KEY='8GcUp2eAayDFkapchf0LY8IKsBVDTbGZHo0n7xjrV0AOuuNTdIl51nBuoA4SH/2L2w9SxdsBGZsQZZhk8UEoVw=='

if $quiet && $debug; then
    (>&2 echo "Error: options --debug (-d) and --quiet (-q) are incompatible.")
    (>&2 echo "See help (-h, --help) for more info")
    exit 1
fi

container_name="$(echo ${dir} | awk -F'/' '{print $(NF-1)}' | tr -d '-')"
logfile="upload.${container_name}.txt"

if $debug; then
    echo -e "[DEBUG] container_name: \t $container_name"
    echo -e "[DEBUG] logfile:        \t $logfile"
fi


if $continue; then
    echoq "Container already created... continuing"
else
    echoq -n "Creating the container"
    if ! $dry_run; then

        if $debug; then
            azure storage container create "$container_name"
        else
            azure storage container create "$container_name" >> "${logfile}"
        fi
        echoq -e "... created"
    else
        echoq -e "... (dry run)"
    fi
fi

echoq "Uploading the files..."

uploaded_files=
if $continue; then
    # Read command output into array.
    # See:
    # http://askubuntu.com/questions/439026/
    #     store-output-of-command-into-the-array
    uploaded_files=($( \
            sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" "${logfile}"  | \
            grep -A5 "name" | \
            grep -B5 "command OK$" | \
            grep name | \
            awk '{print $3}' ))
fi

for filename in $dir*; do
    echoq -n "$filename "

    fbasename=$(basename "$filename")
    if containsElement "$fbasename" "${uploaded_files[@]}"; then
        echoq -e "\t skipping (already uploaded)"
    else
        echoq -ne "\t ... "

        if ! $dry_run; then
            if $debug; then
                azure storage blob upload "$filename" "$container_name" | tee -a "${logfile}"
            else
                azure storage blob upload "$filename" "$container_name" >> "${logfile}"
            fi
            echoq "uploaded"
        else
            echoq "(dry run)"
        fi
    fi
done

echoq "Done"
