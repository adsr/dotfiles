# dotfiles

dotfiles, config, setup notes for Xubuntu 18.04 on Lenovo X1 Carbon Gen 6

### libvte

Replace libvte with [patched version][0] to completely disable alternate screen
scrolling (mouse-based scrolling inside screen, tmux, readline, etc). If
upgrading xfce4-terminal, get fresh libvte sources from launchpad, apply Debian
patches, and update repo linked above. Overwrite libvte in
`/usr/lib/x86_64-linux-gnu/` (ld does not pick it up in `/usr/local/lib/`).

I think there is supposed to be a way to disable this in config but I recall it
only working partially.

### xfce4-terminal

Kill all instances of `xfce4-terminal` and run these in `xterm` or from a
console.

    cp -vf ~/dotfiles/xf4term-terminalrc ~/.config/xfce4/terminal/terminalrc
    cp -vf ~/dotfiles/xf4term-accels.scm ~/.config/xfce4/terminal/xf4term-accels.scm

### Synaptics Touchpad

In `Application Autostart`, add `synclient` command to disable touchpad bs.

    synclient RTCornerButton=0 RBCornerButton=0 VertEdgeScroll=0 ClickFinger1=0 ClickFinger2=0 MaxTapTime=0 MaxTapMove=0 MaxDoubleTapTime=0 SingleTapTimeout=0

### Screen lock and suspend

We are affected by [this bug][2] which makes screen locking/unlocking painful.
Declare bankruptcy on `light-locker` even though it is probably not its fault.

    sudo apt remove light-locker

Compile xscreensaver with `--with-systemd` and install. In version 5.43,
`make install` does not install `xscreensaver-systemd`. Do that manually. Then
make a user service:

    # /home/adam/.config/systemd/user/xscreensaver.service
    [Unit]
    Description=XScreenSaver
    [Service]
    ExecStart=/usr/local/bin/xscreensaver -no-splash -verbose -no-capture-stderr
    [Install]
    WantedBy=default.target

    systemctl --user enable xscreensaver
    systemctl --user start xscreensaver

Disable `New Login` button:

    echo -e '\nxscreensaver.newLoginCommand:\n' | tee -a ~/.Xdefaults
    xrdb < ~/.Xdefaults
    xscreensaver-command -restart

Make `xflock4` work again (`PATH` does not include `/usr/local/bin`):

    sudo sed -i 's|^PATH=.*|PATH=/bin:/usr/bin:/usr/local/bin|g' /usr/bin/xflock4

Set `Sleep state` to `Linux` in BIOS otherwise laptop does not wakeup from
suspend on lid open.

### PocketJet 3 Plus

See [pocketjet3plus-linux-setup][1]..

[0]: https://github.com/adsr/vte
[1]: https://github.com/adsr/pocketjet3plus-linux-setup
[2]: https://github.com/the-cavalry/light-locker/issues/114
