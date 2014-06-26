# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# Source definitions in .bashrc.d directory
if [ -d $HOME/.bashrc.d ]; then
    for x in $HOME/.bashrc.d/* ; do
        test -f "$x" || continue
        test -x "$x" || continue
        . "$x"
    done
fi
