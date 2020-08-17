#!/usr/bin/env bash
#v1.0 by sandylaw <freelxs@gmail.com> 2020-08-17

# shellcheck disable=SC1091
source common
TUSER=$(whoami)
PWD=$(pwd)
function help() {
    # Display Help
    echo "List or remove packages from the  apt repository."
    echo
    echo "Syntax: bash Setup_Reprepro.sh"
    echo "Input:can set several at once"
    echo "dists:stable unstable and so on "
    echo "repos:device-gui device-cli and so on"
    echo "codenames: fou fou/sp1 fou/sp2 and so on"
}
loadhelp "$1"
read -ra DISTS -p "Please input the apt dist name,E.g stable unstable:"
read -ra REPOS -p "Please input the apt repos name,E.g device-gui device-cli:"
read -ra CODES -p "Please input the codenames,E.g fou fou/sp1 fou/sp2:"
GPGNAME=devicepackages
GPGEMAIL=devicepackages@uniontech.com
SERVERNAME=localhost

# common function

Install_Required_Packages "$TUSER" "$PWD"
Generate_GPG_KEY "${GPGNAME}" "${GPGEMAIL}"

Configure_Apache2_with_reprepro "$SERVERNAME"

for dist in ${DISTS[*]}; do
    Configure_Reprepro /var/www/repos/"$dist" "${REPOS[*]}" "$PUBLIC_KEY_URL" "${CODES[*]}"
done
echo "The ASCII Format Public key is $PUBLIC_KEY_URL"
echo "The Passphrase saved at $PASSWD_URL"
