#!/usr/bin/bash
#v1.0 by sandylaw <freelxs@gmail.com> 2020-08-17
#This script is add list of packages to the list.
#Eg. bash addtolist $URL unstable_device-gui_fou-sp2.list
#fou/sp2 replaced by fou-sp2.
# shellcheck disable=SC1091
source ../common
function help() {
    # Display Help
    echo
    echo "Add list of packages to the list file."
    echo
    echo "Syntax: bash addtolist URL unstable_device-gui_fou-sp2.list"
    echo "options:"
    echo "dist:stable unstable and so on"
    echo "repo: device-gui device-cli and so on"
    echo "codename: fou fou/sp1 fou/sp2 and so on"
    echo "Please Notice:Eg. fou/sp2 replaced by fou-sp2"
}
# common function
loadhelpall "$*"
URL=$1
if [ ! -n "$2" ]; then
    echo "Please input list name,E.g: unstable_device-gui_fou-sp2.list"
fi
LIST=$2
isurl=$(check_url "$URL")
if [ "$isurl" == 0 ] && [ "${URL: -1}" == "/" ]; then
    :
elif     [ "$isurl" == 0 ] && [ "${URL: -1}" != "/" ]; then
    URL=$URL"/"
else
    echo "Please check the URL: $URL"
    exit 1
fi

function getwebdir() {
    URL=$1
    read -ra WEBDIR <<< "$(wget -O - "$URL" 2> /dev/null | grep href= | awk -F '"' '{print $2}' | tr "\\n" " ")"
    for d in ${WEBDIR[*]}; do
        URL=$1
        if [ "${d: -1}" == "/" ]; then
            URL=$URL"$d"
            # 调用自身
            getwebdir "$URL"
        elif [ "${d##*.}" == "deb" ]; then
            RESULT_WEBDIR+=("$URL")
        else
            :
        fi
    done
}

getwebdir "$URL"

read -ra RESULT_WEBDIR <<< "$(echo "${RESULT_WEBDIR[@]}" | sed 's/ /\n/g' | sort | uniq | tr "\\n" " ")"
echo "${RESULT_WEBDIR[@]}" | sed 's/ /\n/g' | sort | uniq | tee -a "$LIST" &> /dev/null
sort < "$LIST" | uniq | tee tmplist && mv tmplist "$LIST"
rm -rf wget-log
