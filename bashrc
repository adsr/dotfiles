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

# env prompt
ps1_color() {
    local color=32
    local prompt='$'
    if [ "$EUID" = 0 ]; then
        color=35
        prompt='#'
    elif { hostname -f | grep -Eq -e '^a[0-9]{4}' -e $'\x65\x74\x73\x79'; }; then
        color='38;5;208'
        prompt='$'
    fi
    echo "\[\033[01;${color}m\]\u\[\033[00;${color}m\]@\[\033[01;${color}m\]\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]${prompt} "
}
export PS1=$(ps1_color)
unset -f ps1_color

# env locale
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

# env go
export GOPATH=~/go

# env history
export HISTCONTROL=ignoredups
export HISTSIZE=1048576
export HISTFILESIZE=1048576

# env less
export LESS='-RXi -# 8'

# env lynx
export LYNX_CFG=~/.lynx.cfg

# env editor
for _e in mle vim nano; do
    command -v $_e &>/dev/null || continue
    export EDITOR="$_e"
    break
done
unset _e

# shell opts
shopt -s histappend
shopt -s checkwinsize

# aliases
alias ls='ls --color=auto'
alias ll='ls --color=auto -lF'
alias la='ls --color=auto -alF'
alias grep='grep --color=auto'
alias gg='git grep -iP'
alias bell='echo -e "\a"'
alias loc='echo "$(hostname -f):$(pwd)"'
alias ..='cd ..'
alias xcopy='xclip -sel c'
alias batt='cat /sys/class/power_supply/BAT0/capacity'
[ -f ~/.bash_aliases ] && source ~/.bash_aliases

# functions
ff()  { local IFS='*'; local patt="$*"; find . -iwholename "*${patt}*"; }
fd()  { local IFS='*'; local patt="$*"; find . -type d -iwholename "*${patt}*"; }
fo()  { ff "$@" | head -n1; }
fcd() { local d=$(fd "$@" | head -n1); [ -n "$d" ] && cd "$d"; }
fdd() { find "${@:-.}" -type d; }
fdf() { find "${@:-.}" -type f; }
up()  { local n=${1:-1} p='' i; for i in $(seq 1 "$n"); do p+='../'; done; cd "$p"; }
awkf() { awk -vf="${1:-1}" '{print $f}' "${2:--}"; }
ffplay_ts()  { ffplay -vf "drawtext=fontsize=40:text='%{pts\:hms}':box=1:x=0:y=h-lh" "$@"; }
ffplay_x11() { ffplay -select_region 1 -show_region 1 -f x11grab -i "${DISPLAY:-:0}"; }
pla() { _pl_all=1 pl "$@"; }
pll() { _pl_noh=1 pl "$@"; }
pl() {
    local forest; test -n "${_pl_noh:-}" || forest='-H'
    ps -A $forest -o user,pid,ppid,pgid,%cpu,%mem,vsz:8,rss:8,tty,stat,wchan:16,etime,args "$@" | \
        { { test -n "${_pl_all:-}" && cat; } || awk '$3!=2{print}'; } | less -S
}
screenall() {
    screen -X at \# stuff "$(echo -e "$*\r")"
}
dumpflow() {
    local OPTIND
    local iface='any'
    local hex=1
    while getopts ":ai:" opt; do
        case $opt in
            a) hex=0 ;;
            i) iface=$OPTARG ;;
            *) return 1 ;;
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
write_if() {
    local fname=$1
    local mode=${2:-}
    local dname=$(dirname "$fname")
    local yn
    if [ -n "${WRITEIF_INTERACTIVE:-}" ]; then
        local tmpf=$(mktemp)
        cat >"$tmpf"
        interactive_update "$fname" "$mode" "$tmpf"
        rm -f "$tmpf"
    else # write_if_missing
        [ -d "$dname" ] || return
        [ -f "$fname" ] && return
        cat >"$fname"
        [ -n "$mode" ] && chmod "$mode" "$fname"
    fi
}
mle_install() {(
    set -e
    local tmpdir=$(mktemp -d)
    pushd "$tmpdir"
    git clone --recursive 'https://github.com/adsr/mle.git'
    pushd mle
    make mle_vendor=1
    mkdir -vp "$HOME/bin"
    cp -vf mle "$HOME/bin"
    popd
    popd
    rm -rf "$tmpdir"
)}
interactive_update() {
    local target=$1
    local mode=$2
    local candidate=$3
    local target_dir=$(dirname "$target")
    local yn
    if [ ! -f "$candidate" ]; then
        return 1
    elif [ ! -d "$target_dir" ]; then
        echo; read -rp "Missing dir for ${target}. Create? [yN] >" yn </dev/tty
        [ "$yn" = y ] && mkdir -vp "$target_dir" || return 1
        yn=y
    elif [ -f "$target" ]; then
        diff -q "$target" "$candidate" &>/dev/null
        [ "$?" -eq 0 ] && { echo "No diff for ${target}"; return 1; }
        ( set -x; diff -u --color "$target" "$candidate" )
        echo; read -rp "Update ${target}? [yN] >" yn </dev/tty
    else
        yn=y
    fi
    if [ "$yn" = y ]; then
        cp -vf "$candidate" "$target"
        [ -n "$mode" ] && chmod "$mode" "$target"
        return 0
    fi
    return 1
}
bashrc_update() {
    local url='https://raw.githubusercontent.com/adsr/dotfiles/master/bashrc'
    local yn
    local tmpf=$(mktemp)
    wget -O "$tmpf" "$url" || { echo 'Failed'; return 1; }
    if interactive_update "${BASH_SOURCE[0]}" "$tmpf"; then
        echo; read -rp 'Reload? [yiN] >' yn
        if [[ "$yn" =~ ^[yi]$ ]]; then
            WRITEIF_INTERACTIVE=$(test "$yn" = i && printf 1 : printf '') \
                source "${BASH_SOURCE[0]}"
        fi
    fi
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
write_if ~/.screenrc <<'EOD'
crlf off
startup_message off
vbell off
bell_msg 'Bell in window %n^G'
defmonitor off
defutf8 on
nethack off
autodetach on
defscrollback 1048576
hardstatus alwayslastline
hardstatus string '%{= kw}[%H]  %-w[%{= dW}%n %t%{-}]%+w'
termcapinfo xterm* ti@:te@
term screen-256color
EOD

# write ~/.gdbinit
write_if ~/.gdbinit <<'EOD'
set history save on
add-auto-load-safe-path /home/adam/php-src/.gdbinit
define hexdump
  dump binary memory /tmp/gdb.hexdump $arg0 $arg0+$arg1
  shell hexdump -C /tmp/gdb.hexdump
  shell rm -f /tmp/gdb.hexdump
end
EOD

# write ~/.gitconfig
write_if ~/.gitconfig <<'EOD'
[user]
name = Adam Saponara
email = as@php.net
[include]
path = .localgitconfig
[github]
user = adsr
[alias]
br = branch
brt = branch --sort=-committerdate
brr = branch --sort=refname
chp = cherry-pick
ci = commit
co = checkout
df = diff
dfm = diff origin/master master
dfs = diff --staged
ll = log --pretty=format:"%C(yellow)%h%Cred%d\\ %Creset%s%Cblue\\ [%cn]" --decorate --numstat
l = log --graph --decorate
ls = log --pretty=format:"%C(yellow)%h\\ %ad%Cred%d\\ %Creset%s%Cblue\\ [%cn]" --decorate --date=short
praise = blame
rpop = "!git stash && git pull --rebase && git stash pop"
rpull = pull --rebase --stat
sm = submodule
spush = "!v=$(git remote get-url --push origin | perl -pe 's|^https?://([^/]+)/([^/]+)/(.*)$|git@\\1:\\2/\\3|g') && git push $v $(git rev-parse --abbrev-ref HEAD) && git rpull"
stp = status --porcelain
st = status
unci = reset --soft HEAD~1
un = reset
[status]
submoduleSummary = true
[diff]
algorithm = histogram
submodule = log
[color]
ui = auto
[core]
autocrlf = input
safecrlf = true
excludesfile = ~/.gitignore
preloadindex = true
[push]
default = current
[credential]
helper = cache --timeout=15552000
EOD

# write ~/.inputrc
write_if ~/.inputrc <<'EOD'
set enable-bracketed-paste off
set colored-completion-prefix on
set colored-stats on
set visible-stats on
EOD

# write ~/.wgetrc
write_if ~/.wgetrc <<'EOD'
check-certificate=off
EOD

# write ~/.mlerc
write_if ~/.mlerc 755 <<'EOD'
#!/bin/bash
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
echo '-Ssyn_diff,\.(diff|patch)$,4,0'           # syn_diff
echo '-s^\+.*,,3,0'
echo '-s^-.*,,2,0'
echo '-Kmle_as,,1'                              # custom mode
[ -d '.git' ] && echo '-kcmd_grep,M-q,git grep --color=never -P -i -I -n %s 2>/dev/null'
command -v tableize &>/dev/null && echo '-kcmd_shell,M-x t,tableize 2>/dev/null'
echo '-nmle_as'
EOD

# write ~/bin/tableize
write_if ~/bin/tableize 755 <<'EOD'
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

# write ~/bin/foldw
write_if ~/bin/foldw 755 <<'EOD'
#!/bin/bash
w=${1:-79}
cat | fold -s -w $w | sed -E 's/\s+$//g'
EOD

# write ~/.php_history
write_if ~/.php_history <<'EOD'
EOD

# write ~/.lynx.cfg
write_if ~/.lynx.cfg <<'EOD'
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

# write ~/.Xresources
write_if ~/.Xresources <<'EOD'
xterm*termName:        xterm-256color
xterm*background:      black
xterm*foreground:      gray80
xterm*metaSendsEscape: true
xterm*cursorBlink:     true
xterm*maximized:       true
xterm*bellIsUrgent:    true
xterm*scrollBar:       true
xterm*rightScrollBar:  true
xterm*faceName:        DejaVu Sans Mono
xterm*faceSize:        11
xterm*saveLines:       1048576
xterm*vt100.translations: #override \n\
    Ctrl Shift <Key>X: insert-selection(SELECT) \n\
    Ctrl Shift <Key>C: copy-selection(CLIPBOARD) \n\
    Ctrl Shift <Key>V: insert-selection(CLIPBOARD)
xterm*scrollbar.foreground: gray50
xterm*scrollbar.background: black
xterm*scrollbar.thumb:      black
xterm*scrollbar.width:      18
xterm*scrollbar.translations: #override \n\
    <Btn5Down>:   StartScroll(Forward) \n\
    <Btn1Down>:   StartScroll(Continuous) MoveThumb() NotifyThumb() \n\
    <Btn4Down>:   StartScroll(Backward) \n\
    <Btn1Motion>: MoveThumb() NotifyThumb() \n\
    <BtnUp>:      NotifyScroll(Proportional) EndScroll()
EOD

# write ~/bin/ahist
write_if ~/bin/ahist 755 <<'EOD'
#!/usr/bin/env php
<?php
$nrows = max(24, (int)shell_exec('tput lines'));
$nrows -= 4; // 1st prompt, 2nd prompt, screen status, +1 for good measure
$ncols = max(80, (int)shell_exec('tput cols'));
$buckets = array_reduce(
    ['second', 'minute', 'hour', 'day', 'week', 'month', 'year'],
    function ($a, $v) { $a[$v] = strtotime("+1 {$v}", 0); return $a; }
);
$opt = getopt('hi:s:Ff:g:v');
isset($opt['h']) && die("Usage: {$_SERVER['PHP_SELF']} -i <interval_str> -s <interval_s> -F(fill) -f <tfmt_out> -g <tfmt_in> -v(value_mode)\n");
$value_mode = isset($opt['v']);
$tformat_out = $opt['f'] ?? 'Y-m-d H:i:s';
$tformat_in = $opt['g'] ?? null;
$tmin = null;
$tmax = null;
$tseries = [];
while (($line = fgets(STDIN)) !== false) {
    if ($value_mode) {
        $ts = (int)$line;
    } else if ($tformat_in) try {
        $ats = date_parse_from_format($tformat_in, $line);
        $ts = mktime($ats['hour'], $ats['minute'], $ats['second'],
                     $ats['month'] ?: 1, $ats['day'] ?: 1, $ats['year']); // tz
    } catch (Exception $e) {
        continue;
    } else if (($ts = strtotime($line)) === false) {
        continue;
    }
    if ($tmin === null || $ts < $tmin) $tmin = $ts;
    if ($tmax === null || $ts > $tmax) $tmax = $ts;
    $tseries[] = $ts;
}
if (empty($tseries)) exit(0); // empty time series
$trange = $tmax - $tmin;
$tplus = match (true) {
    $value_mode => max(1, intdiv($trange, $nrows)),
    isset($opt['F']) => sprintf('+%d second', max(1, intdiv($trange, $nrows))),
    isset($opt['s']) => sprintf('+%d second', max(1, (int)$opt['s'])),
    isset($opt['i']) => sprintf('+%s', ltrim($opt['i'], '+')),
    default => sprintf('+1 %s', (function() use ($trange, $nrows, $buckets) {
        foreach ($buckets as $bucket => $bucket_s) {
            if (intdiv($trange, $bucket_s) > $nrows) continue;
            return $bucket;
        }
        return array_key_last($buckets);
    })()),
};
$tplus_fn = $value_mode
    ? (fn ($tsb) => $tsb + $tplus)
    : (fn ($tsb) => strtotime($tplus, $tsb));
sort($tseries, SORT_NUMERIC);
$tsb = null;
$tsb_next = $tseries[0];
$tsb_advance = function() use (&$tsb, &$tsb_next, $tplus_fn) {
    $tsb = $tsb_next !== null ? $tsb_next : $tplus_fn($tsb);
    $tsb_next = $tplus_fn($tsb);
    if ($tsb === $tsb_next || !is_int($tsb_next)) exit(1); // invalid tplus
};
$tsb_advance();
$hist = [];
foreach ($tseries as $ts) {
    while ($ts >= $tsb_next) $tsb_advance();
    $hist[$tsb] = ($hist[$tsb] ?? 0) + 1;
}
$vmin = min($hist);
$vmax = max($hist);
$tbmin = min(array_keys($hist));
$tbmax = max(array_keys($hist));
$vlen = strlen($vmax);
$tsflen = strlen($value_mode ? $tbmax : gmdate($tformat_out));
$vwidth = max($ncols - $vlen - 1 - $tsflen - 1, 1);
$vbucket = max(1.0, $vmax / $vwidth);
for ($tsb = $tbmin, $tsb_next = null; $tsb <= $tbmax; $tsb_advance()) {
    $v = $hist[$tsb] ?? 0;
    $nv = (int)round($v / $vbucket);
    $tsf = $value_mode ? sprintf("%{$tsflen}s", $tsb) : gmdate($tformat_out, $tsb);
    printf("%s %s %d\n", $tsf, str_repeat('#', $nv), $v);
}
EOD

# write ~/bin/descstat
write_if ~/bin/descstat 755 <<'EOD'
#!/bin/bash
read -r -d '' awk_program <<'EOE'
BEGIN                  { alen=0 }
/^\s*$/                { next }
/^[-+]?[0-9]*.?[0-9]*/ { a[alen++]=$0 }
END                    {
    if (alen<1) exit
    asort(a) # reindexes 1->n
    sum=0; for (i in a) sum+=a[i]
    mean=sum/alen
    var=0; for (i in a) var+=(a[i]-mean)^2
    var/=alen
    stddev=sqrt(var)
    min=a[1]
    max=a[alen]
    median=a[int(alen*0.50)]
    p95=a[int(alen*0.95)]
    p99=a[int(alen*0.99)]
    if (label) printf("%s: ", label)
    printf("n=%d min=%.3f max=%.3f mean=%.3f median=%.3f p95=%.3f p99=%.3f stddev=%.3f sum=%.3f\n",
            alen,min,     max,     mean,     median,     p95,     p99,     stddev,     sum)
}
EOE
awk -v "label=$1" "$awk_program"
EOD

# write ~/bin/qrcam2clip
write_if ~/bin/qrcam2clip 755 <<'EOD'
#!/bin/bash
set -euo pipefail
main() {
    trap cleanup EXIT
    tmpf="$(mktemp --suffix .png)"
    while true; do
        ffmpeg -y -f v4l2 -video_size 1280x720 -i /dev/video0 -update 1 -frames:v 1 "$tmpf" &>/dev/null
        out=$(ZXingReader -format QRCode -bytes "$tmpf" || true)
        test -n "$out" && xclip -sel c <<<"$out" && echo Copied && exit
        sleep 1
    done
}
cleanup() { test -n "$tmpf" && rm -f "$tmpf"; }
main "$@"
EOD

# include .localbashrc
[ -f ~/.localbashrc ] && source ~/.localbashrc
