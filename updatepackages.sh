#!/usr/bin/bash
#v1.0 by sandylaw <freelxs@gmail.com> 2020-08-17
#This script is add packages of update/dist_repo_codename.list to the apt repos.
#Eg. unstable_device-gui_fou-sp2.list
#fou/sp2 replaced by fou-sp2.

TUSER=$(whoami)
MYDIR=$(
    cd "$(dirname "$0")" || exit
    pwd
)
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
            listname=$(echo "$dist"_"$repo"_"$codename" | tr "/" "-")
            if [ -f list/"$listname".list ]; then
                for line in $(< list/"$listname".list); do
                    SRC="$line"
                    #time=$(date +%Y%m%d%H%M)
                    filename=$(basename "$SRC")
                    pwd
                    pushd "$CACHEDIR" > /dev/null || exit
                    wget -O - "$SRC" | grep .deb | awk -F '[ ":> ]' '{printf $3 " " $7 $8 $9 $10"\n"}' | tee "$filename"_new &> /dev/null
                    if [ -f "$filename"_old ]; then
                        diff "$filename"_new "$filename"_old > "$filename"_diff
                    else
                        popd > /dev/null || exit
                        # Haha fresh , add first.
                        bash Add_to_APT_Repository.sh "$dist" "$repo" "$codename" "$SRC"
                        pushd "$CACHEDIR" > /dev/null || exit
                    fi

                    mv "$filename"_new "$filename"_old

                    if [ -f "$filename"_diff ]; then
                        DIFF=$(wc -c "$filename"_diff | awk '{print $1}')
                    fi
                    popd > /dev/null || exit
                    if [[ "$DIFF" -gt 0 ]]; then
                        echo "INFO Now will update packages to $dist $repo $codename "
                        bash Add_to_APT_Repository.sh "$dist" "$repo" "$codename" "$SRC"
                    fi

                done
            else
                echo "$listname".list is not exist.
            fi
        done
    done

done
