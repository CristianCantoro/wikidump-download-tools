#!/usr/bin/env bash

dry_run=false
quiet=false
debug=false

eval "$(docopts -V - -h - : "$@" <<EOF
Usage: azure-transfer.sh [options]

    -d, --debug     Debug mode (incompatible with --quiet).
    -n, --dry-run   Do not upload files or create containers.
    -q, --quiet     Suppress output (incompatible with --debug).
    -h, --help      Show this help message and exits.
    --version       Print version and copyright information.
----
azure-transfer.sh 0.1.0
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

if $quiet && $debug; then
    (>&2 echo "Error: options --debug (-d) and --quiet (-q) are incompatible.")
    (>&2 echo "See help (-h, --help) for more info")
    exit 1
fi

verbosity_opt='-q'
if $debug; then verbosity_opt='-d'; fi

scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Read command output into array.
# See:
# http://askubuntu.com/questions/439026/
#     store-output-of-command-into-the-array
completed_years=($( cat "${scriptdir}/completed.years.txt" ))


for year in {2007..2015}; do
    for month in {01..12}; do
        if [ "$year" -eq "2007" ] && [ "$month" -lt "12" ]; then continue; fi

        echoq -ne "$year-$month "

        if containsElement "$year-$month" "${completed_years[@]}"; then
            echoq -e "\t skipping (already done)"
            continue
        fi

        transfer_logfile="${scriptdir}/azure-transfer.${year}${month}.log"
        write_log () {
            # write_log "201204" "download.start" 
            # echo "download.start" > "${scriptdir}/azure-transfer.201204.log"   
            echo "$1" >> "$transfer_logfile"   
        }

        transfer_log=('')
        if [ -f "$transfer_logfile" ]; then
            transfer_log=($( cat "$transfer_logfile" ))
        fi

        wrap_run () {

            local cmd_name
            cmd_name="$1"
            shift

            local continue_opt=''

            if containsElement "$cmd_name.completed" "${transfer_log[@]}"; then
                echoq -e "\t skipping (already done)"
                return 0;
            fi

            if containsElement "$cmd_name.start" "${transfer_log[@]}"; then
                echoq -e "\t (continuing)"
            else
                write_log "$cmd_name.start"
            fi
            

            if $debug; then
                echo -ne "\n\t"
                echo "$@"
            fi

            if $dry_run; then
                echoq "(dry run)"
            else
                # "$@"
                if ! $debug; then echoq "done"; fi
            fi
            write_log "$cmd_name.completed"
        }

        echoq ''

        echoq -ne "  * Download pagecounts \t\t ... "
        wrap_run "download" "${scriptdir}/scripts/download.sh" "$verbosity_opt" "$year" "$month"

        exit 0

        echoq -ne "  * Compute checksums \t\t\t ... "
        wrap_run "compute_checksums" "${scriptdir}/data/checkme.sh" "$verbosity_opt" "$year-$month/"

        echoq -ne "  * Move download log to downloads dir \t ... "
        wrap_run "download_move" "mv" "${scriptdir}/download.$year-$month.txt" "${scriptdir}/downloads/download.$year-$month.txt"

        echoq -ne "  * Check checksums \t\t\t ... "
        wrap_run "check_checksums" "${scriptdir}/checksums/check_checksums.sh" "$verbosity_opt" "${scriptdir}/checksums/check/$year-$month/"

        echoq -ne "  * Upload files on MS Azure \t\t ... "
        wrap_run "upload" "${scriptdir}/azure-copy.sh" "$verbosity_opt" "${scriptdir}/data/$year-$month/"

        echoq -ne "  * Check upload was successful \t ... "
        wrap_run "check_upload" "${scriptdir}/uploads/check_uploads.sh" "$verbosity_opt" "${scriptdir}/upload.${year}${month}.txt"

        echoq -ne "  * Move upload log to uploads dir \t ... "
        wrap_run "move_upload" "mv" "${scriptdir}/upload.$year-$month.txt" "${scriptdir}/uploads/upload.$year-$month.txt"

        echoq -ne "  * Remove pagecounts \t\t\t ... "
        wrap_run "remove_data" "rm" "-r" "${scriptdir}/data/${year}-${month}/"

        # rm "${scriptdir}/azure-transfer.${year}${month}.log"
        # echo "${year}-${month}" >> "${scriptdir}/completed.years.txt"

    done
done

echoq "done"
