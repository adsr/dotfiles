# dotfiles

dotfiles, config, setup notes for Xubuntu on Lenovo X1 Carbon

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

### PocketJet 3 Plus

See [pocketjet3plus-linux-setup][1]..

[0]: https://github.com/adsr/vte
[1]: https://github.com/adsr/pocketjet3plus-linux-setup
