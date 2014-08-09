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

### Install (clobber mode)

By default, the install script will only create a symlink for files that do
not already exist relative to `$HOME`. In clobber mode (`-x`), if a file
already exists, the install script issues an `rm -rf` against it and replaces
it with a symlink. Therefore, danger!, use this option with care! Do a dry run
first.

    $ ./dotfiles/install.sh -d -x   # Dry run mode with clobber
    $ ./dotfiles/install.sh -x      # Install with clobber

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
