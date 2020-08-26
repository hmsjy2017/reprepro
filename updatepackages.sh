#!/usr/bin/bash
#v1.1 by sandylaw <freelxs@gmail.com> 2020-08-26
#This script is add packages of update/dist_repo_codename_comps.list to the apt repos.
#Eg. unstable_device_mars-sp1_main.list

TUSER=$(whoami)
MYDIR=$(
    cd "$(dirname "$0")" || exit
    pwd
)
comps=(main contrib non-free)
cd "$MYDIR" || exit
CACHEDIR=/home/$TUSER/.cache/apt-repo
if [ ! -d "$CACHEDIR" ]; then
    mkdir -p "$CACHEDIR"
fi
pushd /var/www/repos > /dev/null || exit
read -ra dists <<< "$(find . -maxdepth 1 -type d | awk -F "/" '{ print $2 }' | tr '\n' ' ')"
popd > /dev/null || exit
for dist in "${dists[@]}"; do
    APTURL=/var/www/repos/$dist
    pushd "$APTURL" > /dev/null || exit
    read -ra repos <<< "$(find . -maxdepth 1 -type d | awk -F "/" '{ print $2 }' | tr '\n' ' ')"
    popd > /dev/null || exit
    for repo in "${repos[@]}"; do
        REPO=$repo
        REPOSDIR="$APTURL"/"$REPO"
        read -ra codenames <<< "$(grep Codename < "$REPOSDIR"/conf/distributions | awk '{ print $2 }' | tr '\n' ' ')"
        for codename in "${codenames[@]}"; do
            for comp in "${comps[@]}"; do
                listname=$(echo "$dist"_"$repo"_"$codename"_"$comp" | tr "/" "-")
                if [ -f list/"$listname".list ]; then
                    for line in $(< list/"$listname".list); do
                        SRC="$line"
                        #time=$(date +%Y%m%d%H%M)
                        filename="$listname"_$(basename "$SRC")
                        pwd
                        pushd "$CACHEDIR" > /dev/null || exit
                        wget -O - "$SRC" | grep .deb | grep -Po 'href=\"\K.*?(?=")' | tee "$filename"_new &> /dev/null
                        if [ -f "$filename"_old ]; then
                            diff "$filename"_new "$filename"_old > "$filename"_diff
                        else
                            popd > /dev/null || exit
                            # Haha fresh , add first.
                            bash Add_to_APT_Repository.sh "$dist" "$repo" "$codename" "$comp" "$SRC"
                            pushd "$CACHEDIR" > /dev/null || exit
                        fi

                        mv "$filename"_new "$filename"_old

                        if [ -f "$filename"_diff ]; then
                            DIFF=$(wc -c "$filename"_diff | awk '{print $1}')
                        fi
                        popd > /dev/null || exit
                        if [[ "$DIFF" -gt 0 ]]; then
                            echo "INFO Now will update packages to $dist $repo $codename $comp"
                            bash Add_to_APT_Repository.sh "$dist" "$repo" "$codename" "$comp" "$SRC"
                        fi

                    done
                else
                    echo "$listname".list is not exist.
                fi
            done
        done
    done
done
