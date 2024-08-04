#!/bin/sh

set -e

run_a11y_agent() {
    files=$1
    for file in $files
    do
        ./exe/a11y_agent "$file"
    done
}

get_files() {
    files=$(find "$1" -type f \( -iname "*.block" -o -iname "*.list" -o -iname "*.item" -o -iname "*.liquid" -o -iname "*.tpl" -o -iname "*.twig" -o -iname "*.html" -o -iname "*.erb" \))
    echo "$files"
}

help() {
    echo "Usage: ./exe/a11y_agent.sh --repo <repo>"
    echo "Usage: ./exe/a11y_agent.sh --file <file>"
    echo "Usage: ./exe/a11y_agent.sh --dir <dir>"
}

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    help
    exit 0
elif [ "$1" = "--repo" ]; then
    if [ ! -d "/tmp/$2" ]; then
        echo "Cloning repo..."
        gh repo clone "$2" "/tmp/$2"
    fi

    echo "Found $2 in /tmp/$2"
    files=$(get_files "/tmp/$2")
    run_a11y_agent "$files"
elif [ "$1" = "--dir" ]; then
    files=$(get_files "$2")
    run_a11y_agent "$files"
elif [ "$1" = "--file" ]; then
    run_a11y_agent "$2"
elif [ -z "$1" ]; then
    help
    exit 0
fi
