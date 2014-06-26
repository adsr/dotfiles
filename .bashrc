# Source global bashrc
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# Source .bashrc.d
if [ -d $HOME/.bashrc.d ]; then
    for x in $HOME/.bashrc.d/* ; do
        test -f "$x" || continue
        test -x "$x" || continue
        . "$x"
    done
fi
