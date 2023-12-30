# dotfiles

dotfiles, config, setup notes for Debian bookworm on Lenovo X1 Carbon Gen 6

### xfce4-terminal

To install terminal config, kill all instances of `xfce4-terminal` and run these
in `xterm` or from a console.

    cp -vf ~/dotfiles/xf4term-terminalrc ~/.config/xfce4/terminal/terminalrc
    cp -vf ~/dotfiles/xf4term-accels.scm ~/.config/xfce4/terminal/accels.scm

TODO: Since around v1.1.0, config is now stored in xfconf. Include
`~/.config/xfce4/xfconf` here.

### xfce4-panel

Install `xfce4-panel-profiles`. Right click on panel, `Panel Preferences...`,
`Backup and restore`, `Import`, select `~/dotfiles/xf4panel-config.txt.tar.bz2`.

### Workspace switcher icon width

Make the workspace switcher icons narrower like they used to be.

    cp -vf ~/dotfiles/gtk.css ~/.config/gtk-3.0/gtk.css

### Synaptics Touchpad

In `Application Autostart`, add `synclient` command to disable touchpad bs.

    synclient RTCornerButton=0 RBCornerButton=0 VertEdgeScroll=0 ClickFinger1=0 ClickFinger2=0 MaxTapTime=0 MaxTapMove=0 MaxDoubleTapTime=0 SingleTapTimeout=0

### Other startup commands

    setxkbmap -layout us -option ctrl:nocaps # Make CapsLock a Ctrl key
    redshift-gtk -l 40.834398:-74.177090 -t 6500K:5000K # Color temp adjustment

### Screen lock, suspend, screensaver

Install `xfce4-screensaver`. Create and enable a systemd user service:

```
# /home/adam/.config/systemd/user/xfce4-screensaver.service
[Unit]
Description=Xfce Desktop Screensaver and Locker
After=graphical.target
StartLimitIntervalSec=30s
StartLimitBurst=5

[Service]
Environment=SYSTEMD_LOG_LEVEL=debug
ExecStart=/usr/bin/xfce4-screensaver --debug
Restart=always
RestartSec=1s

[Install]
WantedBy=graphical.target
```

Potentially set `Sleep state` to `Linux` in BIOS otherwise laptop does not
wakeup from suspend on lid open.

### PocketJet 3 Plus

See [pocketjet3plus-linux-setup][1].

[1]: https://github.com/adsr/pocketjet3plus-linux-setup

### Windows 9x Theme

    mkdir ~/.themes
    cd $_
    tar xf ~/dotfiles/Redmond.tgz

Change theme in Window Manager settings.
