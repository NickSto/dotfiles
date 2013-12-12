#TODO: make all relevant functions work on stdin too
##### Detect host #####

# supported hosts:
# zen main nsto yarr brubeck ndojo.nfshost.com nbs.nfshost.com
# partial support:
# vbox (cygwin)
host=$(hostname)


##### Detect distro #####

if [[ $host =~ (zen|main|nsto|yarr) ]]; then
  distro="ubuntu"
elif [[ $host =~ (nfshost) ]]; then
  distro="freebsd"
elif [[ $host =~ (brubeck) ]]; then
  distro="debian"
elif [[ $host =~ (vbox) ]]; then
  distro="cygwin"
# Do your best to detect the distro
# Uses info from http://www.novell.com/coolsolutions/feature/11251.html
# and http://en.wikipedia.org/wiki/Uname
else
  kernel=$(uname -s | tr '[:upper:]' '[:lower:]')
  if [[ $kernel =~ freebsd ]]; then
    distro="freebsd"
  elif [[ $kernel =~ bsd$ ]]; then
    distro="bsd"
  elif [[ $kernel =~ darwin ]]; then
    distro="mac"
  elif [[ $kernel =~ cygwin ]]; then
    distro="cygwin"
  elif [[ $kernel =~ mingw ]]; then
    distro="mingw"
  elif [[ $kernel =~ sunos ]]; then
    distro="solaris"
  elif [[ $kernel =~ haiku ]]; then
    distro="haiku"
  elif [[ $kernel =~ linux ]]; then
    if [ -f /etc/os-release ]; then
      distro=$(grep '^NAME' /etc/os-release | sed -E 's/^NAME="([^"]+)"$/\1/g' | tr '[:upper:]' '[:lower:]')
    fi
    if [[ ! $distro ]]; then
      distro=$(ls /etc/*-release | sed -E 's#/etc/([^-]+)-release#\1#' | head -n 1)
    fi
    if [[ ! $distro ]]; then
      if [ -f /etc/debian_version ]; then
        distro="debian"
      elif [ -f /etc/redhat_version ]; then
        distro="redhat"
      elif [ -f /etc/slackware-version ]; then
        distro="slackware"
      fi
    fi
    if [[ ! $distro ]]; then
      distro="linux"
    fi
  else
    distro="unknown"
  fi
fi



#################### System default stuff ####################


# All comments in this block are from Ubuntu's default .bashrc
if [[ $distro == "ubuntu" ]]; then

  # ~/.bashrc: executed by bash(1) for non-login shells.
  # examples: /usr/share/doc/bash/examples/startup-files (in package bash-doc)

  # If not running interactively, don't do anything
  case $- in
      *i*) ;;
        *) return;;
  esac

  # make less more friendly for non-text input files, see lesspipe(1)
  [ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

  # "alert" Sends notify-send notification with exit status of last command
  alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

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
elif [[ $distro == "debian" ]]; then

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

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'



#################### My stuff ####################


home=$(echo $HOME | sed -E 's#/$##g')
if [[ $host =~ (zen|main) ]]; then
  bashrc_dir="$home/aa/code/bash/bashrc"
else # known location for nsto, brubeck, nfshost, vbox, yarr
  bashrc_dir="$home/code/bashrc"
fi


##### Bash options #####

# don't put duplicate lines or lines starting with space in the history.
HISTCONTROL=ignoreboth
HISTSIZE=2000       # max # of lines to keep in active history
HISTFILESIZE=2000   # max # of lines to record in history file
shopt -s histappend # append to the history file, don't overwrite it
# check the window size after each command and update LINES and COLUMNS.
shopt -s checkwinsize
# Make "**" glob all files and subdirectories recursively
shopt -s globstar


##### Aliases #####

if [[ $distro =~ (ubuntu|cygwin|debian) ]]; then
  alias lsl='ls -lFhAb --color=auto --group-directories-first'
  alias lsld='ls -lFhAbd --color=auto --group-directories-first'
else
  # long options don't work on nfshost (freebsd)
  alias lsl='ls -lFhAb'
  alias lsld='ls -lFhAbd'
fi
alias sll='sl' # choo choo
alias mv="mv -i"
alias cp="cp -i"
alias trash='trash-put'
alias targ='tar -zxvpf'
alias tarb='tar -jxvpf'

alias awkt="awk -F '\t' -v OFS='\t'"
alias pingg='ping -c 1 google.com'
alias curlip='curl icanhazip.com'
geoip () { curl http://freegeoip.net/csv/$1; }
if [[ $host =~ (nfshost) || $distro =~ bsd$ ]]; then
  alias vib='vim ~/.bash_profile'
else
  alias vib='vim ~/.bashrc'
fi
if [[ $host =~ (brubeck) ]]; then
  alias cds='cd /scratch2/nick'
fi
alias kerb='kinit nick@BX.PSU.EDU'
alias rsynca='rsync -e ssh --delete --itemize-changes -zaXAv'
alias rsynchome='rsync -e ssh -zaXAv --itemize-changes --delete /home/me/aa/ home:/home/me/aa/ && rsync -e ssh -zaXAv --itemize-changes --delete /home/me/annex/ home:/home/me/annex/'
alias swapkeys="loadkeys-safe.sh && sudo loadkeys $HOME/aa/misc/computerthings/keymap-loadkeys.txt"

alias minecraft="cd ~/src/minecraft && java -Xmx400M -Xincgc -jar $home/src/minecraft_server.jar nogui"
alias minelog='ssh vps "tail src/minecraft/server.log"'
alias mineme='ssh vps "cat src/minecraft/server.log" | grep -i nick | tail'
alias minelist="ssh vps 'screen -S minecraft -X stuff \"list
\"; sleep 1; tail src/minecraft/server.log'"
alias minemem='ssh vps "if pgrep -f java >/dev/null; then pgrep -f java | xargs ps -o %mem; fi"'

if [[ $host =~ (nfshost) || $distro =~ bsd$ ]]; then
  alias psp="ps -o 'user,pid,ppid,%cpu,%mem,rss,tty,start,time,args'"
else # doesn't work in cygwin, but no harm
  alias psp="ps -o 'user,pid,ppid,%cpu,%mem,rss,tname,start_time,time,args'"
fi
if [[ $host =~ (nfshost) ]]; then
  alias errlog='less +G /home/logs/error_log'
elif [[ $host =~ (nsto) ]]; then
  alias errlog='less +G /var/www/logs/error.log'
elif [[ $distro =~ ubuntu ]]; then
  alias errlog='less +G /var/log/syslog'
fi
alias temp="sensors | extract Physical 'Core 1' | sed 's/(.*)//' | grep -P '\d+\.\d'"
alias proxpn='cd ~/src/proxpn_mac/config && sudo openvpn --user $USER --config proxpn.ovpn'
alias mountv="sudo mount -t vboxsf -o uid=1000,gid=1000,rw shared $HOME/shared"
alias mountf='mount | perl -we '"'"'printf("%-25s %-25s %-25s\n","Device","Mount Point","Type"); for (<>) { if (m/^(.*) on (.*) type (.*) \(/) { printf("%-25s %-25s %-25s\n", $1, $2, $3); } }'"'"''
alias blockedips="grep 'UFW BLOCK' /var/log/ufw.log | sed -E 's/.* SRC=([0-9a-f:.]+) .*/\1/g' | sort -g | uniq -c | sort -rg -k 1"
alias bitcoin="curl -s http://data.mtgox.com/api/2/BTCUSD/money/ticker_fast | grep -Eo '"'"last":\{"value":"[0-9.]+"'"' | grep -Eo '[0-9.]+'"
if [[ $host =~ (nfshost) || $distro =~ bsd$ ]]; then
  alias updaterc="cd $bashrc_dir && git pull && cd -"
else
  alias updaterc="git --work-tree=$bashrc_dir --git-dir=$bashrc_dir/.git pull"
fi
if [[ $host =~ (zen) ]]; then
  alias logtail='ssh home "~/bin/logtail.sh 100" | less +G'
  logrep () { ssh home "cd ~/0utbox/annex/Work/PSU/Nekrutenko/misc/chatlogs/galaxy-lab; grep -r $@"; }
elif [[ $host =~ (main) ]]; then
  alias logtail='~/bin/logtail.sh 100 | less +G'
  logrep () { cd ~/0utbox/annex/Work/PSU/Nekrutenko/misc/chatlogs/galaxy-lab; grep -r $@; }
fi


##### Functions #####

bak () { cp -r "$1" "$1.bak"; }
# a quick shortcut to placing a script in the ~/bin dir
# only if the system supports readlink -f (BSD doesn't)
if readlink -f / >/dev/null 2>/dev/null; then
  bin () {
    ln -s $(readlink -f $1) ~/bin/$(basename $1)
  }
fi
# no more "cd ../../../.." (from http://serverfault.com/a/28649)
up () { 
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
vix () {
  if [ -e $1 ]; then
    vim $1
  else
    touch $1; chmod +x $1; vim $1
  fi
}
calc () {
  if [ "$1" ]; then
    pycode="from __future__ import division; from math import *; print $@"
    python -c "$pycode" # this kludge is needed because of bash.
  else
    python -i -c "from __future__ import division; from math import *"
  fi
}
wcc () { echo -n "$@" | wc -c; }
if which lynx >/dev/null 2>/dev/null; then
  lgoog () {
    local query=$(echo "$@" | sed -E 's/ /+/g')
    local output=$(lynx -dump "http://www.google.com/search?q=$query")
    local end=$(echo "$output" | grep -n '^References' | cut -f 1 -d ':')
    echo "$output" | head -n $((end-2))
  }
fi
if which lower.b >/dev/null 2>/dev/null; then
  lc () { echo "$1" | lower.b; }
else
  lc () { echo "$1" | tr '[:upper:]' '[:lower:]'; }
fi
pg () {
    if pgrep -f $@ >/dev/null; then
        pgrep -f $@ | xargs ps -o user,pid,stat,rss,%mem,pcpu,args --sort -pcpu,-rss;
    fi
}
parents () {
  if [[ "$1" ]]; then
    pid="$1"
  else
    pid=$$
  fi
  while [[ "$pid" -gt 0 ]]; do
    ps -o comm="" -p $pid
    pid=$(ps -o ppid="" -p $pid)
  done
}
# readlink -f except it handles commands on the PATH too
deref () {
  local file="$1"
  if [ ! -e "$file" ]; then
    file=$(which "$file" 2>/dev/null)
  fi
  readlink -f "$file"
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
if ! which longurl >/dev/null 2>/dev/null; then
  # doesn't work on nfshost (FreeBSD) because it currently needs full regex
  if [[ $distro =~ ubuntu ]]; then
    longurl () {
      url="$1"
      while [ "$url" ]; do
        echo "$url"
        echo -n "$url" | sed -r 's#^https?://([^/]+)/?.*$#\1#g' | xclip -sel clip
        line=$(curl -sI "$url" | grep -P '^[Ll]ocation:\s' | head -n 1)
        url=$(echo "$line" | sed -r 's#^[Ll]ocation:\s+(\S.*\S)\s*$#\1#g')
      done
    }
  # so apparently curl has the -L option
  else
    longurl () {
      echo "$1"; curl -LIs "$1" | grep '^[Ll]ocation' | cut -d ' ' -f 2
    }
  fi
fi

# What are the most common column widths?
columns () {
  echo " totals|columns"
  awkt '{print NF}' $1 | sort -g | uniq -c | sort -rg -k 1
}
# Get totals of a specified column
sumcolumn () {
  if [ ! "$1" ] || [ ! "$2" ]; then
    echo 'USAGE: $ sumcolumn 3 file.csv'
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
wifimac () {
  iwconfig 2> /dev/null | sed -nE 's/^.*access point: ([a-zA-Z0-9:]+)\s*$/\1/pig'
}
wifissid () {
  iwconfig 2> /dev/null | sed -nE 's/^.*SSID:"(.*)"\s*$/\1/pig'
}
wifiip () {
  getip | sed -nE 's/^wlan0:\s*([0-9:.]+)$/\1/pig'
}
bintoascii () {
  for i in $( seq 0 8 ${#1} ); do echo -n $(python -c "print chr($((2#${1:$i:8})))"); done; echo
}


##### Bioinformatics #####

if [[ $host =~ (brubeck) ]]; then
  alias igv='java -Xmx16384M -jar ~/bin/igv.jar'
elif [[ $host =~ (zen|main) ]]; then
  alias igv='java -Xmx4096M -jar ~/bin/igv.jar'
elif [[ $host =~ (nsto) ]]; then
  alias igv='java -Xmx256M -jar ~/bin/igv.jar'
fi
alias seqlen="bioawk -c fastx '{ print \$name, length(\$seq) }'"
alias rdp='java -Xmx1g -jar ~/bin/MultiClassifier.jar'
alias gatk="java -jar ~/bin/GenomeAnalysisTK.jar"
#alias qsh='source $home/src/qiime_software/activate.sh'
alias readsfa='grep -Ec "^>"'
readsfq () {
  echo "$(wc -l $1 |  cut -f 1 -d ' ')/4" | bc
}
alias bcat="samtools view -h"
gatc () {
  if [[ -n $1 ]]; then
    echo "$1" | sed -E 's/[^GATCNgatcn]//g';
  else
    while read data; do
      echo "$data" | sed -E 's/[^GATCNgatcn]//g';
    done;
  fi
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
# Get some quality stats on a BAM using samtools
bamsummary () {
  for bam in $@; do
    if [[ $# -gt 1 ]]; then echo -e "    $bam:"; fi
    local total=$(samtools view -c $bam)
    pct () { python -c "print round(100.0 * $1/$total, 2)"; }
    echo -e "total reads:\t $total"
    local unmapped=$(samtools view -c -f 4 $bam)
    echo -e "unmapped reads:\t $unmapped\t"$(pct $unmapped)"%"
    local improper_pair=$(samtools view -c -F 2 $bam)
    echo -e "not proper pair: $improper_pair\t"$(pct $improper_pair)"%"
    local q0=$(echo $total-$(samtools view -c -q 1 $bam) | bc)
    echo -e "MAPQ 0 reads:\t $q0\t"$(pct $q0)"%"
    local q20=$(echo $total-$(samtools view -c -q 20 $bam) | bc)
    echo -e "< MAPQ 20 reads: $q20\t"$(pct $q20)"%"
    local q30=$(echo $total-$(samtools view -c -q 30 $bam) | bc)
    echo -e "< MAPQ 30 reads: $q30\t"$(pct $q30)"%"
    local duplicates=$(samtools view -c -f 1024 $bam)
    echo -e "duplicates:\t $duplicates\t"$(pct $duplicates)"%"
  done 
}


##### Other #####

# Stuff I don't want to post publicly on Github. Still should be universal, not
# machine-specific.
if [ -f ~/.bashrc_private ]; then
  source ~/.bashrc_private
fi

export PS1="\e[0;36m[\d]\e[m \e[0;32m\u@\h: \w\e[m\n\$ "

# a more "sophisticated" method for determining if we're in a remote shell
remote=""
# check if the system supports the right ps parameters and if parents is able to
# climb the entire process hierarchy
if ps -o comm="" -p 1 >/dev/null 2>/dev/null && [[ $(parents | tail -n 1) == "init" ]]; then
  for process in $(parents); do
    if [[ "$process" == "sshd" ]]; then
      remote="true"
    fi
  done
else
  if [[ -n $SSH_CLIENT || -n $SSH_TTY ]]; then
    remote="true"
  fi
fi

# if it's a remote shell, change $PS1 prompt format and enter a screen
if [[ $remote ]]; then
  export PS1="[\d] \u@\h: \w\n\$ "
  # if not already in a screen, enter one (IMPORTANT to avoid infinite loops)
  # also check that stdout is attached to a real terminal with -t 1
  if [[ ! "$STY" && -t 1 ]]; then
    # Don't export PATH again if in a screen.
    export PATH=$PATH:~/bin
    if [[ ! $host =~ (main|zen|brubeck) ]]; then
      export PATH=$PATH:~/code
    fi
    if [[ $host =~ (nfshost) ]]; then
      true  # no screen there
    elif [[ $host =~ (brubeck) ]]; then
      exec ~/code/pagscr-me.sh '-RR -S auto'
    else
      exec screen -RR -S auto
    fi
  fi
fi
