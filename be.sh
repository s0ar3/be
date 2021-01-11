#!/bin/bash

# Name: toBE-checker
# Version: 0.1
# Author: s0ar3 (Valentin Soare)
# Github: https://github.com/s0ar3/be
# Short description: Check tool existance and then displays the package that contains it or not.

#Set cursor invisible and back.

INV_CURSOR=$(tput civis)
NRM_CURSOR=$(tput cnorm)

#Checking number of parameters to see if we have any input to check.

sanityChecks() {
    if [[ ${#} -lt 1 ]]; then
        printf "\n\e[31m%s\e[0m\n\n" " **No arguments given. We need at least one name of a tool to check if it is installed."
        exit
    fi
}

#Progress bar starter with message, sleep and progress character.

progress_dots() {
    local sleepTime="${1}"
    local typeP="${2}"
    local message="${3}"
    
    printf "%s" "${message}"

    while true; do
        printf "%s" "${typeP}"
        sleep "${sleepTime}"
    done

    trap 'kill $!' SIGTERM
}

#Function used to convert the output from a string variable into an array 
#and then print the output and put it nicely into a table.

endProgress_dots() {
    local printed_message="$1"
    local -a results
    
    kill "${!}"
    wait "${!}" 2> /dev/null
    sleep 0.1
    printf "%s\n\n" "DONE"
    sleep 0.5

    while IFS=$'\n' read -r line; do
        results+=("${line}")
    done <<< "${printed_message}"

    printf "%85s\n" " " | tr " " "-"
    printf "| %-6s |%-14s |%-28s|%-28s %s\n" "STATUS" " QUERY" " PACKAGE" " VERSION & RELEASE" "|"
    printf "%85s\n" " " | tr " " "-"

    for ((i=0; i<${#results[@]}; i++)) do
        printf "%s\n" "${results[i]}"
        if [[ $i -eq ${#results[@]}-2 ]]; then
            printf "%85s\n\n" " " | tr " " "-"
        fi       
    done
}

#Banner generation with green color, date and name of the script and version :P

generate_banner() {
  local msg 
  local edge
  msg="|         ${1}         |"
  edge=$(printf "%s" "${msg}" | awk 'gsub(".","-",$0)')
  printf "\e[38;5;113m"
  printf " %s\n" "${edge}"
  printf "%s\n %s\n" " ${msg}" "|      $(date "+%X %x")       |"
  printf " %s\n" "${edge}"
  printf "\e[0m\n"
}

#Print the name of the package and contains the query and its version/release.

find_package_complete() {
    local input="${1}"
    local item_searched="${2}"
    package=$(yum list installed "${input}" | awk 'NR==2{print $1}')
    version=$(yum list installed "${input}" | awk 'NR==2{print $2}')
    printf "|\e[32m %-8s\e[0m |\e[32m %-14s\e[0m| %-27s| %-28s|\n" "✔" "${item_searched}" "${package}" "${version}"
}

# Execute finding the package begin with the name of the tool in /usr/bin.

main() {
    declare -x not_installed=0
    for i in "$@"; do
        tool_installed=$(find /usr/bin /usr/sbin /opt -executable -type f -regextype posix-awk -iregex ".*/${i}" 2> /dev/null)
        exit_code=$?
        if [[ ("${exit_code}" -eq 0) && (-n "${tool_installed}")  ]] ; then
            if find_pckg=$(rpm -qf "${tool_installed}"); then
                find_package_complete "${find_pckg}" "${i}"
            else
                find_package_complete "${i}" "${i}"
            fi
        else
            printf "|\e[31m %-9s\e[0m| \e[31m%-14s\e[0m| %-27s| %-27s %s\n" "✘" "${i}" "not installed" "none" "|"
            ((not_installed++))
        fi
    done

    if [[ ${not_installed} -gt 0 ]]; then
        printf "\e[31m%s\e[0m" "Sript terminated! (${not_installed} tool(s) not installed.)"
    else
        printf "\e[32m%s\e[0m" "Sript terminated! (All tools installed.)"
    fi
}

# Generate logging file in /var/log/be

logging_output() {
    content=$1

    [[ ! -d /var/log/be ]] && { mkdir -p /var/log/be; }
    [[ ! -e /var/log/be/be.log ]] && { touch /var/log/be/be.log; printf "%105s\n" " " | tr ' ' '-' >> /var/log/be/be.log; }

    printf "%s\n" "${content}" | while read -r line_input; do
        printf "$(date) %s\n" "${line_input}" | awk 'gsub(/\|/,"")' >> /var/log/be/be.log
    done

    printf "%105s\n" " " | tr ' ' '-' >> /var/log/be/be.log
}

# Run the functions mentioned above and first as you can see output is put in variable $output_main
# and then in function called endProgress_dots this output is put into an array and displayed in the table

sanityChecks "$@"

printf "%s\n" "${INV_CURSOR}"

generate_banner "toBE-checker v0.1"
progress_dots "0.5" "." " Searching" &
output_main="$(main "$@")"
endProgress_dots "${output_main}"
logging_output "${output_main}"

printf "%s\n" "${NRM_CURSOR}"