#!/bin/bash

current_res=$(xrandr --current | grep '*' | head -n1 | awk '{print $1}')
[ "$current_res" == "1920x1080" ] || xrandr --output eDP-1 --mode 1920x1080 --rate 120
