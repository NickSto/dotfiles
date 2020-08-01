if [[ $BashrcRan ]]; then
  echo '.bashrc already sourced. Unset $BashrcRan to source again.' >&2
  return 1
fi

##### Detect host #####

Host=$(hostname -s 2>/dev/null || hostname)

# supported hosts:
# ruby main nsto2 ndojo nbs yarr brubeck scofield desmond nn[0-9]+ uniport lion cyberstar

# supported distros:
#   ubuntu debian freebsd
# partial support:
#   cygwin osx

# Are we on one of the cluster nodes?
InCluster=
if echo "$Host" | grep -qE '^nn[0-9]+$' && [[ "${Host:2}" -le 15 ]]; then
  InCluster=true
fi

##### Determine distro #####

# Avoid unexpectd $CDPATH effects
# https://bosker.wordpress.com/2012/02/12/bash-scripters-beware-of-the-cdpath/
unset CDPATH

# Reliably get the actual parent dirname of a link (no readlink -f in BSD)
function realdirname {
  echo $(cd $(dirname $(readlink "$1")) && pwd)
}

# Determine directory with .bashrc files
if [[ -d "$HOME" ]]; then
  cd "$HOME"
fi
if [[ -f .bashrc ]]; then
  # Is it a link or real file?
  if [[ -h .bashrc ]]; then
    BashrcDir=$(realdirname .bashrc)
  else
    BashrcDir="$HOME"
  fi
elif [[ -f .bash_profile ]]; then
  # Is it a link or real file?
  if [[ -h .bash_profile ]]; then
    BashrcDir=$(realdirname .bash_profile)
  else
    BashrcDir="$HOME"
  fi
else
  BashrcDir="$HOME/code/dotfiles"
fi
cd - >/dev/null

# Set distro based on known hostnames
case "$Host" in
  aknot)
    Distro="ubuntu";;
  ruby)
    Distro="ubuntu";;
  main)
    Distro="ubuntu";;
  nsto2)
    Distro="ubuntu";;
  yarr)
    Distro="ubuntu";;
  ndojo)
    Distro="freebsd";;
  nbs)
    Distro="freebsd";;
  brubeck)
    Distro="debian";;
  scofield)
    Distro="debian";;
  *)  # Unrecognized host? Run detection script.
    if [[ -f "$BashrcDir/detect-distro.sh" ]]; then
      source "$BashrcDir/detect-distro.sh"
    else
      Distro=
    fi;;
esac

# Get the kernel string if detect-distro.sh didn't.
if [[ ! "$Kernel" ]]; then
  Kernel=$(uname -s 2>/dev/null | tr '[:upper:]' '[:lower:]')
fi

# If we're in Tails, set $HOME to the USB drive with this bashrc on it.
if [[ "$Distro" == tails ]]; then
  if [[ "$Host" == localhost.localdomain ]]; then
    Host=tails
  fi
  usb_drive=$(df "$BashrcDir" | awk 'END {print $6}')
  if [[ $usb_drive ]]; then
    export HOME="$usb_drive"
    cd "$HOME"
  fi
fi

# If we're in the webserver, cd to the webroot.
if [[ "$Host" == nsto2 ]]; then
  cd /var/www/nstoler.com
fi



#################### System default stuff ####################


# All comments in this block are from Ubuntu's default .bashrc
if [[ "$Distro" == ubuntu ]]; then

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
elif [[ "$Host" == brubeck ]]; then

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
    . "$file"
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
DataDir="$HOME/.local/share/nbsdata"
# Set a default bx destination server
export LC_BX_DEST=desmond
# Set my default text editor
export EDITOR=vim
# Allow disabling ~/.python_history.
# See https://unix.stackexchange.com/questions/121377/how-can-i-disable-the-new-history-feature-in-python-3-4
export PYTHONSTARTUP=~/.pythonrc
# Perl crap to enable CPAN modules installed to $HOME.
if [[ -d "$HOME/perl5/bin" ]]; then
  export PATH="$PATH:$HOME/perl5/bin"
fi
export PERL5LIB="$HOME/perl5/lib/perl5"
export PERL_LOCAL_LIB_ROOT="$HOME/perl5"
export PERL_MB_OPT="--install_base \"$HOME/perl5\""
export PERL_MM_OPT="INSTALL_BASE=$HOME/perl5"


##### Aliases #####

if [[ "$Distro" == ubuntu || "$Distro" == cygwin || "$Distro" == debian ]]; then
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
alias vib="vim $BashrcDir/.bashrc"
alias awkt="awk -F '\t' -v OFS='\t'"
alias pingg='ping -c 1 google.com'
alias curlip='curl -s icanhazip.com'


##### Functions and Aliases #####

function mouse {
  nohup mousepad "$1" >/dev/null 2>/dev/null &
}
function now {
  date +%s
}
function cpu {
  ps aux | awk 'NR > 1 {cpu+=$3; mem+=$4} END {printf("%0.2f\t%0.2f\n", cpu/100, mem/100)}'
}
alias mem=cpu
if which totalmem.sh >/dev/null 2>/dev/null; then
  alias chromem='totalmem.sh -n Chrome /opt/google/chrome/'
  alias foxmem='totalmem.sh -n Firefox /usr/lib/firefox/'
fi
function geoip {
  if [[ "$1" ]]; then
    ip="$1"
  else
    ip=$(curlip)
  fi
  curl -s "http://ipinfo.io/$ip" | jq -r '.city + ", " + .region + ", " + .country + ": " + .org'
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
    if ! [[ -d "$HOME/.trash" ]]; then
      if ! mkdir "$HOME/.trash"; then
        echo "Error creating ~/.trash" >&2
        return 1
      fi
    fi
    mv "$@" "$HOME/.trash"
  }
fi
function cds {
  if [[ "$1" ]]; then
    local n="$1"
  else
    local n=5
  fi
  if [[ "$n" == 1 ]]; then
    if [[ "$Host" == brubeck ]]; then
      cd /scratch/nick
    else
      cd /nfs/brubeck.bx.psu.edu/scratch1/nick
    fi
  elif [[ "$n" == 2 ]]; then
    if [[ "$Host" == brubeck ]]; then
      cd /scratch2/nick
    else
      cd /nfs/brubeck.bx.psu.edu/scratch2/nick
    fi
  elif [[ "$n" -ge 3 ]]; then
    cd "/nfs/brubeck.bx.psu.edu/scratch$n/nick"
  fi
}
alias noheader='grep -v "^#"'
alias veramount="veracrypt -t --truecrypt -k '' --protect-hidden=no"
# Swap caps lock and esc.
alias swapkeys="loadkeys-safe.sh && sudo loadkeys $HOME/aa/computer/keymap-loadkeys.txt"
# If an .xmodmap is present, source it to alter the keys however it says. Disable with noremap=1.
# This is possibly obsoleted by the loadkeys method above.
if [[ -f ~/.xmodmap ]] && [[ -z "$noremap" ]]; then
  xmodmap ~/.xmodmap
fi
function kerb {
  local bx_realm="nick@BX.PSU.EDU"
  local galaxy_realm="nick@GALAXYPROJECT.ORG"
  local default_realm="$bx_realm"
  local realm="$1"
  if [[ "$#" -le 0 ]]; then
    realm="$default"
  elif [[ "$1" == bx ]]; then
    realm="$bx_realm"
  elif [[ "${1:0:3}" == bru ]]; then
    realm="$bx_realm"
  elif [[ "${1:0:3}" == des ]]; then
    realm="$bx_realm"
  elif [[ "${1:0:3}" == sco ]]; then
    realm="$galaxy_realm"
  elif [[ "${1:0:3}" == gal ]]; then
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
  if [[ -d "$HOME/aa" ]] && [[ -d "$HOME/annex" ]] && [[ -d "$HOME/code" ]]; then
    rsynca "$HOME/aa/" "$dest:/home/$USER/aa/" \
      && rsynca "$HOME/annex/" "$dest:/home/$USER/annex/" \
      && rsynca "$HOME/code/" "$dest:/home/$USER/code/"
  else
    echo "Wrong set of directories exists. Is this the right machine?" >&2
  fi
}
function vnc {
  local delay=8
  (sleep "$delay" && vinagre localhost:0) &
  echo "starting ssh tunnel and vnc server, then client in $delay seconds.."
  echo "[Ctrl+C to exit]"
  ssh -t -L 5900:localhost:5900 home 'x11vnc -localhost -display :0 -ncache 10 -nopw' >/dev/null
}
function config {
  if [[ "$#" != 3 ]]; then
    echo "Usage: config settings.ini section key" >&2
    return 1
  fi
  python3 -c 'import configparser, sys
config = configparser.ConfigParser(interpolation=None)
config.read(sys.argv[1])
try:
  print(config.get(sys.argv[2], sys.argv[3]))
except configparser.Error as error:
  print(error, file=sys.stderr)
  sys.exit(1)' "$1" "$2" "$3"
}
alias minecraft="cd ~/src/minecraft && java -Xmx400M -Xincgc -jar $HOME/src/minecraft_server.jar nogui"
alias minelog='ssh vps "tail src/minecraft/server.log"'
alias mineme='ssh vps "cat src/minecraft/server.log" | grep -i nick | tail'
alias minelist="ssh vps 'screen -S minecraft -X stuff \"list\"; sleep 1; tail src/minecraft/server.log'"
alias minemem='ssh vps "if pgrep -f java >/dev/null; then pgrep -f java | xargs ps -o %mem; fi"'

if [[ "$Distro" =~ (^osx$|bsd$) ]]; then
  alias psp="ps -o 'user,pid,ppid,%cpu,%mem,rss,tty,start,time,args'"
else # doesn't work in cygwin, but no harm
  alias psp="ps -o 'user,pid,ppid,%cpu,%mem,rss,tname,start_time,time,args'"
fi
if [[ "$Host" == ndojo || "$Host" == nbs ]]; then
  alias errlog='less +G /home/logs/error_log'
elif [[ "$Host" == nsto2 ]]; then
  alias errlog='less +G /var/www/logs/error.log'
elif [[ "$Distro" == ubuntu || "$Distro" == debian ]]; then
  alias errlog='less +G /var/log/syslog'
fi
# Search all encodings for strings, raise minimum length to 5 characters
function stringsa {
  strings -n 5 -e s "$1"
  strings -n 5 -e b "$1"
  strings -n 5 -e l "$1"
}
alias temp="sensors | grep -A 3 '^coretemp-isa-0000' | tail -n 1 | awk '{print \$3}' | sed -E -e 's/^\+//' -e 's/\.[0-9]+//'"
alias mountv="sudo mount -t vboxsf -o uid=1000,gid=1000,rw shared $HOME/shared"
function mountf {
  local args='-se -x 1,start,/var/lib/snapd -x 3,start,cgroup'
  if ! which fit-columns.py >/dev/null 2>/dev/null; then
    return 1
  elif [[ "$Host" == brubeck ]] || [[ "$Host" == desmond ]]; then
    local fit_cols=$(deref fit-columns.py)
    (echo Device Mount Type && mount | awk '{print $1, $3, $5}' | sort) | python3.6 "$fit_cols" "$args"
  else
    (echo Device Mount Type && mount | awk '{print $1, $3, $5}' | sort) | fit-columns.py "$args"
  fi
}
alias blockedips="grep 'UFW BLOCK' /var/log/ufw.log | sed -E 's/.* SRC=([0-9a-f:.]+) .*/\1/g' | sort -g | uniq -c | sort -rg -k 1"
alias bitcoin="curl -s 'https://api.coindesk.com/v1/bpi/currentprice.json' | jq .bpi.USD.rate_float | cut -d . -f 1"
if ! which git >/dev/null 2>/dev/null; then
  alias updaterc="wget 'https://raw.githubusercontent.com/NickSto/dotfiles/master/.bashrc' -O $BashrcDir/.bashrc"
elif [[ "$Host" == cyberstar || "$Distro" =~ bsd$ ]]; then
  alias updaterc="cd $BashrcDir && git pull && cd -"
else
  alias updaterc="git --work-tree=$BashrcDir --git-dir=$BashrcDir/.git pull"
fi
function silence {
  local Silence="$DataDir/SILENCE"
  if [[ "$#" -ge 1 ]] && [[ "$1" == '-h' ]]; then
    echo "Usage: \$ silence [-u|-f]
Toggles silence file $Silence and silences some common background services.
Prompts before unsilencing (unless -u is given).
Use -f to force silencing even if SILENCE file exists.
Returns 0 when silenced, 2 when unsilenced, and 1 on error." >&2
    return 1
  fi
  if [[ "$#" -ge 1 ]] && [[ "$1" == '-u' ]]; then
    rm -f "$Silence"
    unsilence_services
    echo "Unsilenced!"
  elif [[ -f "$Silence" ]] && [[ "$1" != '-f' ]]; then
    local response
    read -p "You're currently silenced! Use -f to force silencing again or type \"louden\" to unsilence! " response
    if [[ "$response" == 'louden' ]]; then
      rm -f "$Silence"
      unsilence_services
      echo "Unsilenced!"
    else
      echo "Aborting!"
      return 1
    fi
  else
    silence_services
    retval="$?"
    touch "$Silence"
    if [[ "$retval" == 0 ]]; then
      echo "Silenced!"
    else
      echo "Error silencing some services!" >&2
      return "$retval"
    fi
  fi
}
function silence_services {
  local failure=
  # Dropbox
  echo "Killing Dropbox.."
  if which dropbox >/dev/null 2>/dev/null; then
    dropbox stop
    local sleep_time=1
    # The "running" command seems to return the opposite of what you expect.
    while ! dropbox running >/dev/null 2>/dev/null; do
      sleep "$sleep_time"
      sleep_time=$((sleep_time*2))
      if [[ "$sleep_time" -ge 32 ]]; then
        echo "Error: Could not kill Dropbox!" >&2
        failure=true
        break
      fi
    done
    if ! [[ "$failure" ]]; then
      # Sometimes dropbox gives conflicting messages. Let's reassure with our own.
      echo "Dropbox daemon stopped." >&2
    fi
  fi
  # Crashplan
  echo "Killing CrashPlan.."
  local crashservice=$(get_crashservice)
  if [[ "$crashservice" ]]; then
    if ! $crashservice stop; then
      failure=true
    fi
  else
    echo "Error: Could not find command to kill CrashPlan!" >&2
    failure=true
  fi
  # Snap daemon (often maintains a connection) (listening for updates?)
  echo "Killing snapd.."
  if service snapd status >/dev/null 2>/dev/null; then
    sudo service snapd stop
  fi
  if [[ "$failure" ]]; then
    return 1
  else
    return 0
  fi
}
function unsilence_services {
  failure=
  # Dropbox
  echo "Starting Dropbox.."
  if which dropbox >/dev/null 2>/dev/null; then
    if ! dropbox start 2>/dev/null; then
      echo "Error: Problem starting Dropbox." >&2
      failure=true
    else
      echo "Dropbox started successfully." >&2
    fi
  fi
  # Crashplan
  echo "Starting CrashPlan.."
  local crashservice=$(get_crashservice)
  if [[ "$crashservice" ]]; then
    if ! $crashservice start; then
      echo "Error: Problem starting CrashPlan." >&2
      failure=true
    fi
  else
    echo "Warning: did not find command to start CrashPlan." >&2
  fi
  # Snap Daemon
  echo "Starting snapd.."
  service snapd status >/dev/null 2>/dev/null
  if [[ "$?" != 4 ]]; then
    # The status command returns 4 if the service doesn't exist, but 3 if it's not running.
    sudo service snapd start
  fi
  if [[ "$failure" ]]; then
    return 1
  else
    return 0
  fi
}
function get_crashservice {
  if service_exists code42; then
    echo sudo service code42
  elif service_exists crashplan; then
    echo sudo service crashplan
  elif which CrashPlanEngine >/dev/null 2>/dev/null; then
    echo CrashPlanEngine
  elif [[ -x "$HOME/src/crashplan/bin/CrashPlanEngine" ]]; then
    echo "$HOME/src/crashplan/bin/CrashPlanEngine"
  else
    echo "Error: Crashplan service not found and CrashPlanEngine command not found." >&2
    return 1
  fi
}
function service_exists {
  local service="$1"
  service "$service" status >/dev/null 2>/dev/null
  retval="$?"
  if [[ "$retval" == 0 ]]; then
    # Service exists and is running.
    return 0
  elif [[ "$retval" == 3 ]]; then
    # Service exists and isn't running.
    return 0
  elif [[ "$retval" == 4 ]]; then
    # Service unrecognized.
    return 1
  else
    echo "Error: Unrecognized return value $retval for service $service." >&2
    return 1
  fi
}
if which tmpcmd.sh >/dev/null 2>/dev/null; then
  function crashpause {
    local old_title="$TITLE"
    title crashpause
    if [[ "$#" -ge 1 ]]; then
      if [[ "$1" == '-h' ]]; then
        echo "Usage: \$ crashpause [time]" >&2
        return 1
      else
        local timeout="$1"
      fi
    else
      local timeout=2h
    fi
    local prefix rest
    read prefix rest <<< $(get_crashservice)
    if ! [[ "$prefix" ]] && ! [[ "$rest" ]]; then
      return 1
    fi
    if [[ "$prefix" == sudo ]]; then
      local crashservice="$rest"
    else
      local crashservice="$prefix $rest"
      prefix=''
    fi
    "$prefix" tmpcmd.sh -t "$timeout" "$crashservice stop" "$crashservice start"
    title "$old_title"
  }
  if which dnsadd.sh >/dev/null 2>/dev/null; then
    function dnsadd {
      if [[ "$#" -lt 1 ]]; then
        echo "Usage: \$ dnsadd [domain.com]" >&2
        return 1
      fi
      sudo tmpcmd.sh -t 2h "dnsadd.sh add $1" "dnsadd.sh rm $1"
    }
  fi
fi
function logip {
  local LogFile=~/aa/computer/logs/ips.tsv
  if [[ "$1" == '-h' ]]; then
    echo "Usage: \$ logip [-f]
Log your current public IP address to $LogFile.
Uses icanhazip.com to get your IP address.
Add -f to force logging even when SILENCE is in effect." >&2
    return 1
  fi
  if [[ "$1" != '-f' ]] && [[ -e "$DataDir/SILENCE" ]]; then
    echo "Error: SILENCE file exists ($DataDir/SILENCE). Add -f to override." >&2
    return 1
  fi
  local ip=$(curl -s icanhazip.com)
  if [[ "$ip" ]]; then
    echo "$ip" >> "$LogFile"
    echo echo "$ip" '>>' "$LogFile"
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
  local dir="$1"
  local location="$2"
  if [[ ! -d "$dir" ]]; then
    return
  fi
  # Handle empty PATH.
  if [[ ! "$PATH" ]]; then
    export PATH="$dir"
    return
  fi
  # Check if it's already present.
  local path=''
  for path in $(echo "$PATH" | tr ':' '\n'); do
    if [[ "$path" == "$dir" ]]; then
      return
    fi
  done
  # Otherwise, do the normal concatenation.
  if [[ "$location" == "start" ]]; then
    PATH="$dir:$PATH"
  else
    PATH="$PATH:$dir"
  fi
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
function dusort {
  if [[ "$#" -ge 1 ]] && [[ "$1" == '-h' ]]; then
    echo "Usage: dusort [path1 [path2 [path3 [...]]]]
Note: This works with dotfiles and files with spaces." >&2
    return 1
  fi
  local hidden=
  if [[ "$#" -ge 1 ]]; then
    local paths="$@"
  else
    local paths=*
    if ls .[!.]* >/dev/null 2>/dev/null; then
      hidden=.[!.]*
    fi
  fi
  du -sB1 $paths $hidden | sort -g -k 1 | while read size path; do
    du -sh "$path"
  done
}
# a quick shortcut to placing a script in the ~/bin dir
# only if the system supports readlink -f (BSD doesn't)
if readlink -f / >/dev/null 2>/dev/null; then
  function bin {
    ln -s $(readlink -f "$1") ~/bin/$(basename "$1")
  }
fi
# Done quoting variables up to here. [keys: quotes]
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
function gitgrep {
  if [[ "$#" -lt 1 ]] || [[ "$#" -gt 1 ]] || [[ "$1" == '-h' ]] || [[ "$1" == '--help' ]]; then
    echo 'Usage: $ codegrep query
Do a recursive search for an exact string anywhere under the current directory.
Current features: ignores .git and .venv directories, truncates lines to current terminal width.' >&2
    return 1
  fi
  local query="$1"
  grep -RIF --exclude-dir .git --exclude-dir .venv "$query" | awk "{print substr(\$0, 1, $COLUMNS)}"
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
  python3 -c "import titlecase, sys
if len(sys.argv) > 1:
  line = ' '.join(sys.argv[1:])
  print(titlecase.titlecase(line.lower()))
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
  if [[ "$#" -ge 1 ]]; then
    local pid="$1"
  else
    local pid="$$"
  fi
  while [[ "$pid" -gt 0 ]]; do
    ps -o pid,args -p $pid | tail -n +2
    pid=$(ps -o ppid -p $pid | tail -n +2)
  done
}
# readlink -f except it handles commands on the PATH too
function deref {
  local arg="$1"
  local path
  if [[ $(type -t "$arg") == file ]]; then
    # It's a command on the $PATH. Look up its actual path.
    path=$(which "$arg" 2>/dev/null)
    readlink -f "$path"
    return "$?"
  else
    path="$arg"
  fi
  while [[ "$path" ]]; do
    local old_path="$path"
    path=$(readlink "$old_path")
  done
  echo "$old_path"
}
# this requires deref()!
function vil {
  vi $(deref "$1")
}
function dfh {
  local args='-se -x 1,start,/dev/loop -x 1,tmpfs -x 1,udev -x 1,start,/dev/mapper/vg-var -x 1,AFS'
  if ! which fit-columns.py >/dev/null 2>/dev/null; then
    return 1
  elif [[ "$Host" == brubeck ]] || [[ "$Host" == desmond ]]; then
    local fit_cols=$(deref fit-columns.py)
    df -h | python3.6 "$fit_cols" $args
  else
    df -h | fit-columns.py $args
  fi
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
function eta {
  local Usage="Usage: eta <start_time> <start_count> <current_count> <goal_count>
       --- or ---
       eta start <goal_count> <start_count>
       eta <current_count>"
  if [[ "$#" -lt 1 ]] || [[ "$1" == '-h' ]]; then
    echo "$Usage" >&2
    return 1
  elif [[ "$1" == 'start' ]] && [[ "$#" == 3 ]]; then
    start_time=$(date +%s)
    goal="$2"
    start_count="$3"
    echo -e "start_time=$start_time\nstart_count=$start_count\ngoal=$goal"
    return 0
  elif [[ "$#" == 1 ]] && [[ "$start_time" ]] && [[ "$start_count" ]] && [[ "$goal" ]]; then
    local current="$1"
  elif [[ "$#" == 4 ]]; then
    local start_time="$1"
    local start_count="$2"
    local current="$3"
    local goal="$4"
  else
    echo "$Usage" >&2
    return 1
  fi
  if [[ "$(calc "$current <= $start_count")" == 'True' ]]; then
    echo "Error: $current <= $start_count" >&2
    return 1
  fi
  local now=$(date +%s)
  local sec_left=$(calc "($goal-$current)*($now-$start_time)/($current-$start_count)")
  local eta=$(date -d "now + $sec_left seconds")
  local eta_diff=$(datediff "$eta")
  local min_left=$(calc "'{:0.2f}'.format($sec_left/60)")
  echo -e "$eta_diff\t($min_left min from now)"
}
function timer {
  if [[ "$#" -lt 1 ]] || [[ "$#" -gt 2 ]] || [[ "$1" == '-h' ]]; then
    echo "Usage: timer delay [message]
The 'delay' should be parseable by the 'sleep' command.
This will sleep for 'delay', then notify-send the message and play a tone." >&2
    return 1
  fi
  local delay_str="$1"
  local message='Timer finished!'
  if [[ "$#" -ge 2 ]]; then
    message="$2"
  fi
  local remaining=$(time_to_sec "$delay_str")
  local interval
  if [[ "$remaining" -lt 10 ]]; then
    interval="$remaining"
  elif [[ "$remaining" -lt 120 ]]; then
    interval=10
  elif [[ "$remaining" -lt 1800 ]]; then
    interval=60
  elif [[ "$interval" -lt 9000 ]]; then
    interval=300
  else
    interval=1800
  fi
  while [[ "$remaining" -gt 0 ]]; do
    if [[ "$interval" -lt "$remaining" ]]; then
      local sleep_time="$interval"
    else
      local sleep_time="$remaining"
    fi
    echo "$(human_time "$remaining" 1unit) remaining."
    sleep "$sleep_time"
    remaining=$((remaining-sleep_time))
  done
  if [[ "$?" != 0 ]]; then
    echo "Timer cancelled by user." >&2
    return 1
  fi
  echo "$message"
  notify-send "$message"
  local sound_path="$HOME/aa/audio/30 second silence and tone.mp3"
  if [[ -f "$sound_path" ]]; then
    vlc --play-and-exit "$sound_path" 2>/dev/null
  else
    echo "Sound file not found: $sound_path" >&2
  fi
}
function readcsv {
  if [[ "$#" -ge 1 ]]; then
    python -c 'import sys, csv
csv.writer(sys.stdout, dialect="excel-tab").writerows(csv.reader(open(sys.argv[1])))' "$1"
  else
    python -c 'import sys, csv
csv.writer(sys.stdout, dialect="excel-tab").writerows(csv.reader(sys.stdin))'
  fi
}
function datediff {
  if [[ "$#" -lt 1 ]] || [[ "$1" == '-h' ]]; then
    echo "Usage: datediff date1 [date2]
Compare two datetimes and print the parts of date1 that are different from date2.
date2 is the current time by default.
The dates should be parseable by the 'date -d' command." >&2
    return 1
  elif [[ "$#" -ge 2 ]]; then
    local timestamp2=$(date +%s -d "$2")
  else
    local timestamp2=$(date +%s)
  fi
  local timestamp1=$(date +%s -d "$1")
  local secdiff=$((timestamp1-timestamp2))
  secdiff=${secdiff#-}
  local dow1 dow2 mon1 mon2 dom1 dom2 time1 time2 tz1 tz2 year1 year2
  read time1 tz1 dow1 mon1 dom1 year1 <<< $(date +'%l:%M:%S%p %Z %a %b %e %Y' -d "@$timestamp1")
  read time2 tz2 dow2 mon2 dom2 year2 <<< $(date +'%l:%M:%S%p %Z %a %b %e %Y' -d "@$timestamp2")
  tz1noDST=$(echo "$tz1" | sed -E 's/(.)[SD]T/\1XT/')
  tz2noDST=$(echo "$tz2" | sed -E 's/(.)[SD]T/\1XT/')
  if [[ "$tz1noDST" != "$tz2noDST" ]]; then
    time1="$time1 $tz1"
    time2="$time2 $tz2"
  fi
  if [[ "$timestamp1" == "$timestamp2" ]]; then
    # The two dates are the same.
    echo "$time1"
  elif [[ "$year1" != "$year2" ]]; then
    # They're in different years.
    echo "$time1 $dow1 $mon1 $dom1, $year1"
  elif [[ "$mon1" != "$mon2" ]] || [[ "$dom1" != "$dom2" ]]; then
    # They're in the same year, but different days.
    daystart1=$(date +%s -d "$dow1 $mon1 $dom1 0:00:00 $tz1 $year1")
    daystart2=$(date +%s -d "$dow2 $mon2 $dom2 0:00:00 $tz2 $year2")
    daydiff=$((daystart1-daystart2))
    if [[ "$daydiff" -ge 82799 ]] && [[ "$daydiff" -le 90001 ]]; then
      # Difference is about +1 day.
      echo "$time1 Tomorrow"
    elif [[ "$daydiff" -le -82799 ]] && [[ "$daydiff" -ge -90001 ]]; then
      # Difference is about -1 day.
      echo "$time1 Yesterday"
    elif [[ "$secdiff" -ge 864000 ]]; then
      # More than 10 days apart.
      echo "$time1 $mon1 $dom1"
    else
      # Less than 10 days apart.
      echo "$time1 $dow1 $mon1 $dom1"
    fi
  else
    # They're within the same day.
    echo "$time1"
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
  python3 -c "
import random
octets = []
octet = random.randint(0, 63)*4
octets.append('{:02x}'.format(octet))
for i in range(5):
  octet = random.randint(0, 255)
  octets.append('{:02x}'.format(octet))
print(':'.join(octets))"
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
  python3 -c 'import sys
if len(sys.argv) <= 1 or sys.argv[1] == "-h" or sys.argv[1] == "--help":
  sys.stderr.write("Usage: asciitobin hello\n")
  sys.exit(1)
for i in range(1, len(sys.argv)):
  word = sys.argv[i]
  for char in word:
    print("{0:08b}".format(ord(char)), end=" ")
  if i < len(sys.argv)-1:
    print("00100000", end=" ")
print()' "$@"
}
function bintoascii {
  python3 -c 'import sys
if len(sys.argv) <= 1 or sys.argv[1] == "-h" or sys.argv[1] == "--help":
  sys.stderr.write("Usage: bintoascii 011011010111010101100101011100100111010001100101\n")
  sys.exit(1)
binstr = "".join(sys.argv[1:])
for i in range(0, len(binstr), 8):
  byte = binstr[i:i+8]
  integer = int(byte, 2)
  print(chr(integer), end="")
print()' "$@"
}
function title {
  if [[ $# == 1 ]] && [[ $1 == '-h' ]]; then
    echo 'Usage: $ title [New terminal title]
Default: "Terminal"' >&2
    return 1
  fi
  if [[ $# == 0 ]]; then
    TITLE="$Host"
  else
    TITLE="$@"
  fi
  echo -ne "\033]2;$TITLE\007"
}
# I keep typing this for some reason.
alias tilte=title
function test_rate {
  if [[ "$#" == 2 ]]; then
    local fpos_rate="$1"
    local prevalence="$2"
  else
    echo 'Usage: $ test_rate false_positive_rate population_prevalence
E.g. for a 10% false positive rate and a 2% true population infection rate:
$ test_rate 10 2' >&2
    return 1
  fi
  local false_positives=$(calc "1000*$fpos_rate*100")
  local true_positives=$(calc "1000*$prevalence*100")
  local likelihood=$(calc "100*$true_positives/($true_positives+$false_positives)")
  printf "Chance a positive result means you're actually positive: %0.1f%%\n" "$likelihood"
}
# Convert a number of seconds into a human-readable time string.
# Example output: "1 year 33 days 2:43:06"
function human_time {
  if [[ "$#" -lt 1 ]] || [[ "$#" -gt 2 ]] || [[ "$1" == '-h' ]] || [[ "$1" == '--help' ]]; then
    echo "Usage: human_time num_sec [format]
Formats:
            2309487     |   23094   |     2309     |     23
clock: 26 days 17:31:27 | 6:24:54   | 38:29        | 23
1unit: 3.8 weeks        | 6.4 hours | 38.5 minutes | 23 seconds" >&2
    return 1
  fi
  local sec_total="$1"
  local format="clock"
  if [[ "$#" -ge 2 ]]; then
    format="$2"
  fi
  local sec=$((sec_total % 60))
  local min_total=$((sec_total/60))
  local min=$((min_total % 60))
  local hr_total=$((min_total/60))
  local hr=$((hr_total % 24))
  local days_total=$((hr_total/24))
  local days=$((days_total % 365))
  local years_total=$((days_total/365))
  local formatter=
  case "$format" in
    clock)
      formatter=human_time_clock;;
    1unit)
      formatter=human_time_1unit;;
    *)
      echo "Error: Invalid format \"$format\"" >&2
      return 1;;
  esac
  $formatter "$sec_total" "$sec" "$min" "$hr" "$days" "$years_total"
}
function human_time_clock {
  local sec_total sec min hr days years
  read sec_total sec min hr days years <<< "$@"
  if [[ $days == 1 ]]; then
    local days_str='1 day '
  else
    local days_str="$days days "
  fi
  if [[ $years == 1 ]]; then
    local years_str='1 year '
  else
    local years_str="$years years "
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
  if [[ $years == 0 ]]; then
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
function human_time_1unit {
  local sec_total sec min hr days years
  read sec_total sec min hr days years <<< "$@"
  local unit quantity
  if [[ "$sec_total" -lt 60 ]]; then
    unit='second'
    quantity="$sec_total"
  elif [[ "$sec_total" -lt 3600 ]]; then
    unit='minute'
    quantity=$(echo "$sec_total/60" | bc -l)
  elif [[ "$sec_total" -lt 86400 ]]; then
    unit='hour'
    quantity=$(echo "$sec_total/60/60" | bc -l)
  elif [[ "$sec_total" -lt 864000 ]]; then
    unit='day'
    quantity=$(echo "$sec_total/60/60/24" | bc -l)
  elif [[ "$sec_total" -lt 3456000 ]]; then
    unit='week'
    quantity=$(echo "$sec_total/60/60/24/7" | bc -l)
  elif [[ "$sec_total" -lt 31536000 ]]; then
    unit='month'
    quantity=$(echo "$sec_total/60/60/24/30.5" | bc -l)
  else
    unit='year'
    quantity=$(echo "$sec_total/60/60/24/365" | bc -l)
  fi
  local rounded=$(printf '%0.1f' "$quantity")
  local integered=$(printf '%0.0f' "$quantity")
  if [[ "$rounded" == "$integered.0" ]]; then
    rounded="$integered"
  fi
  output="$rounded $unit"
  if [[ "$rounded" != 1 ]]; then
    output="${output}s"
  fi
  echo "$output"
}
function time_to_sec {
  if [[ "$#" != 1 ]] || [[ "$1" == '-h' ]]; then
    echo "Usage: time_to_sec 15m
Returns number of seconds.
Input format same as for 'sleep' command, except integers only." >&2
    return 1
  fi
  local time="$1"
  local quantity unit
  read quantity unit <<< $(echo "$time" | sed -En 's/^([0-9]+)([smhd])?$/\1 \2/p')
  if ! [[ "$quantity" ]]; then
    echo "Error: Invalid time string \"$time\"" >&2
    return 1
  fi
  multiplier=1
  case "$unit" in
    m)
      multiplier=60;;
    h)
      multiplier=3600;;
    d)
      multiplier=86400;;
  esac
  echo $((quantity*multiplier))
}


##### Bioinformatics #####

if [[ $Host == ruby || $Host == main ]]; then
  true #alias igv='java -Xmx4096M -jar ~/bin/igv.jar'
elif [[ $Host == nsto2 ]]; then
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
function quals {
  # From: http://blog.wittelab.ucsf.edu/visualizing-fastq-file-quality-scores/
  local command='n;n;n;y/!"#$%&'\''()*+,-.\/0123456789:;<=>?@ABCDEFGHIJKL/▁▁▁▁▁▁▁▁▂▂▂▂▂▃▃▃▃▃▄▄▄▄▄▅▅▅▅▅▆▆▆▆▆▇▇▇▇▇██████/'
  if [[ "$#" -ge 1 ]]; then
    if [[ "$1" == '-h' ]]; then
      echo "Usage: quals reads.fq" >&2
      echo "       head reads.fq | quals" >&2
      echo "Displays FASTQ reads with visual quality scores." >&2
      return 1
    else
      sed -e "$command" "$1"
    fi
  else
    sed -e "$command"
  fi
}
if ! which align.py >/dev/null 2>/dev/null && ! which align-mem.sh >/dev/null 2>/dev/null; then
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
fi
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
  python3 -c "import random
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
    python3 -c "print(100.0*$1/$2)"
  }
  function _print_stat {
    local len=$((${#2}+1))
    printf "%-30s%6.2f%% % ${len}d\n" "$1:" $(_pct $3 $2) $3
  }
  for bam in $@; do
    if ! [[ -s "$bam" ]]; then
      echo "Missing or empty file: $bam" >&2
      continue
    fi
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
if [[ $Host == scofield ]]; then
  aklog bx.psu.edu
fi
# Make it easier to run a command from a Docker container, auto-mounting the current directory so
# it's accessible from inside the container.
alias dockdir='docker run -v $(pwd):/dir/'
# Slurm commands
if [[ $Host == ruby ]]; then
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
if [[ $Host == scofield ]]; then
  pathadd /galaxy/home/$USER/bin
elif [[ $InCluster ]]; then
  true  # inherited from scofield
else
  pathadd ~/bin start
fi
if [[ $Host == lion ]]; then
  pathadd /opt/local/bin
fi
if [[ -d "$HOME/bx/bin" ]]; then
  pathadd "$HOME/bx/bin"
fi
pathadd /sbin
pathadd /usr/sbin
pathadd /usr/local/sbin
pathadd $HOME/.local/bin start
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

if [[ "$USER" == root ]]; then
  export PS1="\e[0;31m[\d] \u@\h: \w\e[m\n# "
fi
# Retitle window only if it's an interactive session. Otherwise, this can cause scp to hang.
if [[ $- == *i* ]] && [[ $Host != uniport ]]; then
  title $Host
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
    if [[ $Host == uniport ]] || [[ $Host == ndojo ]] || [[ $Host == nbs ]] || [[ $InCluster ]]; then
      true  # screen unavailable or undesired
    elif [[ $Host == brubeck || $Host == scofield || $Host == desmond ]] \
        && [[ -x ~/code/pagscr-me.sh ]]; then
      exec ~/code/pagscr-me.sh -RR -S auto
    elif which screen >/dev/null 2>/dev/null; then
      exec screen -RR -S auto
    fi
  fi
else
  export PS1='$ps1_timer_show\e[$pecol[\d]\e[m \e[0;32m\u@\h:\e[m \e[$pgcol\w\e[m\n$ps1_branch\$ '
fi

BashrcRan=true
