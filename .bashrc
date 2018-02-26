# Source global bashrc
if [ -f /etc/bashrc ]; then
    source /etc/bashrc
fi

# Source .bashrc.d
if [ -d $HOME/.bashrc.d ]; then
    for x in $HOME/.bashrc.d/* ; do
        test -f "$x" -a -x "$x" || continue
        source "$x"
    done
fi
