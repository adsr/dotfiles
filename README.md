# dotfiles

dotfiles, config, setup notes for my computers running Debian.

### xfconf

(Untested.) Logout and run from console:

    $ cd ~/.config
    $ tar xf ~/dotfiles/xfce4-config.tar

Includes conf for xfce4-panel, xfce4-terminal, etc.

### Workspace switcher icon width

Make the workspace switcher icons narrower like they used to be.

    $ cp -vf ~/dotfiles/gtk.css ~/.config/gtk-3.0/gtk.css

### Synaptics Touchpad (for Lenovo laptops)

In `Application Autostart`, add `synclient` command to disable touchpad bs.

    $ synclient RTCornerButton=0 RBCornerButton=0 VertEdgeScroll=0 ClickFinger1=0 ClickFinger2=0 MaxTapTime=0 MaxTapMove=0 MaxDoubleTapTime=0 SingleTapTimeout=0

### Other startup commands

    $ setxkbmap -layout us -option ctrl:nocaps # Make CapsLock a Ctrl key
    $ redshift-gtk -l 40.834398:-74.177090 -t 6500K:5000K # Color temp adjustment

### Screen lock, suspend, screensaver

Install `xfce4-screensaver`. Create and enable a systemd user service:

    $ mkdir -p ~/.config/systemd/user
    $ cp -vf ~/dotfiles/xfce4-screensaver.service ~/.config/systemd/user/xfce4-screensaver.service

Potentially set `Sleep state` to `Linux` in BIOS otherwise laptop does not
wakeup from suspend on lid open.

### PocketJet 3 Plus

See [pocketjet3plus-linux-setup][1].

### Windows 9x Theme

    $ mkdir ~/.themes
    $ cd $_
    $ tar xf ~/dotfiles/Redmond.tgz

Change theme in Window Manager settings.

### Replace lightdm with simple agetty+login

    # systemctl set-default multi-user.target # instead of graphical.target
    # systemctl cat switch-to-vt7.service
    [Unit]
    Description=Switch to vt7 after multi-user
    After=multi-user.target

    [Service]
    Type=idle
    ExecStart=/usr/bin/chvt 7
    RemainAfterExit=yes

    [Install]
    WantedBy=multi-user.target
    # systemctl enable switch-to-vt7.service
    # grep VT /etc/systemd/logind.conf
    NAutoVTs=7
    ReserveVT=7
    # cat /home/adam/.localbashrc
    #!/bin/bash
    # startx if
    # - not connected via SSH
    # - there is no existing display
    # - on vt7
    test "$SSH_TTY:$DISPLAY:$XDG_VTNR" = ::7 && test "$(tty)" = /dev/tty7 && exec startx

This can be simpler if you don't mind using vt1 for graphical.

[1]: https://github.com/adsr/pocketjet3plus-linux-setup
