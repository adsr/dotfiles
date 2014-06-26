#!/bin/bash

my_version="0.1"
my_url="https://github.com/adsr/dotfiles"
my_self=$(basename $0)
my_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
my_repo=$(basename "${my_dir}")
my_dry_run=""
my_uninstall=""

# Say hello
echo "${my_repo} ${my_version}"
echo "${my_url}"
echo

# Parse args
my_usage() {
    echo "Usage: $0 -d(dry_run_mode) -u(uninstall) -h(help)" >&2
    exit 1
}
while getopts "duh" opt; do
    case "${opt}" in
        d)
            my_dry_run="1"
            ;;
        u)
            my_uninstall="1"
            ;;
        *)
            my_usage
            ;;
    esac
done

# Require HOME var
if [ -z "${HOME}" ]; then
    echo 'HOME var is empty; bailing' >&2
    exit 1
fi

# Output run params
echo -n 'Run mode: '
if [ -n "${my_uninstall}" ]; then echo "uninstall"; else echo "install"; fi
echo -n ' Dry run: '
if [ -n "${my_dry_run}" ]; then echo "yes"; else echo "no"; fi
echo

# Symlink all files and directories
shopt -s dotglob
for f in ${my_dir}/*; do
    f=$(basename $f)
    if [ "${f}" == "${my_self}" -o "${f}" == ".git" -o "${f}" == "README.md" ]; then
        # Skip self and other known non-dotfiles
        continue
    fi
    my_target="${HOME}/${f}"
    my_source="${my_dir}/${f}"
    my_cmd=""
    echo $f
    if [ -n "${my_uninstall}" ]; then
        # Uninstall mode (remove symlink)
        if [ ! -e "${my_target}" ]; then
            # Skip if it does not exist
            echo "    ${my_target} does not exist; skipping"
            continue
        elif [ ! -h "${my_target}" ]; then
            # Skip if it is not a symlink
            echo "    ${my_target} exists but is not a symlink; skipping"
            continue
        elif [ $(readlink -f "${my_target}") != "${my_source}" ]; then
            # Skip if it is not a symlink to us
            echo "    ${my_target} is a symlink but does not point to ${my_source}; skipping"
            continue
        fi
        my_cmd="rm ${my_target}"
    else
        # Install mode (create symlink)
        if [ -e "${my_target}" ]; then
            # Skip if it already exists
            echo "    ${my_target} already exists; skipping"
            continue
        fi
        my_cmd="ln -s ${my_source} ${my_target}"
    fi
    if [ -n "${my_dry_run}" ]; then
        echo "    Dry run: $my_cmd"
    else
        echo "    $my_cmd"
        eval ${my_cmd}
        if [ "$?" -ne "0" ]; then
            echo "Non-zero exit code on last command; stopping" >&2
            exit 1
        fi
    fi
done

echo
echo 'Done'
