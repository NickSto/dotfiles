##### Detect host #####

host=$(hostname -s 2>/dev/null || hostname)

# supported hosts:
# ruby main nsto2 ndojo nbs yarr brubeck scofield desmond nn[0-9]+ uniport lion cyberstar

# supported distros:
#   ubuntu debian freebsd
# partial support:
#   cygwin osx

# Are we on one of the cluster nodes?
in_cluster=
if echo $host | grep -qE '^nn[0-9]+$' && [[ ${host:2} -le 15 ]]; then
  in_cluster=true
fi

##### Determine distro #####

# Avoid unexpectd $CDPATH effects
# https://bosker.wordpress.com/2012/02/12/bash-scripters-beware-of-the-cdpath/
unset CDPATH

# Reliably get the actual parent dirname of a link (no readlink -f in BSD)
function realdirname {
  echo $(cd $(dirname $(readlink $1)) && pwd)
}

# Determine directory with .bashrc files
cd $HOME
if [[ -f .bashrc ]]; then
  # Is it a link or real file?
  if [[ -h .bashrc ]]; then
    bashrc_dir=$(realdirname .bashrc)
  else
    bashrc_dir="$HOME"
  fi
elif [[ -f .bash_profile ]]; then
  # Is it a link or real file?
  if [[ -h .bash_profile ]]; then
    bashrc_dir=$(realdirname .bash_profile)
  else
    bashrc_dir="$HOME"
  fi
else
  bashrc_dir="$HOME/code/dotfiles"
fi
cd - >/dev/null

# Set distro based on known hostnames
case "$host" in
  ruby)
    distro="ubuntu";;
  main)
    distro="ubuntu";;
  nsto2)
    distro="ubuntu";;
  yarr)
    distro="ubuntu";;
  ndojo)
    distro="freebsd";;
  nbs)
    distro="freebsd";;
  brubeck)
    distro="debian";;
  scofield)
    distro="debian";;
  *)  # Unrecognized host? Run detection script.
    source $bashrc_dir/detect-distro.sh
esac

# Get the kernel string if detect-distro.sh didn't.
if [[ ! $kernel ]]; then
  kernel=$(uname -s 2>/dev/null | tr '[:upper:]' '[:lower:]')
fi

# If we're in Tails, set $HOME to the USB drive with this bashrc on it.
if [[ $distro == tails ]]; then
  if [[ $host == localhost.localdomain ]]; then
    host=tails
  fi
  usb_drive=$(df $bashrc_dir | awk 'END {print $6}')
  if [[ $usb_drive ]]; then
    export HOME=$usb_drive
    cd $HOME
  fi
fi

# If we're in the webserver, cd to the webroot.
if [[ $host == nsto2 ]]; then
  cd /var/www/nstoler.com
fi



#################### System default stuff ####################


# All comments in this block are from Ubuntu's default .bashrc
if [[ $distro == ubuntu ]]; then

  # ~/.bashrc: executed by bash(1) for non-login shells.
  # examples: /usr/share/doc/bash/examples/startup-files (in package bash-doc)

  # make less more friendly for non-text input files, see lesspipe(1)
  [ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

  # enable programmable completion features (you don't need to enable
  # this if it's already enabled in /etc/bash.bashrc and /etc/profile
  # sources /etc/bash.bashrc).
  if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
      . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
      . /etc/bash_completion
    fi
  fi


# All comments in this block are from brubeck's default .bashrc
elif [[ $host == brubeck ]]; then

  # System wide functions and aliases
  # Environment stuff goes in /etc/profile

  # By default, we want this to get set.
  umask 002

  if ! shopt -q login_shell ; then # We're not a login shell
    if [ -d /etc/profile.d/ ]; then
      for i in /etc/profile.d/*.sh; do
        if [ -r "$i" ]; then
          . $i
        fi
      unset i
      done
    fi
  fi

  # system path augmentation
  test -f /afs/bx.psu.edu/service/etc/env.sh && . /afs/bx.psu.edu/service/etc/env.sh

  # make afs friendlier-ish
  if [ -d /afs/bx.psu.edu/service/etc/bash.d/ ]; then
    for file in /afs/bx.psu.edu/service/etc/bash.d/*.bashrc; do
    . $file
    done
  fi

fi

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi



#################### My stuff ####################


##### Bash options #####

# don't put duplicate lines or lines starting with space in the history.
HISTCONTROL=ignoreboth
HISTSIZE=2000       # max # of lines to keep in active history
HISTFILESIZE=2000   # max # of lines to record in history file
shopt -s histappend # append to the history file, don't overwrite it
# check the window size after each command and update LINES and COLUMNS.
shopt -s checkwinsize
# Make "**" glob all files and subdirectories recursively
# Does not exist in Bash < 4.0, so silently fail.
shopt -s globstar 2>/dev/null || true


### Environment variables ###

# Set directory for my special data files
data_dir="$HOME/.local/share/nbsdata"
# Set a default bx destination server
export LC_BX_DEST=bru
# Set my default text editor
export EDITOR=vim
# Allow disabling ~/.python_history.
# See https://unix.stackexchange.com/questions/121377/how-can-i-disable-the-new-history-feature-in-python-3-4
export PYTHONSTARTUP=~/.pythonrc


##### Aliases #####

if [[ $distro == ubuntu || $distro == cygwin || $distro == debian ]]; then
  alias ll='ls -lFhAb --color=auto --group-directories-first'
  alias lld='ls -lFhAbd --color=auto --group-directories-first'
else
  # long options don't work on FreeBSD or OS X
  alias ll='ls -lFhAb'
  alias lld='ls -lFhAbd'
fi
alias lsl=ll
alias lsld=lld
alias sll=sl # choo choo
alias mv='mv -i'
alias cp='cp -i'
alias targ='tar -zxvpf'
alias tarb='tar -jxvpf'
alias pseudo=sudo
alias vib="vim $bashrc_dir/.bashrc"
alias awkt="awk -F '\t' -v OFS='\t'"
function now {
  date +%s
}

alias pingg='ping -c 1 google.com'
alias curlip='curl -s icanhazip.com'
function cpu {
  ps aux | awk 'NR > 1 {cpu+=$3; mem+=$4} END {printf("%0.2f\t%0.2f\n", cpu/100, mem/100)}'
}
alias mem=cpu
if which totalmem.sh >/dev/null 2>/dev/null; then
  alias chrome='totalmem.sh -n Chrome /opt/google/chrome/'
  alias foxmem='totalmem.sh -n Firefox /usr/lib/firefox/'
fi
function geoip {
  curl http://freegeoip.net/csv/$1
}
if which longurl.py >/dev/null 2>/dev/null; then
  alias longurl='longurl.py -bc'
else
  function longurl {
    url=$(xclip -out -sel clip)
    echo "$url"
    curl -LIs "$url" | grep '^[Ll]ocation' | cut -d ' ' -f 2
  }
fi
if which trash-put >/dev/null 2>/dev/null; then
  alias trash=trash-put
else
  function trash {
    echo "No trash-cli found. Falling back to manual ~/.trash directory." >&2
    if ! [[ -d $HOME/.trash ]]; then
      if ! mkdir $HOME/.trash; then
        echo "Error creating ~/.trash" >&2
        return 1
      fi
    fi
    mv "$@" $HOME/.trash
  }
fi
function cds {
  if [[ "$1" ]]; then
    local n=$1
  else
    local n=5
  fi
  if [[ $n == 1 ]]; then
    if [[ $host == brubeck ]]; then
      cd /scratch/nick
    else
      cd /nfs/brubeck.bx.psu.edu/scratch1/nick
    fi
  elif [[ $n == 2 ]]; then
    if [[ $host == brubeck ]]; then
      cd /scratch2/nick
    else
      cd /nfs/brubeck.bx.psu.edu/scratch2/nick
    fi
  elif [[ $n -ge 3 ]]; then
    cd /nfs/brubeck.bx.psu.edu/scratch$n/nick
  fi
}
alias noheader='grep -v "^#"'
alias veramount="veracrypt -t --truecrypt -k '' --protect-hidden=no"
# Swap caps lock and esc.
alias swapkeys="loadkeys-safe.sh && sudo loadkeys $HOME/aa/computer/keymap-loadkeys.txt"
# If an .xmodmap is present, source it to alter the keys however it says. Disable with noremap=1.
# This is possibly obsoleted by the loadkeys method above.
if [[ -f ~/.xmodmap ]] && [[ -z $noremap ]]; then
  xmodmap ~/.xmodmap
fi
function kerb {
  local bx_realm="nick@BX.PSU.EDU"
  local galaxy_realm="nick@GALAXYPROJECT.ORG"
  local default_realm="$bx_realm"
  local realm="$1"
  if [[ $# -le 0 ]]; then
    realm="$default"
  elif [[ $1 == bx ]]; then
    realm="$bx_realm"
  elif [[ ${1:0:3} == bru ]]; then
    realm="$bx_realm"
  elif [[ ${1:0:3} == des ]]; then
    realm="$bx_realm"
  elif [[ ${1:0:3} == sco ]]; then
    realm="$galaxy_realm"
  elif [[ ${1:0:3} == gal ]]; then
    realm="$galaxy_realm"
  fi
  kinit -l 90d "$realm"
}
alias rsynca='rsync -e ssh --delete --itemize-changes -zaXAv'
function rsynchome {
  # If we can find the host "main", then we're on the same LAN (we're at home).
  if [[ $(dig +short main) ]]; then
    local dest='local'
  else
    local dest='home'
  fi
  if [[ -d $HOME/aa ]] && [[ -d $HOME/annex ]] && [[ -d $HOME/code ]]; then
    rsynca $HOME/aa/ $dest:/home/$USER/aa/ \
      && rsynca $HOME/annex/ $dest:/home/$USER/annex/ \
      && rsynca $HOME/code/ $dest:/home/$USER/code/
  else
    echo "Wrong set of directories exists. Is this the right machine?" >&2
  fi
}
function vnc {
  local delay=8
  (sleep $delay && vinagre localhost:0) &
  echo "starting ssh tunnel and vnc server, then client in $delay seconds.."
  echo "[Ctrl+C to exit]"
  ssh -t -L 5900:localhost:5900 home 'x11vnc -localhost -display :0 -ncache 10 -nopw' >/dev/null
}

alias minecraft="cd ~/src/minecraft && java -Xmx400M -Xincgc -jar $HOME/src/minecraft_server.jar nogui"
alias minelog='ssh vps "tail src/minecraft/server.log"'
alias mineme='ssh vps "cat src/minecraft/server.log" | grep -i nick | tail'
alias minelist="ssh vps 'screen -S minecraft -X stuff \"list\"; sleep 1; tail src/minecraft/server.log'"
alias minemem='ssh vps "if pgrep -f java >/dev/null; then pgrep -f java | xargs ps -o %mem; fi"'

if [[ $distro =~ (^osx$|bsd$) ]]; then
  alias psp="ps -o 'user,pid,ppid,%cpu,%mem,rss,tty,start,time,args'"
else # doesn't work in cygwin, but no harm
  alias psp="ps -o 'user,pid,ppid,%cpu,%mem,rss,tname,start_time,time,args'"
fi
if [[ $host == ndojo || $host == nbs ]]; then
  alias errlog='less +G /home/logs/error_log'
elif [[ $host == nsto2 ]]; then
  alias errlog='less +G /var/www/logs/error.log'
elif [[ $distro == ubuntu || $distro == debian ]]; then
  alias errlog='less +G /var/log/syslog'
fi
# Search all encodings for strings, raise minimum length to 5 characters
function stringsa {
  strings -n 5 -e s $1
  strings -n 5 -e b $1
  strings -n 5 -e l $1
}
alias temp="sensors | grep -A 3 '^coretemp-isa-0000' | tail -n 1 | awk '{print \$3}' | sed -E -e 's/^\+//' -e 's/\.[0-9]+//'"
alias mountv="sudo mount -t vboxsf -o uid=1000,gid=1000,rw shared $HOME/shared"
function mountf {
  mount | python -c "import sys
print 'Device                    Mount Point               Type'
for line in sys.stdin:
  fields = line.split()
  if len(fields) >= 5 and fields[1] == 'on' and fields[3] == 'type':
    print('{0:<25s} {2:<25s} {4:<25s}'.format(*fields))"
}
alias blockedips="grep 'UFW BLOCK' /var/log/ufw.log | sed -E 's/.* SRC=([0-9a-f:.]+) .*/\1/g' | sort -g | uniq -c | sort -rg -k 1"
alias bitcoin="curl -s 'https://api.coindesk.com/v1/bpi/currentprice.json' | jq .bpi.USD.rate_float | cut -d . -f 1"
if ! which git >/dev/null 2>/dev/null; then
  alias updaterc="wget 'https://raw.githubusercontent.com/NickSto/dotfiles/master/.bashrc' -O $bashrc_dir/.bashrc"
elif [[ $host == cyberstar || $distro =~ bsd$ ]]; then
  alias updaterc="cd $bashrc_dir && git pull && cd -"
else
  alias updaterc="git --work-tree=$bashrc_dir --git-dir=$bashrc_dir/.git pull"
fi
if [[ $host == main ]]; then
  alias logtail='~/bin/logtail.sh 100 | less +G'
  function logrep {
    cd ~/0utbox/annex/Work/PSU/Nekrutenko/misc/chatlogs/galaxy-lab && grep -r $@
  }
else
  alias logtail='ssh home "~/bin/logtail.sh 100" | less +G'
  function logrep {
    ssh home "cd ~/0utbox/annex/Work/PSU/Nekrutenko/misc/chatlogs/galaxy-lab && grep -r $*"
  }
fi


##### Functions #####

function silence {
  local Silence="$data_dir/SILENCE"
  if [[ $# -ge 1 ]] && [[ $1 == '-h' ]]; then
    echo "Usage: \$ silence [-u]
Toggles silence file $Silence
Prompts before unsilencing (unless -u is given). Returns 0 when silenced, 2 when unsilenced, and 1
on error." >&2
    return 1
  fi
  if [[ $# == 1 ]] && [[ $1 == '-u' ]] && ! [[ -f "$Silence" ]]; then
    echo "Error: -u given, but silence file doesn't exist. You're already unsilenced!" >&2
    return 1
  fi
  if [[ -f "$Silence" ]]; then
    if [[ $# -ge 1 ]] && [[ $1 == '-u' ]]; then
      rm -f "$Silence"
      echo "Unsilenced!"
      return 2
    else
      local response
      read -p "You're currently silenced! Type \"louden\" to unsilence! " response
      if [[ $response == 'louden' ]]; then
        rm -f "$Silence"
        echo "Unsilenced!"
        return 2
      else
        echo "Aborting!"
        return 1
      fi
    fi
  else
    touch "$Silence"
    echo "Silenced!"
  fi
}
if which tmpcmd.sh >/dev/null 2>/dev/null; then
  function crashpause {
    if [[ $# -ge 1 ]]; then
      if [[ $1 == '-h' ]]; then
        echo "Usage: \$ crashpause [time]" >&2
        return 1
      else
        local timeout="$1"
      fi
    else
      local timeout=2h
    fi
    sudo tmpcmd.sh -t $timeout 'service crashplan stop' 'service crashplan start'
  }
  if which dnsadd.sh >/dev/null 2>/dev/null; then
    function dnsadd {
      if [[ $# -lt 1 ]]; then
        echo "Usage: \$ dnsadd [domain.com]" >&2
        return 1
      fi
      sudo tmpcmd.sh -t 2h "dnsadd.sh add $1" "dnsadd.sh rm $1"
    }
  fi
fi
if [[ $host == ruby ]]; then
  # Log my current number of tabs to a file, for self-monitoring.
  # On my laptop, screw the tabs command for now. Never used it.
  function tabs {
    local LogFile=~/aa/computer/logs/tabs.tsv
    if [[ $# == 0 ]] || [[ $1 == '-h' ]]; then
      echo "Usage: \$ tabs main_tabs [all_tabs]
Log your current number of tabs, plus a timestamp, to $LogFile
Format is tab-delimited: unix timestamp, number of tabs in main window,
number of tabs in all windows, human-readable timestamp." >&2
      return 1
    fi
    if ! [[ -d $(dirname $LogFile) ]]; then
      echo "Error: Missing directory $(dirname $LogFile)" >&2
      return 1
    fi
    local timestamp=$(date +%s)
    local time_human=$(date -d @$timestamp)
    local main_tabs=$1
    local all_tabs=.
    if [[ $# -gt 1 ]]; then
      all_tabs=$2
    fi
    if [[ $main_tabs -gt 100 ]]; then
      echo "Dang, that's a lot of tabs."
    fi
    echo -e "$timestamp\t$main_tabs\t$all_tabs\t$time_human" >> $LogFile
  }
fi
function logip {
  local LogFile=~/aa/computer/logs/ips.tsv
  if [[ $1 == '-h' ]]; then
    echo "Usage: \$ logip [-f]
Log your current public IP address to $LogFile.
Uses icanhazip.com to get your IP address.
Add -f to force logging even when SILENCE is in effect." >&2
    return 1
  fi
  if [[ $1 != '-f' ]] && [[ -e "$data_dir/SILENCE" ]]; then
    echo "Error: SILENCE file exists ($data_dir/SILENCE). Add -f to override." >&2
    return 1
  fi
  local ip=$(curl -s icanhazip.com)
  if [[ $ip ]]; then
    echo $ip >> $LogFile
    echo echo $ip '>>' $LogFile
  else
    echo "Error: Failed getting IP address." >&2
  fi
}
function bak {
  local path="$1"
  if [[ ! "$path" ]]; then
    return 1
  fi
  path=$(echo "$path" | sed 's#/$##')
  cp -r "$path" "$path.bak"
}
# add to path **if it's not already there**
function pathadd {
  if [[ ! -d "$1" ]]; then return; fi
  # handle empty PATH
  if [[ ! "$PATH" ]]; then export PATH="$1"; return; fi
  local path=''
  for path in $(echo "$PATH" | tr ':' '\n'); do
    if [[ "$path" == "$1" ]]; then return; fi
  done
  PATH="$PATH:$1"
}
# subtract from path
function pathsub {
  local newpath=""
  local path=''
  for path in $(echo "$PATH" | tr ':' '\n'); do
    if [[ "$path" != "$1" ]]; then
      # handle empty path
      if [[ "$newpath" ]]; then
        newpath="$newpath:$path"
      else
        newpath="$path"
      fi
    fi
  done
  PATH="$newpath"
}
# a quick shortcut to placing a script in the ~/bin dir
# only if the system supports readlink -f (BSD doesn't)
if readlink -f / >/dev/null 2>/dev/null; then
  function bin {
    ln -s $(readlink -f $1) ~/bin/$(basename $1)
  }
fi
alias gitgraph='git log --oneline --abbrev-commit --all --graph --decorate --color'
alias gig='nohup giggle >/dev/null 2>/dev/null &'
function gitswitch {
  if [[ -f ~/.ssh/id_rsa-code ]]; then
    mv ~/.ssh/id_rsa-code{,.pub} ~/.ssh/keys && \
    mv ~/.ssh/keys/id_rsa-generic{,.pub} ~/.ssh && \
    echo "Switched to NickSto"
  elif [[ -f ~/.ssh/id_rsa-generic ]]; then
    mv ~/.ssh/id_rsa-generic{,.pub} ~/.ssh/keys && \
    mv ~/.ssh/keys/id_rsa-code{,.pub} ~/.ssh && \
    echo "Switched to Qwerty0"
  fi
}
function gitlast {
  local commits=1
  if [[ $# -ge 1 ]]; then
    if [[ $1 == '-h' ]]; then
      echo 'Usage: $ gitlast [num_commits]' >&2
      return 1
    else
      commits=$1
    fi
  fi
  git log --oneline -n $commits
}
function gitdiff {
  diff_num=1
  if [[ $# -ge 1 ]]; then
    if [[ $1 == '-h' ]]; then
      echo 'Usage: $ gitdiff [diff_num]
Show a diff for the last commit (between it and the previous).
Or, give a number for which diff before it to show (e.g. "2" gives the diff
between the 3rd and 2nd to last commits).' >&2
      return 1
    else
      diff_num=$1
    fi
  fi
  local commit1 commit2
  read commit2 commit1 <<< $(git log -n $((diff_num+1)) --pretty=format:%h | tail -n 2)
  git diff $commit1 $commit2
}
# no more "cd ../../../.." (from http://serverfault.com/a/28649)
function up {
  local d="";
  for ((i=1 ; i <= $1 ; i++)); do
    d=$d/..;
  done;
  d=$(echo $d | sed 's#^/##');
  if [ -z "$d" ]; then
    d=..;
  fi;
  cd $d
}
function vix {
  if [ -e $1 ]; then
    vim $1
  else
    touch $1; chmod +x $1; vim $1
  fi
}
function calc {
  if [[ $# -gt 0 ]]; then
    python3 -c "from math import *; print($*)"
  else
    python3 -i -c 'from math import *'
  fi
}
function wcc {
  if [[ $# == 0 ]]; then
    wc -c
  else
    echo -n "$@" | wc -c
  fi
}
function lgoog {
  if ! which lynx >/dev/null 2>/dev/null; then
    echo 'Error: lynx not installed!' >&2
    return 1
  fi
  local query=$(echo "$@" | sed -E 's/ /+/g')
  local output=$(lynx -dump "http://www.google.com/search?q=$query")
  local end=$(echo "$output" | grep -n '^References' | cut -f 1 -d ':')
  echo "$output" | head -n $((end-2))
}
function uc {
  if [[ $# -gt 0 ]]; then
    echo "$@" | tr '[:lower:]' '[:upper:]'
  else
    tr '[:lower:]' '[:upper:]'
  fi
}
if which lower.b >/dev/null 2>/dev/null; then
  function lc {
    if [[ $# -gt 0 ]]; then
      echo "$@" | lower.b
    else
      lower.b
    fi
  }
else
  function lc {
    if [[ $# -gt 0 ]]; then
      echo "$@" | tr '[:upper:]' '[:lower:]'
    else
      tr '[:upper:]' '[:lower:]'
    fi
  }
fi
function tc {
  python -c "import titlecase, sys
if len(sys.argv) > 1:
  line = ' '.join(sys.argv[1:])
  print titlecase.titlecase(line.lower())
else:
  for line in sys.stdin:
    sys.stdout.write(titlecase.titlecase(line.lower()))" $@
}
function pg {
  if pgrep -f $@ >/dev/null; then
    pgrep -f $@ | xargs ps -o user,pid,stat,rss,%mem,pcpu,args --sort -pcpu,-rss;
  fi
}
function parents {
  if [[ "$1" ]]; then
    local pid="$1"
  else
    local pid=$$
  fi
  while [[ "$pid" -gt 0 ]]; do
    ps -o comm="" -p $pid
    pid=$(ps -o ppid="" -p $pid)
  done
}
# readlink -f except it handles commands on the PATH too
function deref {
  local file="$1"
  if [ ! -e "$file" ]; then
    file=$(which "$file" 2>/dev/null)
  fi
  readlink -f "$file"
}
# this requires deref()!
function vil {
  vi $(deref "$1")
}
function venv {
  if [[ $# -ge 1 ]] && [[ $1 == '-h' ]]; then
    echo "Usage: \$ venv
Looks for a .venv directory in the current directory or its parents, and activates the first one it
finds." >&2
    return 1
  fi
  local dir=$(pwd)
  while ! [[ -d $dir/.venv ]] && [[ $dir != / ]]; do
    dir=$(dirname $dir)
  done
  if [[ $dir == / ]]; then
    echo "No .venv directory found." >&2
    return 1
  else
    echo "Activating virtualenv in $dir/.venv" >&2
  fi
  if [[ -f $dir/.venv/bin/activate ]]; then
    source $dir/.venv/bin/activate
  else
    echo "Error: no .venv/bin/activate file found." >&2
    return 1
  fi
}
function getip {
  if [[ $# -gt 0 ]]; then
    echo "Usage: \$ getip
Parse the ifconfig command to get your interface names, IP addresses, and MAC addresses.
Prints one line per interface, tab-delimited:
interface-name    MAC-address    IPv4-address    IPv6-address
Does not work on OS X (totally different ifconfig output)." >&2
    return 1
  fi
  ip addr | awk -v OFS='\t' '
# Get the interface name.
$1 ~ /^[0-9]:$/ && $2 ~ /:$/ {
  # If we'\''re at the interface name line, we either just started or just finished the previous
  # interface. If so, print the previous one.
  if (iface && (ipv4 || ipv6)) {
    print iface, mac, ipv4, ipv6
  }
  split($2, fields, ":")
  iface=fields[1]
  mac = ""
  ipv4 = ""
  ipv6 = ""
}
# Get the MAC address.
$1 == "link/ether" {
  mac = $2
}
# Get the IPv4 address.
$1 == "inet" && $5 == "scope" && $6 == "global" {
  split($2, fields, "/")
  ipv4=fields[1]
}
# Get the IPv6 address.
# "temporary" IPv6 addresses are the ones which aren'\''t derived from the MAC address:
# https://en.wikipedia.org/wiki/IPv6_address#Modified_EUI-64
$1 == "inet6" && $3 == "scope" && $4 == "global" && $5 == "temporary" {
  split($2, fields, "/")
  # Avoid private addresses:
  # https://serverfault.com/questions/546606/what-are-the-ipv6-public-and-private-and-reserved-ranges/546619#546619
  if (substr(fields[1], 1, 2) != "fd") {
    ipv6=fields[1]
  }
}
# Print the last interface.
END {
  if (iface && (ipv4 || ipv6)) {
    print iface, mac, ipv4, ipv6
  }
}'
}
alias getmac=getip
function getinterface {
  if [[ $# -gt 0 ]]; then
    echo "Usage: \$ getinterface
Print the name of the interface on the default route (like \"wlan0\" or \"wlp58s0\")" >&2
    return 1
  fi
  getip | awk '{print $1}'
}
function iprange {
  if which ipwraplib.py >/dev/null 2>/dev/null; then
    ipwraplib.py mask_ip $@ | tr -d "(',')" | tr ' ' '\n'
  fi
}
# Print a random, valid MAC address.
function randmac() {
  python -c "
import random
octets = []
octet = random.randint(0, 63)*4
octets.append('{:02x}'.format(octet))
for i in range(5):
  octet = random.randint(0, 255)
  octets.append('{:02x}'.format(octet))
print ':'.join(octets)"
}
function spoofmac() {
  local Usage="Usage: \$ spoofmac [mac]
Set your wifi MAC address to the given one, or a random one otherwise."
  if [[ $# -gt 0 ]]; then
    if [[ $1 == '-h' ]]; then
      echo "$Usage" >&2
      return 1
    elif echo $1 | grep -qE '[0-9A-Fa-f:]{17}'; then
      local mac=$1
    else
      echo "Error: Invalid MAC provided: \"$1\"." >&2
      echo "$Usage" >&2
      return 1
    fi
  else
    local mac=$(randmac)
  fi
  local wifi_iface=$(getip | grep -Eo '^wl\S+' | head -n 1)
  if ! [[ $wifi_iface ]]; then
    echo "Error: Cannot find your wifi interface name. Maybe it's off right now?" >&2
    return 1
  fi
  echo "Remember your current MAC address: "$(getip | awk '$1 == "'$wifi_iface'" {print $2}')
  echo "Setting your MAC to $mac. You'll probably have to toggle your wifi after this."
  sudo ip link set dev $wifi_iface down
  sudo ip link set dev $wifi_iface address $mac
  sudo ip link set dev $wifi_iface up
}
# What are the most common number of columns?
function columns {
  echo " totals|columns"
  awkt '{print NF}' $1 | sort -g | uniq -c | sort -rg -k 1
}
# Get totals of a specified column.
function sumcolumn {
  local Usage='Usage: $ sumcolumn 3 file.tsv [file2.tsv [file3.tsv [..]]]
       $ cat file.tsv | sumcolumn 2'
  if [[ $# -lt 1 ]] || [[ $1 == '-h' ]]; then
    echo "$Usage" >&2
    return 1
  fi
  local col=$1
  shift
  if ! echo $col | grep -qE '^[0-9]+$'; then
    echo "Error: column \"$col\" not an integer." >&2
    echo "$Usage" >&2
    return 1
  fi
  awk -F '\t' '{tot += $'$col'} END {print tot}' "$@"
}
# Get totals of all columns in stdin or in all filename arguments.
function sumcolumns {
  if [[ $# == 1 ]] && [[ $1 == '-h' ]]; then
    echo 'Usage: $ sumcolumns file.tsv [file2.tsv [file3.tsv [..]]]
       $ cat file.tsv | sumcolumns' >&2
    return 1
  fi
  awk -F '\t' -v OFS='\t' '
  {
    for (i = 1; i <= NF; i++) {
      totals[i] += $i
    }
  }
  END {
    for (i = 1; totals[i] != ""; i++) {
      printf("%d\t", totals[i])
    }
    print ""
  }' "$@"
}
function showdups {
  local line
  cat "$1" | while read line; do
    local notfirst=''
    grep -n "^$line$" "$1" | while read line; do
      if [ "$notfirst" ]; then echo "$line"; else notfirst=1; fi
    done
  done
}
function repeat {
  if [[ $# -lt 2 ]] || ! [[ "$2" =~ ^[0-9]+$ ]]; then
    echo "USAGE: repeat [string] [number of repeats]" 1>&2
    return
  fi
  local i=0
  while [ $i -lt $2 ]; do
    echo -n "$1"
    i=$((i+1))
  done
}
function oneline {
  if [[ $# == 0 ]]; then
    tr -d '\n'
  else
    echo "$@" | tr -d '\n'
  fi
}
function wifimac {
  iwconfig 2> /dev/null | sed -nE 's/^.*access point: ([a-zA-Z0-9:]+)\s*$/\1/pig'
}
function wifissid {
  iwconfig 2> /dev/null | sed -nE 's/^.*SSID:"(.*)"\s*$/\1/pig'
}
function wifiip {
  getip | awk 'substr($1, 1, 2) == "wl" {print $3}'
}
function inttobin {
  echo "obase=2;$1" | bc
}
function bintoint {
  echo "ibase=2;obase=1010;$1" | bc
}
function inttohex {
  echo "obase=16;$1" | bc
}
function hextoint {
  # Input numbers in bc have to be in uppercase.
  in=$(echo $1 | tr [:lower:] [:upper:])
  echo "ibase=16;obase=A;$in" | bc
}
function asciitobin {
  python -c "print bin(ord('$1'))[2:]"
}
function bintoascii {
  if [[ $# != 1 ]] || [[ $1 == '-h' ]]; then
    echo 'Usage: bintoascii 011011010111010101100101011100100111010001100101' >&2
    return 1
  fi
  for i in $(seq 0 8 ${#1}); do
    echo -n $(python -c "print chr($((2#${1:$i:8})))")
  done
  echo
}
function title {
  if [[ $# == 1 ]] && [[ $1 == '-h' ]]; then
    echo 'Usage: $ title [New terminal title]
Default: "Terminal"' >&2
    return 1
  fi
  if [[ $# == 0 ]]; then
    TITLE="$host"
  else
    TITLE="$@"
  fi
  echo -ne "\033]2;$TITLE\007"
}
# I keep typing this for some reason.
alias tilte=title
# Convert a number of seconds into a human-readable time string.
# Example output: "1 year 33 days 2:43:06"
function human_time {
  local sec_total=$1
  local sec=$((sec_total % 60))
  local min_total=$((sec_total/60))
  local min=$((min_total % 60))
  local hr_total=$((min_total/60))
  local hr=$((hr_total % 24))
  local days_total=$((hr_total/24))
  local days=$((days_total % 365))
  local years_total=$((days_total/365))
  if [[ $days == 1 ]]; then
    local days_str='1 day '
  else
    local days_str="$days days "
  fi
  if [[ $years_total == 1 ]]; then
    local years_str='1 year '
  else
    local years_str="$years_total years "
  fi
  local hr_str="$hr:"
  local min_str="$min:"
  local sec_str=$sec
  if [[ $min -lt 10 ]] && [[ $min_total -ge 60 ]]; then
    min_str="0$min:"
  fi
  if [[ $sec -lt 10 ]] && [[ $sec_total -ge 60 ]]; then
    sec_str="0$sec"
  fi
  if [[ $years_total == 0 ]]; then
    years_str=''
    if [[ $days == 0 ]]; then
      days_str=''
      if [[ $hr == 0 ]]; then
        hr_str=''
        if [[ $min == 0 ]]; then
          min_str=''
          if [[ $sec == 0 ]]; then
            sec_str='0'
          fi
        fi
      fi
    fi
  fi
  echo "$years_str$days_str$hr_str$min_str$sec_str"
}


##### Bioinformatics #####

if [[ $host == ruby || $host == main ]]; then
  true #alias igv='java -Xmx4096M -jar ~/bin/igv.jar'
elif [[ $host == nsto2 ]]; then
  alias igv='java -Xmx256M -jar ~/bin/igv.jar'
else
  alias igv='java -jar ~/bin/igv.jar'
fi
alias seqlen="bioawk -c fastx '{ print \$name, length(\$seq) }'"
# alias rdp='java -Xmx1g -jar ~/bin/MultiClassifier.jar'
alias gatk="java -jar ~/bin/GenomeAnalysisTK.jar"
#alias qsh='source $HOME/src/qiime_software/activate.sh'
alias readsfa='grep -Ec "^>"'
if ! which readsfq >/dev/null 2>/dev/null; then
  function readsfq {
    echo "$(wc -l $1 |  cut -f 1 -d ' ')/4" | bc
  }
fi
alias bcat="samtools view -h"
function align {
  local opts_default='-M -t 32'
  if [[ $# -lt 3 ]]; then
    echo "Usage: \$ align ref.fa reads_1.fq reads_2.fq [--other --bwa --options]
If you provide your own options, yours will replace the defaults ($opts_default)." 1>&2
    return 1
  fi
  local ref fastq1 fastq2 opts
  read ref fastq1 fastq2 opts <<< $@
  if ! [[ $opts ]]; then
    opts="$opts_default"
  fi
  local base=$(echo $fastq1 | sed -E -e 's/\.gz$//' -e 's/\.fa(sta)?$//' -e 's/\.f(ast)?q$//' -e 's/_[12]$//')
  bwa mem $opts $ref $fastq1 $fastq2 > $base.sam
  samtools view -Sbu $base.sam | samtools sort - $base
  samtools index $base.bam
  echo "Final alignment is in: $base.bam"
}
# Print random DNA.
function dna {
  length=200
  if [[ $# -gt 0 ]]; then
    if [[ $1 == '-h' ]]; then
      echo 'Usage: $ dna [nbases]
Default number of bases: '$length >&2
      return 1
    fi
    length=$1
  fi
  python -c "import random
LINE_LENGTH = 100
bases = []
for i in range($length):
  bases.append(random.choice('ACGT'))
  if i % LINE_LENGTH == LINE_LENGTH - 1:
    print(''.join(bases))
    bases = []
if bases:
  print(''.join(bases))"
}
function gatc {
  if [[ $# -gt 0 ]]; then
    echo "$1" | sed -E 's/[^GATCNgatcn]//g';
  else
    local data
    while read data; do
      echo "$data" | sed -E 's/[^GATCNgatcn]//g';
    done;
  fi
}
function revcomp {
  if [[ $# == 0 ]]; then
    tr 'ATGCatgc' 'TACGtacg' | rev
  else
    echo "$1" | tr 'ATGCatgc' 'TACGtacg' | rev
  fi
}
function seqdiff {
  if [[ "$#" != 2 ]]; then
    echo "Usage: seqdiff GATTACA GATTANA" >&2
    return 1
  fi
  echo "$1" | fold -w 1 \
    | paste - <(echo "$2" | fold -w 1) \
    | awk '{printf("%4d  %s  %s", NR, $1, $2); if ($1 != $2) {printf("  !")} printf("\n")}'
}
function dotplot {
  if [[ $# -lt 3 ]]; then
    echo "Usage: dotplot seq1.fa seq2.fa output.jpg" >&2 && return
  fi
  if [[ -e "$3.tmp.pdf" ]]; then
    echo "Error: $3.tmp.pdf exists" >&2 && return
  fi
  if ! which dotter >/dev/null 2>/dev/null || ! which convert >/dev/null 2>/dev/null; then
    echo 'Error: "dotter" and "convert" commands required.' >&2 && return
  fi
  dotter "$1" "$2" -e "$3.tmp.pdf"
  convert -rotate 90 -density 400 -resize 50% "$3.tmp.pdf" "$3"
  rm -f "$3.tmp.pdf"
}
# Get some quality stats on a BAM using samtools
function bamsummary {
  function _pct {
    python -c "print 100.0*$1/$2"
  }
  function _print_stat {
    local len=$((${#2}+1))
    printf "%-30s%6.2f%% % ${len}d\n" "$1:" $(_pct $3 $2) $3
  }
  for bam in $@; do
    echo -e "\t$bam:"
    local total=$(samtools view -c $bam)
    printf "%-39s%d\n" "total alignments:" $total
    _print_stat "unmapped reads  (-f 4)" $total $(samtools view -c -f 4 $bam)
    _print_stat "not proper pair (-F 2)" $total $(samtools view -c -F 2 $bam)
    _print_stat "  MAPQ 0 alignments" $total  $(echo $total-$(samtools view -c -q 1 $bam) | bc)
    _print_stat "< MAPQ 20 alignments" $total $(echo $total-$(samtools view -c -q 20 $bam) | bc)
    _print_stat "< MAPQ 30 alignments" $total $(echo $total-$(samtools view -c -q 30 $bam) | bc)
    _print_stat "2ndary alignments   (-f 256)"  $total $(samtools view -c -f 256 $bam)
    _print_stat "chimeric alignments (-f 2048)" $total $(samtools view -c -f 2048 $bam)
    _print_stat "ambiguous alignments" $total $(samtools view $bam | awk -F '\t' '$5 == 0' | grep -c -E $'\t''XA:Z:')
  done
  unset -f _pct
  unset -f _print_stat
}
function citegrep {
  KeyDefault="doi"
  LibraryDefault="$HOME/bx/communication/anton-papers-db.bib"
  if [[ $# -lt 1 ]] || [[ $1 == '-h' ]]; then
    echo "Usage: citegrep Cai:2015kc [key [library.bib]]
Search a bibtex reference library for an identifier like \"Wan:2015ih\" or \"Schirmer:2015cy\".
Default key: $KeyDefault
Default library: $LibraryDefault" >&2
    return 1
  fi
  id="$1"
  key="$KeyDefault"
  library="$LibraryDefault"
  if [[ $# -ge 2 ]]; then
    key="$2"
  fi
  if [[ $# -ge 3 ]]; then
    library="$3"
  fi
  # If the python script is available, just use that (it's much better and more accurate).
  if which text-to-refs.py >/dev/null 2>/dev/null; then
    text-to-refs.py -i "$id" -k "$key" -l "$library"
    return
  fi
  line=$(grep -En "^@[^{]+\{$id\," "$library" | cut -d : -f 1 | head -n 1)
  if ! [[ $line ]]; then
    echo "Error: Citation \"$id\" not found." >&2
    return 1
  fi
  tail -n +$line "$library" | sed -En 's/^'$key'\s*=\s*\{+(.+)\}+[^}]*$/\1/p' | sed -E -e 's/\}+\s*$//' -e 's/^\s*\{+//' | head -n 1
}
if [[ $host == scofield ]]; then
  aklog bx.psu.edu
fi
# Make it easier to run a command from a Docker container, auto-mounting the current directory so
# it's accessible from inside the container.
alias dockdir='docker run -v $(pwd):/dir/'
# Slurm commands
if [[ $host == ruby ]]; then
  alias sfree='ssh bru sinfo -h -p general -t idle -o %n'
  alias scpus="ssh bru 'sinfo -h -p general -t idle,alloc -o "'"'"%n %C"'"'"' | tr ' /' '\t\t' | cut -f 1,3 | sort -k 1.3g"
  alias squeue='ssh bru squeue'
  alias squeuep="ssh bru 'squeue -o "'"'"%.7i %Q %.8u %.8T %.10M %11R %4h %j"'"'"' | sort -g -k 2"
else
  alias sinfoc='sinfo -p general -o "%11T %.5D %.15C %.15N"'
  alias sfree='sinfo -h -p general -t idle -o %n'
  alias scpus="echo -e 'Node\tFree\tTotal' && sinfo -h -p general -t idle,alloc -o '%n %C' \
                 | tr ' /' '\t\t' | cut -f 1,3,5 | sort -k 1.3g | sed -E 's/\.c\.bx\.psu\.edu//'"
  alias squeuep='squeue -o "%.7i %Q %.8u %.8T %.10M %11R %4h %j" | sort -g -k 2'
  function sgetnode {
    node_arg='-C new'
    max_cpus=0
    local node cpus
    while read node cpus; do
      if [[ $cpus -gt $max_cpus ]]; then
        max_cpus=$cpus
        node_arg="-w $node"
      fi
    done < <(sinfo -h -p general -t idle,alloc -o '%n %C' | tr ' /' '\t\t' | cut -f 1,3)
    echo "$node_arg"
  }
  function snice {
    local SlurmUser=nick
    if [[ $# -lt 1 ]] || [[ $1 == '-h' ]]; then
      echo "Usage: snice priority_diff [user]
Lower the priorities of all your jobs by priority_diff
Default user: $SlurmUser." >&2
      return 1
    fi
    local prio_diff=$1
    local user=$SlurmUser
    if [[ $# -ge 2 ]]; then
      local user=$2
    fi
    local jobid prio
    squeue -h -u $user -t PD -o '%.7i %Q' | while read jobid prio; do
      local new_prio=$((prio - prio_diff))
      scontrol update jobid=$jobid Priority=$new_prio
    done
  }
  function sdefer {
    local SlurmUser=nick
    if [[ $# -lt 1 ]] || [[ $1 == '-h' ]]; then
      echo "Usage: sdefer priority_num [user]
Moves all your pending jobs down in priority so that the highest priority queued job is priority_num
below the lowest priority running job.
Basically, let others start priority_num jobs before starting any more of yours.
Default user is $SlurmUser." >&2
      return 1
    fi
    local prio_num=$1
    local user=$SlurmUser
    if [[ $# -ge 2 ]]; then
      local user=$2
    fi
    # Choose lower of 1) lowest priority currently running job and 2) highest priority queued job.
    local running_prio=$(squeue -h -t R -o %Q | sort -g | head -n 1)
    local queued_prio=$(squeue -h -t PD -o %Q | sort -g | tail -n 1)
    if [[ $running_prio -lt $queued_prio ]]; then
      local lowest_prio=$running_prio
    else
      local lowest_prio=$queued_prio
    fi
    local highest_queued_prio=$(squeue -h -u $user -t PD -o %Q | head -n 1)
    local prio_diff=$((highest_queued_prio - lowest_prio + prio_num))
    echo "Highest priority in your queue:               $highest_queued_prio"
    echo "min(lowest running, highest queued) priority: $lowest_prio"
    echo "Difference:                                   $((highest_queued_prio - lowest_prio))"
    echo "Lowering all your queued jobs by:             $prio_diff"
    snice $prio_diff $user
  }
fi


##### PS1 prompt #####

# color red on last command failure
function prompt_exit_color {
  if [[ $? == 0 ]]; then
    if [[ "$remote" ]]; then
      pecol='0;30m' # black
    else
      pecol='0;36m' # teal
    fi
  else # if error
    pecol='0;31m' # red
  fi
}
# Set the window title, if needed.
function prompt_set_title {
  if ! [[ $TITLE ]]; then
    return
  fi
  local last_cmdline=$(history 1)
  local last_cmd=$(printf "%s" "$last_cmdline" | awk '{print $2}')
  if [[ $last_cmd == ssh ]] || [[ ${last_cmd:0:7} == ipython ]]; then
    title "$TITLE"
  elif [[ ${last_cmd:0:6} == python ]] &&
       [[ $(printf "%s" "$last_cmdline" | awk '{print $3,$4}') == "manage.py shell" ]]; then
    title "$TITLE"
  fi
}
# Gather info on the git repo, if we're in one.
# This is all in one function so we only run the git command once
# (could take a while in large repos).
function prompt_git_info {
  pgcol='0;32m' # cyan
  ps1_branch=
  local info=$(git status --porcelain --branch 2>/dev/null)
  if ! [[ "$info" ]]; then
    return
  fi
  # Color the prompt differently if there are modified, tracked files.
  if echo "$info" | grep -qE '^ M'; then
    pgcol='0;33m' # yellow
  fi
  # Show the branch if we're not on "master".
  local branch=$(echo "$info" | head -n 1 | sed -E -e 's/^## //' -e 's/^(.+)\.\.\..*$/\1/')
  if [[ $branch != master ]]; then
    ps1_branch="$branch "
  fi
}
# timer from https://stackoverflow.com/a/1862762/726773
timer_thres=10
function timer_start {
  # $SECONDS is a shell built-in: the total number of seconds it's been running.
  timer=${timer:-$SECONDS}
}
function timer_stop {
  local seconds=$(($SECONDS - $timer))
  ps1_timer_show=''
  if [[ $seconds -ge $timer_thres ]]; then
    ps1_timer_show="$(time_format $seconds) "
  fi
  unset timer
}
# format a number of seconds into a readable time
function time_format {
  local seconds=$1
  local minutes=$(($seconds/60))
  local hours=$(($minutes/60))
  seconds=$(($seconds - $minutes*60))
  minutes=$(($minutes - $hours*60))
  if [[ $minutes -lt 1 ]]; then
    echo $seconds's'
  elif [[ $hours -lt 1 ]]; then
    echo $minutes'm'$seconds's'
  else
    echo $hours'h'$minutes'm'
  fi
}
trap 'timer_start' DEBUG
# $PROMPT_COMMAND is a shell built-in which is executed just before $PS1 is displayed.
PROMPT_COMMAND='prompt_exit_color;prompt_set_title;prompt_git_info;timer_stop'


##### Things to execute directly on session start #####

# Stuff I don't want to post publicly on Github. Still should be universal, not
# machine-specific.
if [ -f ~/.bashrc_private ]; then
  source ~/.bashrc_private
fi

# add correct bin directory to PATH
if [[ $host == scofield ]]; then
  pathadd /galaxy/home/$USER/bin
elif [[ $in_cluster ]]; then
  true  # inherited from scofield
else
  pathadd ~/bin
fi
if [[ $host == lion ]]; then
  pathadd /opt/local/bin
fi
if [[ $host == ruby ]]; then
  pathadd $HOME/bx/bin
fi
pathadd /sbin
pathadd /usr/sbin
pathadd /usr/local/sbin
pathadd $HOME/.local/bin
# Add the Conda root environment bin directory last, so other versions are preferred.
if [[ -d $HOME/src/miniconda2/bin ]]; then
  pathadd $HOME/src/miniconda2/bin
fi

# a more "sophisticated" method for determining if we're in a remote shell
# check if the system supports the right ps parameters and if parents is able to
# climb the entire process hierarchy
if ps -o comm="" -p 1 >/dev/null 2>/dev/null && [[ $(parents | tail -n 1) == "init" ]]; then
  for process in $(parents); do
    if [[ $process == sshd || $process == slurmstepd ]]; then
      remote="true"
    fi
  done
else
  if [[ -n $SSH_CLIENT || -n $SSH_TTY ]]; then
    remote="true"
  fi
fi

ROOTPS1="\e[0;31m[\d] \u@\h: \w\e[m\n# "
# Retitle window only if it's an interactive session. Otherwise, this can cause scp to hang.
if [[ $- == *i* ]] && [[ $host != uniport ]]; then
  title $host
fi

# If it's a remote shell, change $PS1 prompt format and enter a screen.
if [[ $remote ]]; then
  export PS1='${ps1_timer_show}\e[${pecol}[\d]\e[m \u@\h: \w\n$ps1_branch\$ '
  # Enter a screen, UNLESS:
  # 1. ! "$STY": We're already in a screen (IMPORTANT to avoid infinite loops).
  # 2. -t 1: We're not attached to a real terminal.
  # 3. $LC_NO_SCREEN != true: The user has requested not to enter a screen.
  #    - Set via: $ LC_NO_SCREEN=true ssh -o SendEnv=LC_NO_SCREEN me@destination
  # 4. ! -f ~/NOSCREEN: The user has requested not to enter a screen (backup method).
  if ! [[ "$STY" ]] && [[ -t 1 ]] && [[ $LC_NO_SCREEN != true ]] && ! [[ -f ~/NOSCREEN ]]; then
    if [[ $host == uniport ]] || [[ $host == ndojo ]] || [[ $host == nbs ]] || [[ $in_cluster ]]; then
      true  # screen unavailable or undesired
    elif [[ $host == brubeck || $host == scofield || $host == desmond ]] \
        && [[ -x ~/code/pagscr-me.sh ]]; then
      exec ~/code/pagscr-me.sh -RR -S auto
    elif which screen >/dev/null 2>/dev/null; then
      exec screen -RR -S auto
    fi
  fi
else
  export PS1='$ps1_timer_show\e[$pecol[\d]\e[m \e[0;32m\u@\h:\e[m \e[$pgcol\w\e[m\n$ps1_branch\$ '
fi
