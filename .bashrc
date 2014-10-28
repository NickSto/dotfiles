#TODO: make all relevant functions work on stdin too

##### Detect host #####

host=$(hostname -s 2>/dev/null || hostname)

# supported hosts:
# zen main nsto yarr brubeck scofield ndojo nbs lion cyberstar

# supported distros:
#   ubuntu debian freebsd
# partial support:
#   cygwin osx

##### Determine distro #####

# change effective home directory on scofield
if [[ $host == scofield ]]; then
  HOME=/galaxy/home/nick
  cd $HOME
fi

# Reliably get the actual parent dirname of a link (no readlink -f in BSD)
function realdirname {
  echo $(cd $(dirname $(readlink $1)) && pwd)
}

# Determine directory with .bashrc files
cd $HOME
if [[ -f .bashrc ]]; then
  bashrc_dir=$(realdirname .bashrc)
elif [[ -f .bash_profile ]]; then
  bashrc_dir=$(realdirname .bash_profile)
else
  bashrc_dir="$HOME/code/dotfiles"
fi
cd - >/dev/null

# Set distro based on known hostnames
case "$host" in
  zen)
    distro="ubuntu";;
  main)
    distro="ubuntu";;
  nsto)
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



#################### System default stuff ####################


# All comments in this block are from Ubuntu's default .bashrc
if [[ $distro == ubuntu ]]; then

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

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'



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


##### Aliases #####

# Set directory for my special data files
data_dir="$HOME/.local/share/nbsdata"
if [[ $distro == ubuntu || $distro == cygwin || $distro == debian ]]; then
  alias lsl='ls -lFhAb --color=auto --group-directories-first'
  alias lsld='ls -lFhAbd --color=auto --group-directories-first'
else
  # long options don't work on nfshost (freebsd) or OS X
  alias lsl='ls -lFhAb'
  alias lsld='ls -lFhAbd'
fi
alias sll='sl' # choo choo
alias mv="mv -i"
alias cp="cp -i"
alias targ='tar -zxvpf'
alias tarb='tar -jxvpf'
alias pseudo='sudo'
alias vib="vim $bashrc_dir/.bashrc"
alias awkt="awk -F '\t' -v OFS='\t'"

alias pingg='ping -c 1 google.com'
alias curlip='curl -s icanhazip.com'
function geoip { curl http://freegeoip.net/csv/$1; }
# Get the ASN of a public IP address (or your IP, if none given)
function asn {
  if [[ $# -gt 0 ]]; then
    ip=$1
  else
    ip=$(curlip)
  fi
  asn=$(awk -F '\t' '$1 == "'$ip'" {print $2}' $data_dir/asn-cache.tsv | head -n 1)
  if [[ ! $asn ]]; then
    asn=$(curl -s http://ipinfo.io/$ip/org | grep -Eo '^AS[0-9]+')
  fi
  echo $asn
}
if which longurl.py >/dev/null 2>/dev/null; then
  alias longurl='longurl.py -fc'
else
  function longurl {
    echo "$1"; curl -LIs "$1" | grep '^[Ll]ocation' | cut -d ' ' -f 2
  }
fi
if which trash-put >/dev/null 2>/dev/null; then
  alias trash='trash-put'
else
  function trash {
    if [[ ! -d $HOME/.trash ]]; then
      mkdir $HOME/.trash
    fi
    mv $@ $HOME/.trash
  }
fi
if [[ $host == brubeck ]]; then
  alias cds='cd /scratch2/nick'
elif [[ $host =~ ^nn[0-9] ]]; then
  alias cds='cd /nfs/brubeck.bx.psu.edu/scratch2/nick'
elif [[ $host == zen ]]; then
  alias cds='cd ~/school'
fi
alias noheader='grep -v "^#"'
#alias kerb='kinit -l 90d nick@BX.PSU.EDU'
alias kerb='kinit -l 90d nick@GALAXYPROJECT.ORG'
alias rsynca='rsync -e ssh --delete --itemize-changes -zaXAv'
alias rsynchome='rsync -e ssh -zaXAv --itemize-changes --delete /home/me/aa/ home:/home/me/aa/ && rsync -e ssh -zaXAv --itemize-changes --delete /home/me/annex/ home:/home/me/annex/'
alias rsynclocal='rsync -e ssh -zaXAv --itemize-changes --delete /home/me/aa/ local:/home/me/aa/ && rsync -e ssh -zaXAv --itemize-changes --delete /home/me/annex/ local:/home/me/annex/'
alias swapkeys="loadkeys-safe.sh && sudo loadkeys $HOME/aa/misc/computerthings/keymap-loadkeys.txt"

alias minecraft="cd ~/src/minecraft && java -Xmx400M -Xincgc -jar $HOME/src/minecraft_server.jar nogui"
alias minelog='ssh vps "tail src/minecraft/server.log"'
alias mineme='ssh vps "cat src/minecraft/server.log" | grep -i nick | tail'
alias minelist="ssh vps 'screen -S minecraft -X stuff \"list
\"; sleep 1; tail src/minecraft/server.log'"
alias minemem='ssh vps "if pgrep -f java >/dev/null; then pgrep -f java | xargs ps -o %mem; fi"'

if [[ $distro =~ (^osx$|bsd$) ]]; then
  alias psp="ps -o 'user,pid,ppid,%cpu,%mem,rss,tty,start,time,args'"
else # doesn't work in cygwin, but no harm
  alias psp="ps -o 'user,pid,ppid,%cpu,%mem,rss,tname,start_time,time,args'"
fi
if [[ $host == ndojo || $host == nbs ]]; then
  alias errlog='less +G /home/logs/error_log'
elif [[ $host == nsto ]]; then
  alias errlog='less +G /var/www/logs/error.log'
elif [[ $distro == ubuntu || $distro == debian ]]; then
  alias errlog='less +G /var/log/syslog'
fi
if [[ $host == scofield ]]; then
  alias srunb='srun -C new --pty bash'
  alias srunc='srun -C new'
  aklog bx.psu.edu
fi
alias temp="sensors | extract Physical 'Core 1' | sed 's/(.*)//' | grep -P '\d+\.\d'"
alias proxpn='cd ~/src/proxpn_mac/config && sudo openvpn --user $USER --config proxpn.ovpn && cd -'
alias mountv="sudo mount -t vboxsf -o uid=1000,gid=1000,rw shared $HOME/shared"
alias mountf='mount | perl -we '"'"'printf("%-25s %-25s %-25s\n","Device","Mount Point","Type"); for (<>) { if (m/^(.*) on (.*) type (.*) \(/) { printf("%-25s %-25s %-25s\n", $1, $2, $3); } }'"'"''
alias blockedips="grep 'UFW BLOCK' /var/log/ufw.log | sed -E 's/.* SRC=([0-9a-f:.]+) .*/\1/g' | sort -g | uniq -c | sort -rg -k 1"
alias bitcoin="curl -s http://data.mtgox.com/api/2/BTCUSD/money/ticker_fast | grep -Eo '"'"last":\{"value":"[0-9.]+"'"' | grep -Eo '[0-9.]+'"
if [[ $host == cyberstar || $distro =~ bsd$ ]]; then
  alias updaterc="cd $bashrc_dir && git pull && cd -"
else
  alias updaterc="git --work-tree=$bashrc_dir --git-dir=$bashrc_dir/.git pull"
fi
if [[ $host == zen ]]; then
  alias logtail='ssh home "~/bin/logtail.sh 100" | less +G'
  logrep () {
    ssh home "cd ~/0utbox/annex/Work/PSU/Nekrutenko/misc/chatlogs/galaxy-lab && grep -r $*"
  }
elif [[ $host == main ]]; then
  alias logtail='~/bin/logtail.sh 100 | less +G'
  logrep () {
    cd ~/0utbox/annex/Work/PSU/Nekrutenko/misc/chatlogs/galaxy-lab && grep -r $@
  }
fi


##### Functions #####

bak () { cp -r "$1" "$1.bak"; }
# add to path **if it's not already there**
pathadd () {
  if [[ ! -d "$1" ]]; then return; fi
  # handle empty PATH
  if [[ ! "$PATH" ]]; then export PATH="$1"; return; fi
  for path in $(echo "$PATH" | tr ':' '\n'); do
    if [[ "$path" == "$1" ]]; then return; fi
  done
  PATH="$PATH:$1"
}
# subtract from path
pathsub () {
  newpath=""
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
  bin () {
    ln -s $(readlink -f $1) ~/bin/$(basename $1)
  }
fi
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
function calc {
  if [ "$1" ]; then
    python -c "from __future__ import division; from math import *; print $*"
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
  perl -we '
  my @tot; my $first = 1;
  while (<>) {
    next if (m/[a-z]/i); # skip lines with non-numerics
    my @fields = split("\t");
    if ($first) {
      $first = 0;
      for my $field (@fields) {
        push(@tot, $field)
      }
    } else {
      for ($i = 0; $i < @tot; $i++) {
        $tot[$i] += $fields[$i]
      }
    }
  }
  print join("\t", @tot)."\n"'
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
function wtf {
  local url="$1"
  if ! echo "$url" | grep -qE '^http://traffic.libsyn.com/wtfpod/_?WTF_-_EPISODE_[0-9]+.*\.mp3$'; then
    echo "URL doesn't look right: $url" >&2; return
  fi
  local num=$(echo "${url:47}" | sed -E 's/^_?([0-9]+).*$/\1/')
  if echo "${url:47}" | grep -qE '^_?[0-9]+_\w.*\.mp3'; then
    local rawname=$(echo "${url:47}" | sed -E 's/^_?[0-9]+_(.*)\.mp3$/\1/g' | sed -E 's/_/ /g')
    local name=$(python -c 'import sys, titlecase; print titlecase.titlecase(sys.argv[1])' "$rawname")
    local filename="WTF $num - $name.mp3"
  else
    if [[ $# -ge 2 ]]; then
      local name=" - $2"
    fi
    local filename="WTF $num$name.mp3"
  fi
  if [[ -n $COOKIE ]]; then
    local cookie="$COOKIE"
  else:
    local cookie="ketjivcs8avqonscekku2jij75"
  fi
  if curl -L -b "libsyn-paywall=$cookie" "$url" > "$filename"; then
    echo "saved to $filename"
  else
    echo "error downloading" >&2
  fi
  if [[ $(du -sb "$filename") -lt 524288 ]]; then
    echo "possible error: the file is only $(du -sb "$filename")" >&2
  fi
}
# For PS1 prompt (thanks to https://stackoverflow.com/a/1862762/726773)
function prompt_color {
  if [[ $? == 0 ]]; then
    if [[ "$remote" ]]; then
      pcol='0;30m' # black
    else
      pcol='0;36m' # teal
    fi
  else # if error
    pcol='0;31m' # red
  fi
}
timer_thres=10
function timer_start {
  timer=${timer:-$SECONDS}
}
function timer_stop {
  local seconds=$(($SECONDS - $timer))
  timer_show=''
  if [[ $seconds -ge $timer_thres ]]; then
    timer_show="$(time_format $seconds) "
  fi
  unset timer
}
# format a number of seconds into a readable time
function time_format {
  local seconds=$1
  local minutes=$(($seconds/60))
  local hours=$(($minutes/60))
  local seconds=$(($seconds - $minutes*60))
  local minutes=$(($minutes - $hours*60))
  if [[ $minutes -lt 1 ]]; then
    echo $seconds's'
  elif [[ $hours -lt 1 ]]; then
    echo $minutes'm'$seconds's'
  else
    echo $hours'h'$minutes'm'
  fi
}
trap 'timer_start' DEBUG


##### Bioinformatics #####

if [[ $host == zen || $host == main ]]; then
  true #alias igv='java -Xmx4096M -jar ~/bin/igv.jar'
elif [[ $host == nsto ]]; then
  alias igv='java -Xmx256M -jar ~/bin/igv.jar'
else
  alias igv='java -jar ~/bin/igv.jar'
fi
alias seqlen="bioawk -c fastx '{ print \$name, length(\$seq) }'"
alias rdp='java -Xmx1g -jar ~/bin/MultiClassifier.jar'
alias gatk="java -jar ~/bin/GenomeAnalysisTK.jar"
#alias qsh='source $HOME/src/qiime_software/activate.sh'
alias readsfa='grep -Ec "^>"'
if ! which readsfq >/dev/null 2>/dev/null; then
  function readsfq {
    echo "$(wc -l $1 |  cut -f 1 -d ' ')/4" | bc
  }
fi
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
  rm "$3.tmp.pdf"
}
# Get some quality stats on a BAM using samtools
bamsummary () {
  for bam in $@; do
    echo -e "    $bam:"
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

# add correct bin directory to PATH
if [[ $host == scofield ]]; then
  pathadd /galaxy/home/nick/bin
elif [[ $host =~ ^nn[0-9] ]]; then
  true  # inherited from scofield
else
  pathadd ~/bin
fi
if [[ $host == lion ]]; then
  pathadd /opt/local/bin
fi
pathadd /sbin
pathadd /usr/sbin
pathadd /usr/local/sbin
pathadd $HOME/.local/bin

# a more "sophisticated" method for determining if we're in a remote shell
remote=""
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

PROMPT_COMMAND='prompt_color;timer_stop'
ROOTPS1="\e[0;31m[\d] \u@\h: \w\e[m\n# "

# if it's a remote shell, change $PS1 prompt format and enter a screen
if [[ $remote ]]; then
  export PS1='${timer_show}\e[${pcol}[\d]\e[m \u@\h: \w\n\$ '
  # if not already in a screen, enter one (IMPORTANT to avoid infinite loops)
  # also check that stdout is attached to a real terminal with -t 1
  if [[ ! "$STY" && -t 1 ]]; then
    if [[ $host == ndojo || $host == nbs ]]; then
      true  # no screen there
    elif [[ $host == brubeck || $host == scofield ]]; then
      exec ~/code/pagscr-me.sh -RR -S auto
    else
      exec screen -RR -S auto
    fi
  fi
else
  export PS1='${timer_show}\e[${pcol}[\d]\e[m \e[0;32m\u@\h: \w\e[m\n\$ '
fi
