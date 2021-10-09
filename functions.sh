#!/usr/bin/env bash

cwd="$(
    cd -- "$(dirname "$0")" >/dev/null 2>&1
    pwd -P
)"

parse_ini() {
    declare -A parsed_ini=$(awk -F ' *= *' '{ if ($1 ~ /^\[/) section=$1; else if ($1 !~ /^$/) print $1 section "=" $2}' "$1")

    echo ${parsed_ini}
}

get() {
    declare -A parsed_ini_array

    parsed_ini=$(awk -F ' *= *' '{ 
        if ($1 ~ /^\[/) section=substr($1, 2, length($1)-2); 
        else if ($1 !~ /^$/) print "["section"_"$1"]" "=" $2
    }' "$1")

    for item in ${parsed_ini[@]}; do
        key=$(echo ${item} | awk 'match($0, /\[.*\]/) { print substr($0, RSTART+1, RLENGTH-2) } ')
        value=${item//*=/}
        parsed_ini_array[$key]=$value
    done

    echo ${parsed_ini_array[$2]}
}

link_files() {
    user=$(get ${cwd}/config.ini user_name)
    user=${user//\"/}
    dotfiles=$(parse_ini "${cwd}/dotfiles.ini")

    for item in ${dotfiles[@]}; do
        program_name=$(echo ${item} | awk 'match($0, /\[.*\]/) { print substr($0, RSTART+1, RLENGTH-2) } ')
        filepath=${item//*=/}
        target=${filepath//*~/\/home\/$user}
        filename=$(basename ${target})
        source="${cwd}/config/${program_name}/${filename}"

        ln -vsf ${source} ${target}
        chown ${user}:${user} ${target}
        echo $source
    done
}

"$@"
