#!/usr/bin/bash
#v1.0 by sandylaw <freelxs@gmail.com> 2020-08-26
#sync apt repos form Upstream
# shellcheck disable=SC1091
source common
function help() {
    # Display Help
    echo
    echo "Sync apt Repositoryform Upstream."
    echo
    echo "Syntax: bash syncupstream.sh codename [base|device|all]"
    echo "options:"
    echo "codename: mars mars/sp2 venus venus/sp1 and so on"
    echo "base:http://pools.uniontech.com/ppa/uos-base/"
    echo "device:http://10.8.0.113/unstable/device/"
    echo "all:base+device"
}

loadhelpall "$*"

read -ra codenames <<< "$(grep Codename < "$REPOSDIR"/conf/distributions | awk '{ print $2 }' | tr '\n' ' ')"
# common function
CODENAME=$(check_word_in_array "$1" "${codenames[*]}")
if [ -z "$CODENAME" ]; then
    echo "Pleaase check the codename."
    echo "The system has codename list:${codenames[*]}"
    exit 0
fi

# TUSER=$(whoami)
# MYDIR=$(
#     cd "$(dirname "$0")" || exit
#     pwd
# )

function syncbase() {
    CODENAME="$1"
    if [[ -d /var/www/repos/stable/device/ ]]; then
        pushd /var/www/repos/stable/device/ > /dev/null || exit
        sudo sed -ri 's/^Update/Update: uos/g' conf/distributions
        cat << EOF | sudo tee conf/updates
Name: uos
Suite: stable
Architectures: amd64 arm64 mips64el sw_64 source
Components: main contrib non-free
Method: http://pools.uniontech.com/ppa/uos-base/
#Method: file:///data/repo-dev-wh/ppa/dde-apricot
VerifyRelease: blindtrust
EOF
        sudo reprepro update "$CODENAME"
        popd > /dev/null || exit
    fi
}
function syncdevice() {
    CODENAME="$1"
    shift 1
    codenames=("$@")
    if [[ -d /var/www/repos/stable/device/ ]]; then
        pushd /var/www/repos/stable/device/ > /dev/null || exit
        sudo rm -f conf/updates
        for codename in "${codenames[@]}"; do
            sudo sed -ri 's/^Update:[ ]*uos[ ]*$codename/Update: $codename/g' conf/distributions
            cat << EOF | sudo tee -a conf/updates
Name: $codename
Suite: $codename
Architectures: amd64 arm64 mips64el sw_64 source
Components: main contrib non-free
Method: http://10.8.0.113/unstable/device/
#Method: file:///data/repo-dev-wh/ppa/dde-apricot
VerifyRelease: blindtrust

EOF
        done
        sudo reprepro update "$CODENAME"
        popd > /dev/null || exit
    fi
}
case $2 in
    base)
        syncbase "$CODENAME"
        ;;
    device)
        syncdevice "$CODENAME" "${codenames[*]}"
        ;;
    all)
        syncbase "$CODENAME"
        syncdevice "$CODENAME" "${codenames[*]}"
        ;;
    *) ;;

esac
