#!/usr/bin/env bash

dry_run=false
quiet=false
debug=false

eval "$(docopts -V - -h - : "$@" <<EOF
Usage: azure-transfer.sh [options]

    -d, --debug     Debug mode (incompatible with --quiet).
    --date-start YEAR_START     Starting year [default: 2007-12].
    --date-end YEAR_END         Starting year [default: 2016-12].
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

scriptpid=$$

tmpdir='/tmp/azure-transfer.dir'
lockfile="running.$scriptpid"

mkdir -p "${tmpdir}"
touch "${tmpdir}/$lockfile"

function finish {
  rm -f "${tmpdir}/$lockfile"
  rm -f "${tmpdir}/$scriptpid."*".lock"
}
trap finish EXIT

# Dictionarues in bash
# See:
# https://stackoverflow.com/questions/1494178/
#   how-to-define-hash-tables-in-bash
declare -A continue_opts=( ["download"]='-c'
                           ["compute_checksums"]=''
                           ["download_move"]=''
                           ["check_checksums"]=''
                           ["upload"]='-c'
                           ["check_upload"]=''
                           ["move_upload"]=''
                           ["remove_data"]=''
                           ["remove_transferlog"]=''
                           ["finish_year"]=''
                           )

declare -A verbosity_opts=( ["download"]='-c'
                          ["compute_checksums"]='-c'
                          ["download_move"]=''
                          ["check_checksums"]=''
                          ["upload"]='-c'
                          ["check_upload"]=''
                          ["move_upload"]=''
                          ["remove_data"]=''
                          ["remove_transferlog"]=''
                          ["finish_year"]=''
                          )

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

if $debug; then
    function echodebug() {
        echo -n "[DEBUG] "
        echo "$@"
    }
    echodebug "debugging enabled."

    echodebug -e "date_start: \t $date_start"
    echodebug -e "date_end: \t $date_end"
fi

year_start="$(echo "$date_start" | cut -c 1-4)"
month_start="$(echo "$date_start" | cut -c 6-8)"
year_end="$(echo "$date_end" | cut -c 1-4)"
month_end="$(echo "$date_end" | cut -c 6-8)"

if $debug; then
    echodebug -e "year_start: \t $year_start"
    echodebug -e "month_start: \t $month_start"
    echodebug -e "year_end: \t $year_end"
    echodebug -e "month_end: \t $month_end"
fi

startdate=$(date -d "${year_start}-${month_start}-01" +%s)
enddate=$(date -d "${year_end}-${month_end}-01" +%s)

if [ "$startdate" -ge "$enddate" ]; then
    (>&2 echo "Error: end date must be greater than start date")
fi

function skip_years() {
    if [ "$1" -le "$year_start" -a "$2" -lt "$month_start" ]; then return 0; fi
    if [ "$1" -ge "$year_end" -a "$2" -gt "$month_end" ]; then return 0; fi

    return 1
}

verbosity_opt='-q'
if $debug; then verbosity_opt='-d'; fi

scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

for year in $(seq "$year_start" "$year_end"); do
    for month in {01..12}; do
        if [ "$year" -eq "2007" ] && [ "$month" -lt "12" ]; then continue; fi
        if [ "$year" -eq "2016" ] && [ "$month" -gt "08" ]; then continue; fi

        echoq -ne "$year-$month "

        # Read command output into array.
        # See:
        # http://askubuntu.com/questions/439026/
        #     store-output-of-command-into-the-array
        completed_years=($( cat "${scriptdir}/completed.years.txt" ))
        processing_years=($( find "${tmpdir}" -name "*.${year}${month}.lock" -printf "%f\n" | \
                             awk -F'.' '{print $2}' ))


        if [ "${#completed_years[@]}" -gt 0 ] && \
                containsElement "${year}-${month}" "${completed_years[@]}"; then
            echoq -e "\t skipping (completed)"
            continue
        fi

        if [ "${#processing_years[@]}" -gt 0 ] && \
                containsElement "${year}${month}" "${processing_years[@]}"; then
            processing_pid=$(find "${tmpdir}" -name "*.${year}${month}.lock" -printf "%f\n" | \
                             awk -F'.' '{print $1}')
            echoq -e "\t skipping (being processed by PID $processing_pid)"
            continue
        fi

        touch "${tmpdir}/$scriptpid.${year}${month}.lock"

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

            # echo ''
            # return 0;

            local cmd_name
            cmd_name="$1"
            shift

            local numargs="$#"
            local continue_opt=''

            if containsElement "$cmd_name.completed" "${transfer_log[@]}"; then
                echoq -e "skipping (already done)"
                return 0;
            fi

            if containsElement "$cmd_name.start" "${transfer_log[@]}"; then
                echoq -en "continuing ... "
                continue_opt="${continue_opts[$cmd_name]}"
            else
                write_log "$cmd_name.start"
            fi

            local cmd=()
            for (( i=1; i<=numargs; i++ )); do
                cmd+=("$1")
                if [ "$i" -eq "2" ] && [ ! -z "$continue_opt" ]; then
                    cmd+=("$continue_opt")
                fi
                shift
            done

            if $debug; then
                echo -ne "\n\t"
                echo "${cmd[@]}"
            fi

            if $dry_run; then
                echoq "(dry run)"
            else
                # "$@"
                "${cmd[@]}"
                if ! $debug; then echoq "done"; fi
            fi
            write_log "$cmd_name.completed"

        }

        echoq ''

        echoq -ne "  * Download pagecounts \t\t ... "
        wrap_run "download" "${scriptdir}/scripts/download.sh" "$verbosity_opt" "$year" "$month"

        echoq -ne "  * Compute checksums \t\t\t ... "
        cd "${scriptdir}/data"
        wrap_run "compute_checksums" "${scriptdir}/data/checkme.sh" "$verbosity_opt" "$year-$month"
        cd "${scriptdir}"

        echoq -ne "  * Move download log to downloads dir \t ... "
        wrap_run "download_move" "mv" "${scriptdir}/download.${year}${month}.txt" "${scriptdir}/downloads/download.${year}${month}.txt"

        echoq -ne "  * Check checksums \t\t\t ... "
        wrap_run "check_checksums" "${scriptdir}/checksums/check_checksums.sh" "$verbosity_opt" "${scriptdir}/checksums/check/$year-$month/"

        echoq -ne "  * Upload files on MS Azure \t\t ... "
        wrap_run "upload" "${scriptdir}/azure-copy.sh" "$verbosity_opt" "${scriptdir}/data/$year-$month/"

        echoq -ne "  * Check upload was successful \t ... "
        wrap_run "check_upload" "${scriptdir}/uploads/check_uploads.sh" "$verbosity_opt" "${scriptdir}/upload.${year}${month}.txt"

        echoq -ne "  * Move upload log to uploads dir \t ... "
        wrap_run "move_upload" "mv" "${scriptdir}/upload.${year}${month}.txt" "${scriptdir}/uploads/upload.${year}${month}.txt"

        echoq -ne "  * Remove pagecounts \t\t\t ... "
        wrap_run "remove_data" "rm" "-r" "${scriptdir}/data/${year}-${month}/"

        echoq -ne "  * Finish up \t\t\t\t ... "
        rm "${scriptdir}/azure-transfer.${year}${month}.log"
        rm "${tmpdir}/$scriptpid.${year}${month}.lock"

        if ! $dry_run; then
          echo "${year}-${month}" >> "${scriptdir}/completed.years.txt"

          if $debug; then
              echo -ne "\n\t rm ${scriptdir}/azure-transfer.${year}${month}.log"
              echo -e  "\n\t echo ${year}-${month} >> ${scriptdir}/completed.years.txt"
          fi
            echo "done"
        else
            echo "(dry run)"
        fi

    done
done

echoq "done"
