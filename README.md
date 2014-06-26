dotfiles
========

This repo houses my dotfiles + an install/uninstall bash script that uses the
typical symlink method. Installing will not clobber existing dotfiles, and
uninstalling will only remove symlinks that point to `dotfiles/`, so it's
pretty safe.

### Install

    $ cd ~
    $ git clone https://github.com/adsr/dotfiles
    $ ./dotfiles/install.sh -d      # Dry run mode
    $ ./dotfiles/install.sh         # Install

### Uninstall

    $ cd ~
    $ ./dotfiles/install.sh -u -d   # Dry run mode
    $ ./dotfiles/install.sh -u      # Uninstall
    $ rm -rf dotfiles

### Update dotfiles from repo

    $ cd ~/dotfiles
    $ git pull --rebase

### Add a dotfile

Just make one in `dotfiles/` and commit it to the repo. Run install.sh again.

### Remove a dotfile

    $ cd ~
    $ rm .somerc
    $ cd ~/dotfiles
    $ git rm .somerc
