#!/usr/bin/env bash
#v1.0 by sandylaw <freelxs@gmail.com> 2020-08-17
# shellcheck disable=SC1091
source common

function help() {
    # Display Help
    echo
    echo "Add deb and source to the apt repository."
    echo
    echo "Syntax: bash Add_to_APT_Repository.sh dist repo codename crp_rep_url"
    echo "options:"
    echo "just one dist:stable unstable and so on"
    echo "just one repo: device-gui device-cli and so on"
    echo "just one codename: fou fou/sp1 fou/sp2"
    echo "just one crp_rep_url or local dir path"
    #    echo "Tmp_Dir: default at ~/tmp/debs"

}
# common function
loadhelpall "$*"

#set dist dir
pushd /var/www/repos > /dev/null || exit
read -ra dists <<< "$(find . -maxdepth 1 -type d | awk -F "/" '{ print $2 }' | tr '\n' ' ')"
popd > /dev/null || exit
for dist in "${dists[@]}"; do
    if [ "$1" == "$dist" ]; then
        APTURL=/var/www/repos/$1
    fi
done
if [ ! -n "$APTURL" ]; then
    help
    echo "Pleaase check the dist name."
    echo "The system has dists list:${dists[*]}"
    exit 0
fi
# set REPO
pushd "$APTURL" > /dev/null || exit
read -ra repos <<< "$(find . -maxdepth 1 -type d | awk -F "/" '{ print $2 }' | tr '\n' ' ')"
popd > /dev/null || exit
for repo in "${repos[@]}"; do
    if [ "$2" == "$repo" ]; then
        REPO=$2
    fi
done
if [ ! -n "$REPO" ]; then
    help
    echo "Pleaase check the repos."
    echo "The system has repos list:${repos[*]}"
    exit 0
fi

REPOSDIR="$APTURL"/"$REPO"

# check codename
read -ra codenames <<< "$(grep Codename < "$REPOSDIR"/conf/distributions | awk '{ print $2 }' | tr '\n' ' ')"
# common function
CODENAME=$(check_word_in_array "$3" "${codenames[*]}")
if [ ! -n "$CODENAME" ]; then
    echo "Pleaase check the codename."
    echo "The system has codename list:${codenames[*]}"
    exit 0
fi

TUSER=$(whoami)
#echo "$TUSER"
DEBDIR=/home/"$TUSER"/tmp/debs
mkdir -p "$DEBDIR" && cd "$_" || exit
URL=$4
# common function
isurl=$(check_url "$URL")
if [ "$isurl" == 0 ] && [ "${URL: -1}" == "/" ]; then
    wget -r -p -np -k "$URL"
elif [ -d "$URL" ]; then
    rsync -r "$URL" .
else
    help
    echo "Pleach chek the URL, must end with '/' "
    exit 0
fi

add_to_repository "$TUSER" "$REPOSDIR" "$CODENAME" "$DEBDIR"
echo "Clening:delete the $DEBDIR"
sudo rm -rf "$DEBDIR"
