#!/bin/bash

# bail if not running interactively
[[ $- == *i* ]] || return

# source global bashrc
[ -f /etc/bashrc ] && source /etc/bashrc

# env path
[ -d "${HOME}/go/bin"     ] && export PATH="${HOME}/go/bin:${PATH}"
[ -d "${HOME}/.bin"       ] && export PATH="${HOME}/.bin:${PATH}"
[ -d "${HOME}/bin"        ] && export PATH="${HOME}/bin:${PATH}"
[ -d "${HOME}/.local/bin" ] && export PATH="${HOME}/.local/bin:${PATH}"

# env prompt (different color for root)
ps1_color=32; [ "$EUID" = 0 ] && ps1_color=35
export PS1="\[\033[01;${ps1_color}m\]\u\[\033[00;${ps1_color}m\]@\[\033[01;${ps1_color}m\]\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "
unset ps1_color

# env locale
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

# env go
export GOPATH=~/go

# env history
export HISTCONTROL=ignoredups
export HISTSIZE=16384
export HISTFILESIZE=16384

# env less
export LESS=-Ri

# env lynx
export LYNX_CFG=~/.lynx.cfg

# env editor
for e in mle vim nano; do
    command -v $e &>/dev/null || continue;
    export EDITOR="$e"
    break
done

# shell opts
shopt -s histappend
shopt -s checkwinsize

# aliases
alias ls='ls --color=auto'
alias ll='ls --color=auto -lF'
alias la='ls --color=auto -alF'
alias pl="ps -eH -o user,pid,ppid,pgid,%cpu,%mem,vsz:8,rss:8,tty,stat,wchan:16,etime,args | less -S"
alias grep='grep --color=auto'
alias gg='git grep -iP'
alias bell='echo -e "\a"'
alias loc='echo "$(hostname):$(pwd)"'
alias ..='cd ..'
alias xcopy='xclip -sel c'
[ -f ~/.bash_aliases ] && source ~/.bash_aliases

# functions
ff()  { local IFS='*'; local patt="$*"; find . -iwholename "*${patt}*"; }
fo()  { ff "$@" | head -n1; }
fd()  { local IFS='*'; local patt="$*"; find . -type d -iwholename "*${patt}*"; }
fcd() { local d=$(fd "$@" | head -n1); [ -n "$d" ] && cd "$d"; }
screenall() {
    screen -X at \# stuff "$(echo -e "$@\r")"
}
dumpflow() {
    local OPTIND
    local iface='any'
    local hex=1
    while getopts ":ai:" opt; do
        case $opt in
            a) hex=0 ;;
            i) iface=$OPTARG ;;
        esac
    done
    shift $((OPTIND-1))
    local filter=$1
    if [ "$hex" -eq 1 ]; then
        ( set -x; sudo tcpdump -li "$iface" "$filter" -w- | tcpflow -r- -gBCDd5 )
    else
        ( set -x; sudo tcpdump -li "$iface" "$filter" -w- | tcpflow -r- -gBCd5 | tr -c '[:print:]'$'\n'$'\x1b' '.' )
    fi
}
write_if_missing() {
    local fname=$1
    local mode=$2
    local dname=$(dirname $fname)
    [ -f "$fname" ] && return
    [ -L "$fname" ] && rm -f "$fname"
    [ -d "$dname" ] || return
    cat >"$fname"
    [ -n "$mode" ] && chmod "$mode" "$fname"
}
mle_install() {(
    set -e
    local tmpdir=$(mktemp -d)
    pushd $tmpdir
    git clone --recursive https://github.com/adsr/mle.git
    pushd mle
    make mle_vendor=1
    mkdir -vp $HOME/bin
    cp -vf mle $HOME/bin
    popd
    popd
    rm -rf $tmpdir
)}
bashrc_update() {
    local url='https://raw.githubusercontent.com/adsr/dotfiles/master/bashrc'
    local yn=''
    local tmpf=$(mktemp)
    wget -O "$tmpf" "$url" || { echo 'Failed'; return; }
    diff -q "${BASH_SOURCE[0]}" "$tmpf" &>/dev/null
    [ "$?" -eq 0 ] && { echo 'No update'; return; }
    ( set -x; diff "${BASH_SOURCE[0]}" "$tmpf"; )
    echo; read -p 'Update? [yN] >' yn
    [ "$yn" = "y" ] && { cp -vf "$tmpf" "${BASH_SOURCE[0]}"; }
    rm -f "$tmpf"
}

# friendlier less
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# ls colors
[ -x /usr/bin/dircolors ] && eval "$(dircolors -b)"

# bash completion
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        source /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        source /etc/bash_completion
    fi
fi

# write ~/.screenrc
write_if_missing ~/.screenrc <<'EOD'
crlf off
startup_message off
vbell off
bell_msg 'Bell in window %n^G'
defmonitor off
defutf8 on
nethack off
autodetach on
defscrollback 10000
hardstatus alwayslastline
hardstatus string '%{= kw}[%H]  %-w[%{= dW}%n %t%{-}]%+w'
termcapinfo xterm* ti@:te@
term screen-256color
EOD

# write ~/.gdbinit
write_if_missing ~/.gdbinit <<'EOD'
set history save on
add-auto-load-safe-path /home/adam/php-src/.gdbinit
EOD

# write ~/.gitconfig
write_if_missing ~/.gitconfig <<'EOD'
[user]
name = Adam Saponara
email = as@php.net
[github]
user = adsr
[alias]
br = branch
ci = commit
co = checkout
df = diff
dfs = diff --staged
dfm = diff origin/master master
stp = status --porcelain
l = log --graph --decorate
ls = log --pretty=format:"%C(yellow)%h\\ %ad%Cred%d\\ %Creset%s%Cblue\\ [%cn]" --decorate --date=short
ll = log --pretty=format:"%C(yellow)%h%Cred%d\\ %Creset%s%Cblue\\ [%cn]" --decorate --numstat
rpop = "!git stash && git pull --rebase && git stash pop"
spush = "!v=$(git remote get-url --push origin | perl -pe 's|^https?://([^/]+)/([^/]+)/(.*)$|git@\\1:\\2/\\3|g') && git push $v $(git rev-parse --abbrev-ref HEAD)"
rpull = pull --rebase --stat
st = status
un = reset
praise = blame
sm = submodule
[color]
ui = auto
[core]
autocrlf = input
safecrlf = true
excludesfile = ~/.gitignore
preloadindex = true
[push]
default = tracking
[credential]
helper = cache --timeout=15552000
EOD

# write ~/.inputrc
write_if_missing ~/.inputrc <<'EOD'
"\C-d": beginning-of-line
EOD

# write ~/.wgetrc
write_if_missing ~/.wgetrc <<'EOD'
check-certificate=off
EOD

# write ~/.mlerc
write_if_missing ~/.mlerc 755 <<'EOD'
#!/bin/bash
echo '-w1'                                      # soft word wrap
echo '-c80'                                     # mark col 80
echo '-b1'                                      # highlight bracket pairs
echo '-i1'                                      # auto indent
echo '-u1'                                      # coarse undo
echo '-Ssyn_makefile,(/?Makefile|\.mk)$,4,0'    # syn_makefile
echo '-s^\t+,,515,0'
echo '-s^[^:\s]+(?=:),,260,0'
echo '-s^[^=\s]+(?==),,261,0'
echo '-Ssyn_mlerc,\.?mlerc$,4,1'                # syn_mlerc
echo '-s^;.*,,7,0'
echo '-Ssyn_markdown,\.md$,4,1'                 # syn_markdown
echo '-s^#.*,,256,0'
echo '-s^>.*,,4,0'
echo '-s^\s*(\*|\d+.),,6,0'
echo '-s^(\t| {4})(?=\S),,515,0'
echo '-Ssyn_terraform,\.tf$,2,1'                # syn_terraform
echo '-s^(module|output|provider|resource|variable|locals|terraform|data),,1285,0'
echo '-s[\[\]{}=],,258,0'
echo '-s(\d+|true|false),261,0'
echo '-s".*?",,4,0'
echo '-s{.*},,4,0'
echo '-s#.*$,,0,0'
echo '-Kmle_as,,1'                              # custom mode
[ -d '.git' ] && echo '-kcmd_grep,M-q,git grep --color=never -P -i -I -n %s 2>/dev/null'
command -v tableize &>/dev/null && echo '-kcmd_shell,M-x t,tableize 2>/dev/null'
echo '-nmle_as'
EOD

# write ~/bin/tableize
write_if_missing ~/bin/tableize 755 <<'EOD'
#!/usr/bin/env php
<?php
$all = rtrim(file_get_contents('php://stdin'));
$lines = explode("\n", $all);
$colw = [];
$negv = [];
$tabw = 0;
$table = [];
$opt = getopt('l:e:v:');
$climit = !empty($opt['l']) ? (int)$opt['l'] : -1;
$rmatch = !empty($opt['e']) ? "/{$opt['e']}/" : null;
$rfilter = !empty($opt['v']) ? "/{$opt['v']}/" : null;
foreach ($lines as $line) {
    $match = null;
    if ($rfilter && @preg_match($rfilter, $line)) {
        $table[] = rtrim($line, "\n");
    } else if ($rmatch && !@preg_match($rmatch, $line)) {
        $table[] = rtrim($line, "\n");
    } else if (preg_match('@^(\s*)(.+)$@', $line, $match)) {
        $tabw = max($tabw, strlen($match[1]));
        $row = preg_split('@\s+@', rtrim($match[2]), $climit);
        foreach ($row as $i => $col) {
            $negv[$i] = ($negv[$i] ?? 0) | (int)$col < 0 ? 1 : 0;
            $colw[$i] = max($colw[$i] ?? 1, strlen($col) + 1);
        }
        $table[] = $row;
    } else {
        $table[] = '';
    }
}
foreach ($table as $row) {
    if (is_string($row)) {
        echo $row;
    } else {
        echo str_repeat(' ', max(0, $tabw - $negv[0]));
        $colc = count($row);
        foreach ($row as $i => $col) {
            if ($negv[$i] && (int)$col >= 0) {
                $col = ' ' . $col;
            }
            if ($i === $colc - 1) {
                echo rtrim($col);
            } else {
                $w = $colw[$i] + $negv[$i];
                printf("%-{$w}s", $col);
            }
        }
    }
    echo "\n";
}
EOD

# write ~/.php_history
write_if_missing ~/.php_history <<'EOD'
EOD

# write ~/.lynx.cfg
write_if_missing ~/.lynx.cfg <<'EOD'
ACCEPT_ALL_COOKIES:TRUE
ASSUME_CHARSET:utf-8
CHARACTER_SET:utf-8
GLOBAL_EXTENSION_MAP:/etc/mime.types
GLOBAL_MAILCAP:
NO_PAUSE:TRUE
SCROLLBAR:TRUE
SHOW_CURSOR:TRUE
SSL_CERT_FILE:/etc/ssl/certs/ca-certificates.crt
STARTFILE:https://duckduckgo.com
UNDERLINE_LINKS:TRUE
EOD

# include .localbashrc
[ -f ~/.localbashrc ] && source ~/.localbashrc
