#!/bin/bash

# Name: toBE-checker
# Version: 0.1
# Author: s0ar3 (Valentin Soare)
# Github: https://github.com/s0ar3/be
# Short description: Check tool existance and then displays the package that contains it or not.

#Set cursor invisible and back.

INV_CURSOR=$(tput civis)
NRM_CURSOR=$(tput cnorm)

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

    printf "%74s\n" " " | tr " " "-"
    printf "| %-6s |%-14s |%-20s|%-25s %s\n" "STATUS" " QUERY" " PACKAGE" " VERSION & RELEASE" "|"
    printf "%74s\n" " " | tr " " "-"

    for ((i=0; i<${#results[@]}; i++)) do
        printf "%s\n" "${results[i]}"
        sleep 0.3
    done

    printf "%74s\n\n" " " | tr " " "-"
}

#Banner generation with green color, date and name of the script and version :P

generate_banner() {
  local msg 
  local edge
  msg="|         ${1}         |"
  edge=$(printf "%s" "${msg}" | sed 's/./-/g')
  printf "\n\e[38;5;113m"
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
    printf "|\e[32m %-8s\e[0m |\e[32m %-14s\e[0m| %-19s| %-25s|\n" "✔" "${item_searched}" "${package}" "${version}"
}


# Execute finding the package begin with the name of the tool in /usr/bin.

main() {
    for i in "$@"; do
        if tool_installed=$(which "${i}" 2> /dev/null); then
            if find_pckg=$(rpm -qf "${tool_installed}"); then
                find_package_complete "${find_pckg}" "${i}"
            else
                find_package_complete "${i}" "${i}"
            fi
        else
            printf "|\e[31m %-9s\e[0m| \e[31m%-14s\e[0m| %-19s| %-24s %s\n" "✘" "${i}" "not installed" "none" "|"
        fi
    done
}

# Run the functions mentioned above and first as you can see output is put in variable $output_main
# and then in function called endProgress_dots this output is put into an array and displayed in the table

printf "%s" "${INV_CURSOR}"
generate_banner "toBE-checker v0.1"
progress_dots "0.5" "." " Searching" &
output_main="$(main "$@")"
endProgress_dots "${output_main}"
printf "%s" "${NRM_CURSOR}"