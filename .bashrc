#################### Ubuntu default stuff ####################

# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi



#################### My stuff ####################

# supported hosts:
# zen main nsto
# unsupported hosts:
# brubeck ndojo.nfshost.com nbs.nfshost.com
host=$(hostname)

##### Aliases #####

alias lsl='ls -lFhAb --color=auto --group-directories-first'
alias lsld='ls -lFhAbd --color=auto --group-directories-first'
alias trash='trash-put'
alias targ='tar -zxvpf'
alias tarb='tar -jxvpf'

alias awkt="awk -F '\t' -v OFS='\t'"
alias pingg='ping -c 1 google.com'
alias curlip='curl icanhazip.com'
alias vib='vim ~/.bashrc'
alias rsynca='rsync -e ssh --delete -zavXA'
alias kerb='kinit nick@BX.PSU.EDU'
alias temp="sensors | extract Physical 'Core 1' | sed 's/(.*)//' | grep -P '\d+\.\d'"
alias proxpn='cd ~/src/proxpn_mac/config; sudo openvpn --user me --config proxpn.ovpn'
alias mountf='mount | perl -we '"'"'printf("%-25s %-25s %-25s\n","Device","Mount Point","Type"); for (<>) { if (m/^(.*) on (.*) type (.*) \(/) { printf("%-25s %-25s %-25s\n", $1, $2, $3); } }'"'"''

alias minecraft='cd ~/src/minecraft; java -Xmx400M -Xincgc -jar /home/me/src/minecraft_server.jar nogui'
alias minelog='ssh vps "tail src/minecraft/server.log"'
alias mineme='ssh vps "cat src/minecraft/server.log" | grep -i nick | tail'
alias minelist="ssh vps 'screen -S minecraft -X stuff \"list
\"; sleep 1; tail src/minecraft/server.log'"
alias minemem='ssh vps "if pgrep -f java > /dev/null; then pgrep -f java | xargs ps -o %mem; fi"'


##### Functions #####

vix () {
  if [ -e $1 ]; then
    vim $1
  else
    touch $1; chmod +x $1; vim $1
  fi
}
calc () {
  python -c "from math import *; print $1"
}
wcc () { echo -n "$@" | wc -c; }
if [[ $host =~ (zen|main) ]]; then
  lgoog () {
    local query=$(echo "$@" | sed -r 's/ /+/g')
    lynx -dump http://www.google.com/search?q=$query
  }
fi
if [[ $host =~ (zen|main) ]]; then
  lc () { echo "$1" | lower.b; }
else
  lc () { echo "$1" | tr '[:upper:]' '[:lower:]'; }
fi
pg () {
    if pgrep -f $@ > /dev/null; then
        pgrep -f $@ | xargs ps -o user,pid,stat,rss,%mem,pcpu,args --sort -pcpu,-rss;
    fi
}
# readlink except it just returns the input path if it's not a link
deref () {
  local file="$1"
  if [ ! -e "$file" ]; then
    file=$(which "$file")
  fi
  local deref=$(readlink -f "$file")
  if [[ "$deref" ]]; then
    echo $deref
  else
    echo $1
  fi
}
# this requires deref()!
vil () { vi $(deref "$1"); }
getip () {
  # IPv6 too! (Only the non-MAC address-based one.)
  last=""
  ifconfig | while read line; do
    if [ ! "$last" ]; then
      dev=$(echo "$line" | sed -r 's/^(\S+)\s+.*$/\1/g')
    fi
    if [[ "$line" =~ 'inet addr' ]]; then
      echo -ne "$dev:\t"
      echo "$line" | sed -r 's/^\s*inet addr:\s*([0-9.]+)\s+.*$/\1/g'
    fi
    if [[ "$line" =~ 'inet6 addr' && "$line" =~ Scope:Global$ ]]; then
      ip=$(echo "$line" | sed -r 's/^\s*inet6 addr:\s*([0-9a-f:]+)[^0-9a-f:].*$/\1/g')
      if [[ ! "$ip" =~ ff:fe.*:[^:]+$ ]]; then
        echo -e "$dev:\t$ip"
      fi
    fi
    last=$line
  done
}
longurl () {
  url="$1"
  while [ "$url" ]; do
    echo "$url"
    echo -n "$url" | sed -r 's/^https?:\/\/([^/]+).*?\/?.*$/\1/g' | xclip -sel clip
    line=$(curl -sI "$url" | grep -P '^[Ll]ocation:\s' | head -n 1)
    url=$(echo "$line" | sed -r 's/^[Ll]ocation:\s+(\S.*\S)\s*$/\1/g')
  done
}
# Get totals of a specified column
sumcolumn () {
  if [ ! "$1" ] || [ ! "$2" ]; then
    echo 'USAGE: $ cutsum 3 file.csv'
    return
  fi
  awk -F '\t' '{ tot+=$'"$1"' } END { print tot }' "$2"
}
# Get totals of all columns in stdin or in all filename arguments
sumcolumns () {
  perl -we 'my @tot; my $first = 1;
  while (<>) {
    next if (m/[a-z]/i); # skip lines with non-numerics
    my @fields = split("\t");
    if ($first) { $first = 0; for my $field (@fields) { push(@tot, $field) }
    } else { for ($i = 0; $i < @tot; $i++) { $tot[$i] += $fields[$i] } }
  } print join("\t", @tot)."\n"'
}
showdups () {
  cat "$1" | while read line; do
    notfirst=''
    grep -n "^$line$" "$1" | while read line; do
      if [ "$notfirst" ]; then echo "$line"; else notfirst=1; fi
    done
  done
}
repeat () {
  if [[ $# -lt 2 ]] || ! [[ "$2" =~ ^[0-9]+$ ]]; then
    echo "USAGE: repeat [string] [number of repeats]" 1>&2
    return
  fi
  i=0; while [ $i -lt $2 ]; do
    echo -n "$1"; i=$((i+1))
  done
}
oneline () {
  echo "$1" | tr -d '\n'
}


##### Bioinformatics #####

alias rdp='java -Xmx1g -jar ~/bin/MultiClassifier.jar'
#alias qsh='source /home/me/src/qiime_software/activate.sh'
alias readsfa='grep -Pc "^>"'
readsfq () {
  local lines_tmp=$(wc -l $1 |  awk -F ' ' '{print $1}'); echo "$lines_tmp/4" | bc
}
gatc () {
  echo "$1" | sed -r 's/[^GATCNgatcn]//g'
}
revcomp () {
  echo "$1" | tr 'ATGCatgc' 'TACGtacg' | rev
}
mothur_report () {
  local total=$(readsfa "$1.fasta")
  local quality=$(readsfa "mothur-work/$1.trim.fasta")
  local dedup=$(readsfa "mothur-work/$1.trim.unique.fasta")
  echo -e "$total\t$quality\t$dedup"
  quality=$(echo "100*$quality/$total" | bc)
  dedup=$(echo "100*$dedup/$total" | bc)
  echo -e "100%\t$quality%\t$dedup%"
}



##### Other #####

# Stuff I don't want to post publicly on Github.
# Still should be universal, not machine-specific.
if [ -f ~/.bashrc_private ]; then
  source ~/.bashrc_private
fi

export PS1="\e[0;36m[\d]\e[m \e[0;32m\u@\h:\w\e[m\n\$ "
if [[ $host =~ (zen) ]]; then
  export PATH=$PATH:~/bin:~/bx/code
fi

# if it's a remote shell, change $PS1 prompt format and enter a screen
if [[ -n $SSH_CLIENT || -n $SSH_TTY ]]; then
  export PS1="[\d] \u@\h:\w\n\$ "
  # if not already in a screen, enter one (IMPORTANT to avoid infinite loops)
  if [[ ! $STY && ! $host =~ zen ]]; then
    export PATH=$PATH:~/bin
    exec screen -RR -S auto
  fi
fi
