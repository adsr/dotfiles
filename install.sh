#!/bin/bash

df_version="0.2"
df_self=$(basename $0)
df_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
df_dry_run=1
df_clobber=0
df_uninstall=0

# Print header
echo "dotfiles ${df_version}"
echo 'https://github.com/adsr/dotfiles'
echo

# Parse args
df_usage() {
    exit_code=$1
    echo "Usage: $0 -w(wet_run_mode) -x(clobber) -u(uninstall) -h(help)" >&2
    exit $exit_code
}
while getopts "wuhx" opt; do
    case "${opt}" in
        w) df_dry_run=0 ;;
        u) df_uninstall=1 ;;
        x) df_clobber=1 ;;
        h) df_usage 0 ;;
        *) df_usage 1 ;;
    esac
done

# Output run params
echo -n 'Run mode: '; [ $df_uninstall -eq 1 ] && echo 'uninstall' || echo 'install'
echo -n ' Dry run: '; [ $df_dry_run -eq 1 ]   && echo 'yes' || echo 'no'
echo -n ' Clobber: '; [ $df_clobber -eq 1 ]   && echo 'yes' || echo 'no'
echo
read -p "Press enter to continue, or Ctrl-C to abort..."
echo

# Symlink all files and directories
update_symlink() {
    path_src=$1
    path_sym="$HOME/$(basename $path_src)"
    df_cmd=''
    echo $path_src
    if [ $df_uninstall -eq 1 ]; then
        # Uninstall mode (remove symlink)
        if [ ! -e "${path_sym}" ]; then
            # Skip if it does not exist
            echo "    ${path_sym} does not exist; skipping"
            return
        elif [ ! -h "${path_sym}" ]; then
            # Skip if it is not a symlink
            echo "    ${path_sym} exists but is not a symlink; skipping"
            return
        elif [ $(readlink -f "${path_sym}") != "${path_src}" ]; then
            # Skip if it is not a symlink to us
            echo "    ${path_sym} is a symlink but does not point to ${path_src}; skipping"
            return
        fi
        df_cmd="rm ${path_sym}"
    else
        # Install mode (create symlink)
        if [ -e "${path_sym}" ]; then
            # Already exists
            if [ $df_clobber -eq 1 ]; then
                # Clobber mode on; delete!
                df_cmd="rm -rf ${path_sym} && "
            else
                # Clobber mode off; skip
                echo "    ${path_sym} already exists; skipping"
                diff "${path_src}" "${path_sym}"
                return
            fi
        fi
        df_cmd="${df_cmd}ln -s ${path_src} ${path_sym}"
    fi
    if [ $df_dry_run -eq 1 ]; then
        echo "    Dry run: $df_cmd"
    else
        echo "    $df_cmd"
        eval $df_cmd
        if [ "$?" -ne "0" ]; then
            echo "Non-zero exit code on last command; stopping" >&2
            exit 1
        fi
    fi
}

for f in $(find $df_dir -mindepth 1 -maxdepth 1 | grep -Pv '(README\.md|\.git|install\.sh)'); do
    update_symlink $f
done

# Fin
echo
echo 'Done'
