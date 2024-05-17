if [[ "$BashrcRan" ]]; then
  echo '.bashrc already sourced. Unset $BashrcRan to source again.' >&2
  return 1
fi

# Are we root? Be conservative.
if [[ "$USER" == root ]] || [[ "$EUID" == 0 ]] || [[ "$UID" == 0 ]]; then
  IsRoot=true
else
  IsRoot=
fi

##### Detect host #####

#TODO: Just use $HOSTNAME, if portable enough.
Host=$(hostname -s 2>/dev/null || hostname)

# supported hosts:
#   iebdev[0-9]{2} lmem[0-9]{2} nsto[2-9] yarr (and all my personal laptops)
# deprecated:
#   nn[0-9]+ brubeck scofield desmond uniport lion cyberstar

# supported distros:
#   ubuntu debian freebsd
# partial support:
#   GitBash cygwin osx

# Are we on an NCBI server?
InNcbi=
if printf '%s' "$Host" | grep -qE '^(iebdev|lmem)[0-9][0-9]$'; then
  InNcbi=true
fi

##### Determine distro #####

# Avoid unexpectd $CDPATH effects
# https://bosker.wordpress.com/2012/02/12/bash-scripters-beware-of-the-cdpath/
unset CDPATH

# Reliably get the actual parent dirname of a link (no readlink -f in BSD)
function realdirname {
  echo $(cd $(dirname $(readlink "$1")) && pwd)
}

function _get_dirname {
  filename="$1"
  # Is it a link or real file?
  if [[ -h "$filename" ]]; then
    realdirname "$filename"
  elif grep -qE '^##BashrcDir:' "$filename"; then
    sed -En 's/^##BashrcDir://p' "$filename"
  else
    printf '%s' "$HOME"
  fi
}

# Determine directory with .bashrc files
if [[ -d "$HOME" ]]; then
  cd "$HOME"
fi
if [[ -f .bashrc ]]; then
  BashrcDir=$(_get_dirname .bashrc)
elif [[ -f .bash_profile ]]; then
  BashrcDir=$(_get_dirname .bash_profile)
else
  BashrcDir="$HOME/code/dotfiles"
fi
cd - >/dev/null

# Set distro based on known hostnames
case "$Host" in
  aknot)     Distro="ubuntu";;
  ruby)      Distro="ubuntu";;
  main)      Distro="ubuntu";;
  yarr)      Distro="ubuntu";;
  nsto[2-9]) Distro="ubuntu";;
  *)  # Unrecognized host? Run detection script.
    if [[ -f "$BashrcDir/detect-distro.sh" ]] && ! [[ "$IsRoot" ]]; then
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
  if [[ "$usb_drive" ]]; then
    export HOME="$usb_drive"
    cd "$HOME"
  fi
fi

# If we're in the webserver, cd to the webroot.
if [[ "${Host:0:4}" == nsto ]] && [[ "${#Host}" -le 5 ]]; then
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

fi

# enable color support of ls and also add handy aliases
if [[ -x /usr/bin/dircolors ]] && ! [[ "$IsRoot" ]]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi



#################### My stuff ####################


##### Bash options #####

# Don't put duplicate lines or lines starting with a space in the history.
HISTCONTROL=ignoreboth
HISTSIZE=2000       # max # of lines to keep in active history
HISTFILESIZE=5000   # max # of lines to record in history file
# Make the `history` command display the date and time of each command.
HISTTIMEFORMAT='%a %d %b %I:%M:%S %p  '
shopt -s histappend # append to the history file, don't overwrite it
# check the window size after each command and update LINES and COLUMNS.
shopt -s checkwinsize
# Make "**" glob all files and subdirectories recursively
# Does not exist in Bash < 4.0, so silently fail.
shopt -s globstar 2>/dev/null || true


### Environment variables ###

# Set directory for my special data files
DataDir="$HOME/.local/share/nbsdata"
# Set for easy access to cron logs.
OutLog="$HOME/.local/share/nbsdata/cron-stdout.log"
ErrLog="$HOME/.local/share/nbsdata/cron-stderr.log"
# Set my default text editor
export EDITOR=vim
# Allow disabling ~/.python_history.
# See https://unix.stackexchange.com/questions/121377/how-can-i-disable-the-new-history-feature-in-python-3-4
export PYTHONSTARTUP="$HOME/.pythonrc"
# In Git Bash, sometimes $USERNAME is set instead of $USER
if ! [[ "$USER" ]] && [[ "$USERNAME" ]]; then
  USER="$USERNAME"
fi


##### Simple Aliases #####

if [[ "$Distro" == ubuntu || "$Distro" == cygwin || "$Distro" == debian || "$Distro" == centos ]]; then
  alias ll='ls -lFhAb --color=auto --group-directories-first'
  alias lld='ls -lFhAbd --color=auto --group-directories-first'
else
  # long options don't work on FreeBSD or OS X
  alias ll='ls -lFhAb'
  alias lld='ls -lFhAbd'
fi
alias sll=sl # choo choo
alias mv='mv -i'
alias cp='cp -i'
alias targ='tar -zxvpf'
alias tarb='tar -jxvpf'
alias pseudo=sudo
alias awkt="awk -F '\t' -v OFS='\t'"
alias pingg='ping -c 1 google.com'
alias curlip='curl -s icanhazip.com'
alias rsynca='rsync -e ssh --delete --itemize-changes -zaXAv'
alias now='date +%s'
alias pipp='python3 -m pip'


##### Complex Aliases #####

alias temp="sensors | grep -A 3 '^coretemp-isa-0000' | tail -n 1 | awk '{print \$3}' | sed -E -e 's/^\+//' -e 's/\.[0-9]+//'"
alias chromem='totalmem.sh -n Chrome /opt/google/chrome/'
alias foxmem='totalmem.sh -n Firefox /usr/lib/firefox/'
alias bitcoin="curl -s 'https://min-api.cryptocompare.com/data/price?fsym=BTC&tsyms=USD' | jq .USD"
alias ethereum="curl -s 'https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD' | jq .USD"
alias dfh='df -h | fit-columns.py -se -x 1,start,/dev/loop -x 1,tmpfs -x 1,udev -x 1,start,/dev/mapper/vg-var -x 1,AFS'


##### Functions Etc #####

if [[ "$Distro" == mingw ]]; then
  function mouse {
    nohup notepad++.exe -multiInst "$@" >/dev/null 2>/dev/null &
  }
else
  function mouse {
    nohup mousepad "$@" >/dev/null 2>/dev/null &
  }
fi
function cpu {
  local cores=$(grep -Ec '^ *core id' /proc/cpuinfo 2>/dev/null)
  ps aux | awk -v "cores=$cores" -v "user=$USER" -v human=1 -f "$BashrcDir/scripts/cpu-mem.awk"
}
alias mem=cpu
function geoip {
  if [[ "$1" ]]; then
    ip="$1"
  else
    ip=$(curlip)
  fi
  curl -s "http://ipinfo.io/$ip" | jq -r '.city + ", " + .region + ", " + .country + ": " + .org'
}
function mountf {
  mount | sort -k 3 | awk 'BEGIN {
    print "Device", "Mount", "Type"
  }
  $2 == "on" {
    print $1, $3, $5
  }
  $2 == "(deleted)" && $3 == "on" {
    print $1, $4, $5
  }' | fit-columns.py -se -x 2,start,/snap/ -x 3,start,cgroup
}
function longurl {
  if which longurl.py >/dev/null 2>/dev/null; then
    longurl.py -bc
  else
    url=$(xclip -out -sel clip)
    echo "$url"
    curl -LIs "$url" | grep '^[Ll]ocation' | cut -d ' ' -f 2
  fi
}
function trash {
  if which trash.py >/dev/null 2>/dev/null; then
    trash.py "$@"
  elif which trash-put >/dev/null 2>/dev/null; then
    trash-put "$@"
  else
    echo "Falling back to manual ~/.trash directory." >&2
    if ! [[ -d "$HOME/.trash" ]]; then
      if ! mkdir "$HOME/.trash"; then
        echo "Error creating ~/.trash" >&2
        return 1
      fi
    fi
    mv "$@" "$HOME/.trash"
  fi
}
function diffdir {
  local Usage="Usage: \$ diffdir [-t] dir1 dir2
-t: Ignore differences in dates modified."
  if [[ "$#" -lt 2 ]] || [[ "$#" -gt 3 ]] || [[ "$1" == '-h' ]] || [[ "$1" == '--help' ]]; then
    echo "$Usage" >&2
    return 1
  fi
  local ignore_time=''
  if [[ "$#" == 3 ]]; then
    if [[ "$1" == '-t' ]]; then
      ignore_time='true'
    else
      echo "$Usage" >&2
      return 1
    fi
    shift
  fi
  local dir1="$1" dir2="$2"
  printf '%-11s %-11s\n' "$dir1" "$dir2"
  local file
  ls -1A "$dir1" "$dir2" | sort -u | while read file; do
    if [[ "$file" == '' ]] || [[ "$file" == "$dir1:" ]] || [[ "$file" == "$dir2:" ]]; then
      continue
    fi
    local date1='' time1='' size1='' present1=''
    local path present size date time result1 result2
    for path in "$dir1/$file" "$dir2/$file"; do
      if [[ -e "$path" ]]; then
        present='present'
        size=$(du -sh --apparent-size "$path" | awk '{print $1}')
        read date time < <(stat -c '%y' "$path" | awk '{print substr($0, 1, 10), substr($0, 12, 8)}')
      else
        present=''
        size=''
        date=''
        time=''
      fi
      if ! [[ "$size1" ]]; then
        present1="$present"
        size1="$size"
        date1="$date"
        time1="$time"
      fi
    done
    local present2="$present" size2="$size" date2="$date" time2="$time"
    if [[ "$present1" != "$present2" ]]; then
      if [[ "$present1" ]]; then
        result1="$size1"
        result2='MISSING'
      else
        result1='MISSING'
        result2="$size2"
      fi
    elif [[ "$size1" != "$size2" ]]; then
      result1="$size1"
      result2="$size2"
    elif [[ "$ignore_time" ]]; then
      continue
    elif [[ "$date1" != "$date2" ]]; then
      result1="$date1"
      result2="$date2"
    elif [[ "$time1" != "$time2" ]]; then
      result1="$time1"
      result2="$time2"
    else
      continue
    fi
    printf '%11s%11s  %s\n' "$result1" "$result2" "$file"
  done
}
function kerb {
  local realm="$1"
  if [[ "$#" == 0 ]] || [[ "$1" == '-h' ]] || [[ "$1" == '--help' ]]; then
    echo "Usage: \$ kerb realm" >&2
    return 1
  fi
  kinit -l 90d "$realm"
}
# Search all encodings for strings, raise minimum length to 5 characters
function stringsa {
  strings -n 5 -e s "$1"
  strings -n 5 -e b "$1"
  strings -n 5 -e l "$1"
}
function updaterc {
  if ! which git >/dev/null 2>/dev/null; then
    wget 'https://raw.githubusercontent.com/NickSto/dotfiles/master/.bashrc' -O "$BashrcDir/.bashrc"
  elif [[ "$Distro" == *bsd ]]; then
    (cd "$BashrcDir" && git pull && cd -)
  else
    git "--work-tree=$BashrcDir" "--git-dir=$BashrcDir/.git" pull
  fi
}
# Make it easier to run a command from a Docker container, auto-mounting the current directory so
# it's accessible from inside the container.
alias dockdir='docker run -v $(pwd):/dir/'
function crashpause {
  local DefaultTimeout='2h'
  if ! which tmpcmd.sh >/dev/null 2>/dev/null; then
    echo "Error: tmpcmd.sh not found." >&2
    return 1
  fi
  if [[ "$#" -ge 1 ]]; then
    if [[ "$1" == '-h' ]]; then
      echo "Usage: \$ crashpause [time]
time: How long before restarting CrashPlan automatically. Use the same syntax as for the 'sleep'
      command. Default: '$DefaultTimeout'." >&2
      return 1
    else
      local timeout="$1"
    fi
  else
    local timeout=2h
  fi
  local old_title="$Title"
  title crashpause
  local prefix rest
  read prefix rest <<< $(get-crashservice.sh)
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
function logip {
  local LogFile="$HOME/aa/computer/logs/ips.tsv"
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
  local ip=$(curlip)
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
function lnx {
  if [[ "$#" -le 0 ]] || [[ "$1" == '-h' ]] || [[ "$1" == '--help' ]]; then
    echo "Usage: \$ lnx target [link/path]
For use when you don't have the ability to make a symlink (cough Windows).
This will create a two line shell script at link/path which calls target, passing through the args
it was given. If no link/path is given, then, like ln, this will use the basename of the target and
put the \"link\" in the current directory. The target can be a relative path from the current
directory, instead of from the link's directory. It will be resolved to an absolute path anyway." >&2
    return 1
  fi
  local target_raw="$1"
  if [[ "$#" -ge 2 ]]; then
    local link_path="$2"
  else
    local link_path=$(basename "$target")
  fi
  if [[ -e "$link_path" ]] || [[ -h "$link_path" ]]; then
    echo "Error: A file already exists at the link path: $link_path" >&2
    return 1
  fi
  if [[ -e "$target_raw" ]]; then
    local target=$(realpath "$target_raw")
  elif [[ "$#" -ge 2 ]]; then
    # Allow the user to call it like ln -s, with the target relative to the link's directory.
    local link_dir=$(dirname "$link_path")
    local target=$(realpath "$link_dir/$target_raw")
  fi
  if ! [[ -e "$target" ]]; then
    echo "Error: Target not found: $target_raw" >&2
    return 1
  fi
  printf '%s\n' '#!/usr/bin/env bash' > "$link_path"
  printf '%s "$@"\n' "$target" >> "$link_path"
  chmod u+x "$link_path"
}
# Add to PATH if the directory exists and it's not already in the PATH.
function pathadd {
  local dir="$1"
  local location="$2"
  if ! [[ -d "$dir" ]]; then
    return
  fi
  # Handle empty PATH.
  if ! [[ "$PATH" ]]; then
    export PATH="$dir"
    return
  fi
  # Check if it's already present.
  if echo "$PATH" | tr : '\n' | grep -qE "^$dir\$"; then
    return
  fi
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
alias gitgraph='git log --oneline --abbrev-commit --all --graph --decorate --color'
alias gig='nohup giggle >/dev/null 2>/dev/null &'
function gitswitch {
  if [[ -f "$HOME/.ssh/id_rsa-code" ]]; then
    mv "$HOME/.ssh/id_rsa-code"{,.pub} "$HOME/.ssh/keys" && \
    mv "$HOME/.ssh/keys/id_rsa-generic"{,.pub} "$HOME/.ssh" && \
    echo "Switched to NickSto"
  elif [[ -f "$HOME/.ssh/id_rsa-generic" ]]; then
    mv "$HOME/.ssh/id_rsa-generic"{,.pub} "$HOME/.ssh/keys" && \
    mv "$HOME/.ssh/keys/id_rsa-code"{,.pub} "$HOME/.ssh" && \
    echo "Switched to Qwerty0"
  fi
}
function gitlast {
  local commits=1
  if [[ "$#" -ge 1 ]]; then
    if [[ "$1" == '-h' ]]; then
      echo 'Usage: $ gitlast [num_commits]' >&2
      return 1
    else
      commits="$1"
    fi
  fi
  git log --oneline -n "$commits"
}
function gitdiff {
  diff_num=1
  if [[ "$#" -ge 1 ]]; then
    if [[ "$1" == '-h' ]]; then
      echo 'Usage: $ gitdiff [diff_num]
Show a diff for the last commit (between it and the previous).
Or, give a number for which diff before it to show (e.g. "2" gives the diff
between the 3rd and 2nd to last commits).' >&2
      return 1
    else
      diff_num="$1"
    fi
  fi
  local commit1 commit2
  read commit2 commit1 <<< $(git log -n $((diff_num+1)) --pretty=format:%h | tail -n 2 | tr '\n' '\t')
  git diff "$commit1" "$commit2"
} # 13
function gitgrep {
  local Usage='Usage: $ gitgrep [options] query
Do a recursive search for an exact string anywhere under the current directory.
Current features: ignores .git and .venv directories, truncates lines to current terminal width.'
  if [[ "$#" == 0 ]]; then
    echo "$Usage" >&2
    return 1
  fi
  for arg in "$@"; do
    if [[ "$arg" == '-h' ]] || [[ "$arg" == '--help' ]]; then
      echo "$Usage" >&2
      return 1
    fi
  done
  grep -RIF --exclude-dir .git --exclude-dir .venv "$@" | awk "{print substr(\$0, 1, $COLUMNS)}"
}
function vix {
  if ! [[ -e "$1" ]]; then
    touch "$1"
  fi
  chmod +x "$1"
  vim "$1"
}
function calc {
  if [[ "$#" -gt 0 ]]; then
    python3 -c "from math import *; print($*)"
  else
    python3 -i -c 'from math import *'
  fi
}
function pct {
  if [[ "$#" -lt 2 ]] || [[ "$1" == '-h' ]] || [[ "$1" == '--help' ]]; then
    echo 'Usage: $ pct num1 num2
Prints 100*num1/(num1+num2)' >&2
    return 1
  fi
  python3 -c "print(f'{($1)/($1+$2):%}')"
}
function wcc {
  if [[ "$#" == 0 ]]; then
    wc -c
  else
    echo -n "$@" | wc -c
  fi
}
function uc {
  if [[ "$#" -gt 0 ]]; then
    echo "$@" | tr '[:lower:]' '[:upper:]'
  else
    tr '[:lower:]' '[:upper:]'
  fi
}
function lc {
  if which lower.b >/dev/null 2>/dev/null; then
    if [[ "$#" -gt 0 ]]; then
      echo "$@" | lower.b
    else
      lower.b
    fi
  else
    if [[ "$#" -gt 0 ]]; then
      echo "$@" | tr '[:upper:]' '[:lower:]'
    else
      tr '[:upper:]' '[:lower:]'
    fi
  fi
}
alias tc=titlecase
function parents {
  if [[ "$#" -ge 1 ]]; then
    local pid="$1"
  else
    local pid="$$"
  fi
  while [[ "$pid" -gt 0 ]]; do
    ps -o pid,args -p "$pid" | tail -n +2
    pid=$(ps -o ppid -p "$pid" | tail -n +2 | tr -d ' ')
  done
}
# readlink -f except it handles commands on the PATH too
function deref {
  local Usage="deref cmd"
  local verbose=
  if [[ "$#" == 1 ]]; then
    local arg="$1"
  elif [[ "$#" -gt 1 ]]; then
    if [[ "$1" == '-h' ]]; then
      echo "$Usage" >&2
      return 1
    elif [[ "$1" == '-v' ]]; then
      verbose='true'
    else
      echo "Invalid argument '$1'" >&2
      return 1
    fi
    local arg="$2"
  else
    echo "$Usage" >&2
    return 1
  fi
  local path=$(which "$arg" 2>/dev/null)
  if ! [[ "$verbose" ]]; then
    # readlink -f will follow the chain of links to the end in one step.
    readlink -f "$path"
    return "$?"
  fi
  #TODO: This fails on relative links. For example, currently the contents of the link /usr/bin/gcc
  #      is "gcc-9". I'd have to resolve that to /usr/bin/gcc-9 before proceeding.
  while [[ "$path" ]]; do
    echo "$path"
    local old_path="$path"
    path=$(readlink "$old_path")
  done
}
function parent_find {
  if [[ "$#" != 1 ]] || [[ "$1" == '-h' ]] || [[ "$1" == '--help' ]]; then
    echo "\$ parent_find filename
Searches for 'filename' in the current directory or any parent directory. If it's found, it prints
its absolute path and returns 0. Otherwise, it returns 1." >&2
    return 1
  fi
  local filename="$1"
  local dir=$(pwd)
  while true; do
    if [[ -e "$dir/$filename" ]]; then
      printf '%s\n' "$dir/$filename"
      return 0
    elif [[ "$dir" == / ]]; then
      return 1
    fi
    dir=$(dirname "$dir")
  done
}
function venv {
  if [[ "$#" -ge 1 ]] && [[ "$1" == '-h' ]]; then
    echo "Usage: \$ venv
Looks for a .venv directory in the current directory or its parents, and activates the first one it
finds." >&2
    return 1
  fi
  local venv=$(parent_find .venv)
  if ! [[ "$venv" ]]; then
    echo "No .venv directory found." >&2
    return 1
  else
    echo "Activating virtualenv in $venv" >&2
  fi
  if [[ -f "$venv/bin/activate" ]]; then
    source "$venv/bin/activate"
  else
    echo "Error: no .venv/bin/activate file found." >&2
    return 1
  fi
}
function eta {
  local Usage="Usage: eta <start_time> <start_count> <current_count> <goal_count>
       --- or ---
       eta <goal_count> <start_count>
       eta <current_count>"
  if [[ "$#" -lt 1 ]] || [[ "$1" == '-h' ]] || [[ "$1" == '--help' ]]; then
    echo "$Usage" >&2
    return 1
  elif [[ "$#" == 2 ]] || [[ "$#" == 3 ]]; then
    if [[ "$1" == start ]]; then
      # Backward compatibility with old command line format.
      shift
    fi
    start_time=$(date +%s)
    goal="$1"
    start_count="$2"
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
  local now=$(date +%s)
  if [[ "$current" == "$start_count" ]]; then
    echo 'No progress yet!' >&2
    return 1
  elif [[ "$(calc "$current > $start_count")" == 'True' ]]; then
    local progress=$(calc "$current-$start_count")
    local togo=$(calc "$goal-$current")
  else
    local progress=$(calc "$start_count-$current")
    local togo=$(calc "$current-$goal")
  fi
  local elapsed=$(calc "$now-$start_time")
  local sec_left=$(calc "$togo*$elapsed/$progress")
  local eta=$(date -d "now + $sec_left seconds")
  local eta_diff=$(date_parts_diff "$eta")
  local min_left=$(calc "'{:0.2f}'.format($sec_left/60)")
  echo -e "$eta_diff\t($min_left min from now)"
}
function date_parts_diff {
  if [[ "$#" -lt 1 ]] || [[ "$1" == '-h' ]]; then
    echo "Usage: date_parts_diff date1 [date2]
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
function timer {
  if [[ "$#" -lt 1 ]] || [[ "$1" == '-h' ]] || [[ "$1" == '--help' ]]; then
    echo "Usage: timer delay [message]
The 'delay' should be parseable by the 'sleep' command.
This will sleep for 'delay', then notify-send the message and play a tone.
The message doesn't need to be quoted - it can be the rest of the arguments." >&2
    return 1
  fi
  local delay_str="$1"
  local message='Timer finished!'
  if [[ "$#" -ge 2 ]]; then
    shift
    message="$@"
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
  notify -s "$message"
}
function notify {
  local Usage="Usage: notify [-s] [message]"
  local DefaultSound="$HOME/aa/audio/30 second silence and tone.mp3"
  local sound=
  while [[ "${1:0:1}" == '-' ]]; do
    if [[ "$1" == '-h' ]] || [[ "$1" == '--help' ]]; then
      echo "$Usage" >&2
      return 1
    elif [[ "$1" == '-s' ]]; then
      sound="$DefaultSound"
    fi
    shift
  done
  if [[ "$#" -ge 1 ]]; then
    local message="$1"
    echo "$message"
    notify-send "$message"
  elif ! [[ "$sound" ]]; then
    echo "$Usage" >&2
    return 1
  fi
  if [[ "$sound" ]]; then
    if [[ -f "$sound" ]]; then
      vlc --play-and-exit "$sound" 2>/dev/null
    else
      echo "Sound file not found: $sound" >&2
    fi
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
function wifirssi {
  local samples=3
  if [[ "$#" -ge 1 ]]; then
    if [[ "$1" == '-h' ]] || [[ "$1" == '--help' ]] || [[ "$#" -gt 1 ]]; then
      echo "Usage: \$ wifirssi [samples]
Get the wifi signal strength (in dBm), averaging over the given number of samples (default: $samples)
taken 1 second apart." >&2
      return 1
    else
      samples="$1"
    fi
  fi
  local i=0
  local total=0
  while [[ "$i" -lt "$samples" ]]; do
    sample=$(iwconfig 2>/dev/null | sed -En 's/^.*Signal level=(-?[0-9]+) *dBm.*$/\1/p')
    echo "$sample dBm"
    total=$((total+sample))
    sleep 1
    i=$((i+1))
  done
  echo "Average: $((total/samples)) dBm"
}
function getip {
  if [[ "$#" -gt 0 ]]; then
    echo "Usage: \$ getip
Parse the ifconfig command to get your interface names, IP addresses, and MAC addresses.
Prints one line per interface, tab-delimited:
interface-name    MAC-address    IPv4-address    IPv6-address
Does not work on OS X (totally different ifconfig output)." >&2
    return 1
  fi
  ip addr | awk -f "$BashrcDir/scripts/getip.awk"
}
alias getmac=getip
function getinterface {
  if [[ "$#" -gt 0 ]]; then
    echo "Usage: \$ getinterface
Print the name of the interface on the default route (like \"wlan0\" or \"wlp58s0\")" >&2
    return 1
  fi
  getip | awk '{print $1}'
}
function iprange {
  ipwraplib.py mask_ip "$@" | tr -d "(',')" | tr ' ' '\n'
}
function spoofmac() {
  local Usage="Usage: \$ spoofmac [mac]
Set your wifi MAC address to the given one, or a random one otherwise."
  if [[ "$#" -gt 0 ]]; then
    if [[ "$1" == '-h' ]]; then
      echo "$Usage" >&2
      return 1
    elif echo "$1" | grep -qE '[0-9A-Fa-f:]{17}'; then
      local mac="$1"
    else
      echo "Error: Invalid MAC provided: \"$1\"." >&2
      echo "$Usage" >&2
      return 1
    fi
  else
    local mac=$(randmac)
  fi
  local wifi_iface=$(getip | grep -Eo '^wl\S+' | head -n 1)
  if ! [[ "$wifi_iface" ]]; then
    echo "Error: Cannot find your wifi interface name. Maybe it's off right now?" >&2
    return 1
  fi
  echo "Remember your current MAC address: "$(getip | awk '$1 == "'$wifi_iface'" {print $2}')
  echo "Setting your MAC to $mac. You'll probably have to toggle your wifi after this."
  sudo ip link set dev "$wifi_iface" down
  sudo ip link set dev "$wifi_iface" address "$mac"
  sudo ip link set dev "$wifi_iface" up
}
function passphrase {
  local words=7
  local wordlist="$HOME/aa/misc/eff_large_wordlist.txt"
  if [[ "$#" -ge 1 ]]; then
    if [[ "$1" == '-h' ]] || [[ "$1" == '--help' ]]; then
      echo "Usage: passphrase [[wordlist.txt] num_words]" >&2
      return 1
    fi
    if [[ "$#" == 1 ]]; then
      words="$1"
    elif [[ "$#" -ge 2 ]]; then
      wordlist="$1"
      words="$2"
    fi
  fi
  if ! [[ -f "$wordlist" ]]; then
    echo "Error: Wordlist file not found: $wordlist" >&2
    return 1
  fi
  echo $(shuf --random-source /dev/random -n "$words" "$wordlist" | cut -f 2)
}
function scramble {
  if [[ "$#" -ge 1 ]]; then
    if [[ "$1" == '-h' ]] || [[ "$1" == '--help' ]]; then
      echo "Usage: scramble word [word2 [word3]]" >&2
      return 1
    fi
    echo "$@" | fold -w 1 | shuf | tr -d '\n'
  else
    fold -w 1 | shuf | tr -d '\n'
  fi
}
# What are the most common number of columns?
function columns {
  echo " totals|columns"
  awkt '{print NF}' "$1" | sort -g | uniq -c | sort -rg -k 1
}
function sumcolumn {
  local Usage='Get totals of a specified column.
Usage: $ sumcolumn 3 file.tsv [file2.tsv [file3.tsv [..]]]
       $ cat file.tsv | sumcolumn 2'
  if [[ "$#" -lt 1 ]] || [[ "$1" == '-h' ]]; then
    echo "$Usage" >&2
    return 1
  fi
  local col="$1"
  shift
  if ! printf '%s' "$col" | grep -qE '^[0-9]+$'; then
    echo "Error: column \"$col\" not an integer." >&2
    echo "$Usage" >&2
    return 1
  fi
  awk -F '\t' '{tot += $'"$col"'} END {print tot}' "$@"
}
function sumcolumns {
  if [[ "$#" == 1 ]] && [[ "$1" == '-h' ]]; then
    echo 'Get totals of all columns in stdin or in all filename arguments.
Lines beginning with a # are ignored, as are non-numeric values anywhere.
Usage: $ sumcolumns file.tsv [file2.tsv [file3.tsv [..]]]
       $ cat file.tsv | sumcolumns' >&2
    return 1
  fi
  awk -f "$BashrcDir/scripts/sumcolumns.awk" "$@"
}
function maxcolumns {
  if [[ "$#" == 1 ]] && [[ "$1" == '-h' ]]; then
    echo 'Get maximum values of all columns in stdin or in all filename arguments.
Lines beginning with a # are ignored, as are non-numeric values anywhere.
Usage: $ maxcolumns file.tsv [file2.tsv [file3.tsv [..]]]
       $ cat file.tsv | maxcolumns' >&2
    return 1
  fi
  awk -f "$BashrcDir/scripts/maxcolumns.awk" "$@"
}
function average {
  if [[ "$#" -gt 0 ]] && ( [[ "$1" == '-h' ]] || [[ "$1" == '--help' ]] ); then
    echo 'Average a series of numbers. Can read multiple stdin lines.
Usage: $ average num1 [num2 [num3 [..]]]
       $ echo num1 num2 num3 | average' >&2
    return 1
  fi
  _collect_args "$@" | awk '{
    for (i=1; i<=NF; i++) {
      sum += $i
      count++
    }
  }
  END {
    print sum/count
  }'
}
function _collect_args {
  # Collect arguments from either the command line or stdin (but not both) and print to stdout.
  # Usage: `_collect_args "$@" | do_something`
  if [[ "$#" -gt 0 ]]; then
    printf '%s\n' "$@"
  else
    while read line; do
      printf '%s ' "$line"
    done
    printf '\n'
  fi
}
function repeat {
  if [[ "$#" -lt 2 ]] || ! [[ "$2" =~ ^[0-9]+$ ]]; then
    echo "Usage: repeat [string] [number of repeats]" 1>&2
    return
  fi
  local i=0
  while [[ "$i" -lt "$2" ]]; do
    printf '%s' "$1"
    i=$((i+1))
  done
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
  in=$(echo "$1" | tr [:lower:] [:upper:])
  echo "ibase=16;obase=A;$in" | bc
}
function base64tohex {
  python3 -c "import base64
binary = base64.b64decode('$1')
hex_bytes = base64.b16encode(binary)
print(str(hex_bytes, 'utf8').lower())"
}
function hextobase64 {
  python3 -c "import base64
binary = base64.b16decode('$1'.upper())
b64_bytes = base64.b64encode(binary)
print(str(b64_bytes, 'utf8'))"
}
function title {
  if [[ "$#" == 1 ]] && [[ "$1" == '-h' ]]; then
    echo 'Usage: $ title [New terminal title]
Default: "Terminal"' >&2
    return 1
  fi
  if [[ "$#" == 0 ]]; then
    Title="$Host"
  else
    Title="$@"
  fi
  printf "\033]2;$Title\007"
}
# I keep typing this for some reason.
alias tilte=title
function geotime {
  if [[ "$#" == 0 ]] || [[ "$#" -gt 2 ]] || [[ "$1" == '-h' ]] || [[ "$1" == '--help' ]]; then
    echo 'Usage: $ geotime total [current]
Estimate how much longer it will take for GeoTracker to export all my tracks.
`current` defaults to 0.' >&2
    return 1
  fi
  local total="$1"
  local current=0
  if [[ "$#" -ge 2 ]]; then
    current="$2"
  fi
  # Testing new equations:
  # $ end=1688409096
  # $ total=575
  # $ awkt "function est(amt) {return (amt/16.8)^(100/51)}
  #     {print \$2, ($end-\$1)/60, "actual"; print \$2, (est($total) - est(\$2))/60, "estimate"}'
  #     new4.tsv | scatterplot.py -g 3 -S 4 --width 1280 --height 960 -X 'Tracks done' -Y ETA
  local current_elapsed=$(calc "(($current/9.28)**(100/51))")
  local total_eta=$(calc "(($total/9.28)**(100/51))")
  local eta=$(calc "$total_eta-$current_elapsed")
  local eta_time=$(date -d "now + $eta seconds")
  printf 'Done in %0.1f minutes (at %s)\n' "$(calc "$eta/60")" "$eta_time"
}
function lsof_clean {
  # This is intended to output as close to the default lsof output as possible, but actually, like,
  # comprehensible (tab-delimited). But surprise, of course it turns out it's not even really
  # possible. There are no -F equivalents for a lot of the fields, and many are presented
  # differently in the -F output than the text format. This is also intended to avoid truncating
  # fields as much, but apparently things like the COMMAND are already truncated when the kernel
  # gives it to lsof. In the case of Ubuntu 20.04, the COMMAND is limited to 15 characters.
  echo -e 'COMMAND\tPID\tTID\tTASKCMD\tUID\tFD\tTYPE\tSIZE\tINODE\tNAME'
  # Note: The -F output lists the data for each process once, then lists all the files
  # it's got open without repeating the process data. So it's not as simple as "for each line of the
  # regular output, it prints the value of each applicable field".
  #TODO: This is still buggy. It still seems to be omitting the process data sometimes.
  sudo lsof -FcpKMuftsin | awk '
    BEGIN {
      ORDER = "cpKMuftsin"
      PTYPES = "cpKMu"
      FTYPES = "ftsin"
    }
    {
      type = substr($0,1,1)
      data = substr($0,2)
      if (index(PTYPES, type)) {
        if (record[type]) {
          print_line(record)
          delete record
        }
        record[type] = data
      }
      if (index(FTYPES, type)) {
        if (record[type]) {
          print_line(record)
          delete_file_data(record)
        }
        file[type] = data
      }
      record[type] = data
    }
    function print_line(record) {
      for (i=1; i<=length(ORDER); i++) {
        type = substr(ORDER,i,1)
        printf("%s", record[type])
        if (i < length(ORDER)) {
          printf("\t")
        } else {
          printf("\n")
        }
      }
    }
    function delete_file_data(record) {
      for (i=1; i<=length(FTYPES); i++) {
        type = substr(FTYPES,i,1)
        delete record[type]
      }
    }'
}
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
      formatter=_human_time_clock;;
    1unit)
      formatter=_human_time_1unit;;
    *)
      echo "Error: Invalid format \"$format\"" >&2
      return 1;;
  esac
  $formatter "$sec_total" "$sec" "$min" "$hr" "$days" "$years_total"
}
function _human_time_clock {
  local sec_total sec min hr days years
  read sec_total sec min hr days years <<< "$@"
  if [[ "$days" == 1 ]]; then
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
  if [[ "$min" -lt 10 ]] && [[ "$min_total" -ge 60 ]]; then
    min_str="0$min:"
  fi
  if [[ "$sec" -lt 10 ]] && [[ "$sec_total" -ge 60 ]]; then
    sec_str="0$sec"
  fi
  if [[ "$years" == 0 ]]; then
    years_str=''
    if [[ "$days" == 0 ]]; then
      days_str=''
      if [[ "$hr" == 0 ]]; then
        hr_str=''
        if [[ "$min" == 0 ]]; then
          min_str=''
          if [[ "$sec" == 0 ]]; then
            sec_str='0'
          fi
        fi
      fi
    fi
  fi
  printf '%s\n' "$years_str$days_str$hr_str$min_str$sec_str"
}
function _human_time_1unit {
  local sec_total sec min hr days years
  read sec_total sec min hr days years <<< "$@"
  local unit quantity
  if [[ "$sec_total" -lt 60 ]]; then
    unit='second'
    quantity="$sec_total"
  elif [[ "$sec_total" -lt 3600 ]]; then
    unit='minute'
    quantity=$(printf '%s' "$sec_total" | awk '{print $1/60}')
  elif [[ "$sec_total" -lt 86400 ]]; then
    unit='hour'
    quantity=$(printf '%s' "$sec_total" | awk '{print $1/60/60}')
  elif [[ "$sec_total" -lt 864000 ]]; then
    unit='day'
    quantity=$(printf '%s' "$sec_total" | awk '{print $1/60/60/24}')
  elif [[ "$sec_total" -lt 3456000 ]]; then
    unit='week'
    quantity=$(printf '%s' "$sec_total" | awk '{print $1/60/60/24/7}')
  elif [[ "$sec_total" -lt 31536000 ]]; then
    unit='month'
    quantity=$(printf '%s' "$sec_total" | awk '{print $1/60/60/24/30.5}')
  else
    unit='year'
    quantity=$(printf '%s' "$sec_total" | awk '{print $1/60/60/24/365}')
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
  printf '%s\n' "$output"
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
  read quantity unit <<< $(printf '%s' "$time" | sed -En 's/^([0-9]+)([smhd])?$/\1 \2/p')
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
  printf '%s\n' $((quantity*multiplier))
}


##### Bioinformatics #####

alias seqlen="bioawk -c fastx '{ print \$name, length(\$seq) }'"
alias readsfa='grep -Ec "^>"'
function readsfq {
  local fq lines
  local exe=$(which readsfq 2>/dev/null)
  if [[ "$exe" ]]; then
    "$exe" "$@"
  elif [[ "$#" -ge 1 ]]; then
    local total=0
    for fq in "$@"; do
      lines=$(wc -l "$fq" | cut -f 1 -d ' ')
      total=$(echo "$total + $lines/4" | bc)
    done
    echo "$total"
  else
    lines=$(wc -l | cut -f 1 -d ' ')
    echo "$lines/4" | bc
  fi
}
function revcomp {
  if [[ "$#" == 0 ]]; then
    tr 'ATGCatgc' 'TACGtacg' | rev
  else
    echo "$1" | tr 'ATGCatgc' 'TACGtacg' | rev
  fi
}
function dna {
  local length=200
  if [[ "$#" -ge 1 ]]; then
    length="$1"
  fi
  python3 -c "import random; print(''.join([random.choice('ACGT') for i in range($length)]))"
}
# Get some quality stats on a BAM using samtools
function bamsummary {
  function _pct {
    python3 -c "print(100.0*$1/$2)"
  }
  function _print_stat {
    local len=$((${#2}+1))
    printf "%-30s%6.2f%% % ${len}d\n" "$1:" $(_pct "$3" "$2") "$3"
  }
  for bam in "$@"; do
    if ! [[ -s "$bam" ]]; then
      echo "Missing or empty file: $bam" >&2
      continue
    fi
    echo -e "\t$bam:"
    local total=$(samtools view -c "$bam")
    printf "%-39s%d\n" "total alignments:" "$total"
    _print_stat "unmapped reads  (-f 4)" "$total" $(samtools view -c -f 4 "$bam")
    _print_stat "not proper pair (-F 2)" "$total" $(samtools view -c -F 2 "$bam")
    _print_stat "  MAPQ 0 alignments" "$total"  $(echo "$total"-$(samtools view -c -q 1 "$bam") | bc)
    _print_stat "< MAPQ 20 alignments" "$total" $(echo "$total"-$(samtools view -c -q 20 "$bam") | bc)
    _print_stat "< MAPQ 30 alignments" "$total" $(echo "$total"-$(samtools view -c -q 30 "$bam") | bc)
    _print_stat "2ndary alignments   (-f 256)"  "$total" $(samtools view -c -f 256 "$bam")
    _print_stat "chimeric alignments (-f 2048)" "$total" $(samtools view -c -f 2048 "$bam")
    _print_stat "ambiguous alignments" "$total" $(samtools view "$bam" | awk -F '\t' '$5 == 0' | grep -c -E $'\t''XA:Z:')
  done
  unset -f _pct
  unset -f _print_stat
}


##### Root bailout #####

# There's too much stuff below that executes too much code.
# For safety, let's avoid executing all of that as root.
if [[ "$IsRoot" ]]; then
  export PS1='\e[0;31m[\d] \u@\h: \w\e[m\n\$ '
  title ROOT
  BashrcRan=true
  return 0
fi


##### PS1 prompt #####

# Color red on last command failure.
function prompt_exit_color {
  if [[ "$?" == 0 ]]; then
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
  # Some commands (usually environments you enter) will change the title.
  # Afterward, reset the title automatically.
  if [[ "$Title" ]]; then
    title "$Title"
  fi
}
# Gather info on the git repo, if we're in one.
# This is all in one function so we only run the git command once
# (could take a while in large repos).
function prompt_git_info {
  pgcol='0;32m' # cyan
  ps1_branch=
  # Check if we're even in a git repo first. This saves time on slow filesystems by avoiding the
  # call to `git status`.
  if ! parent_find .git >/dev/null; then
    return
  fi
  local info=$(git status --porcelain --branch 2>/dev/null)
  if ! [[ "$info" ]]; then
    return
  fi
  # Color the prompt differently if there are modified, tracked files.
  if printf '%s' "$info" | grep -qE '^ M'; then
    pgcol='0;33m' # yellow
  fi
  # Show the branch if we're not on "master".
  local branch=$(printf '%s' "$info" | head -n 1 | sed -E -e 's/^## //' -e 's/^(.+)\.\.\..*$/\1/')
  if [[ "$branch" != master ]]; then
    ps1_branch="$branch "
  fi
}
# timer from https://stackoverflow.com/a/1862762/726773
timer_thres=10
function timer_start {
  # $SECONDS is a shell built-in: the total number of seconds it's been running.
  timer_sec="${timer_sec:-$SECONDS}"
}
function timer_stop {
  LastCmdTime=$((SECONDS-timer_sec))
  ps1_timer_show=''
  if [[ "$LastCmdTime" -ge "$timer_thres" ]]; then
    ps1_timer_show="$(time_format "$LastCmdTime") "
  fi
  unset timer_sec
}
# format a number of seconds into a readable time
function time_format {
  local seconds="$1"
  local minutes=$((seconds/60))
  local hours=$((minutes/60))
  seconds=$((seconds - minutes*60))
  minutes=$((minutes - hours*60))
  if [[ "$minutes" -lt 1 ]]; then
    printf '%ds' "$seconds"
  elif [[ $hours -lt 1 ]]; then
    printf '%dm%ds' "$minutes" "$seconds"
  else
    printf '%dh%dm' "$hours" "$minutes"
  fi
}
trap 'timer_start' DEBUG
# $PROMPT_COMMAND is a shell built-in which is executed just before $PS1 is displayed.
# NOTE: `prompt_exit_color` must be first or the color will be based on the exit code of whatever is
#       placed before it! And `timer_stop` must be last or it will display the time *between*
#       commands, not of individual commands!
PROMPT_COMMAND='prompt_exit_color;prompt_set_title;prompt_git_info;history -a;timer_stop'


##### Application-specific stuff #####

# Perl crap to enable CPAN modules installed to $HOME.
export PERL5LIB="$HOME/perl5/lib/perl5"
export PERL_LOCAL_LIB_ROOT="$HOME/perl5"
export PERL_MB_OPT="--install_base \"$HOME/perl5\""
export PERL_MM_OPT="INSTALL_BASE=$HOME/perl5"
pathadd "$PATH:$HOME/perl5/bin"

# Homebrew
export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
export HOMEBREW_CELLAR="/home/linuxbrew/.linuxbrew/Cellar"
export HOMEBREW_REPOSITORY="/home/linuxbrew/.linuxbrew/Homebrew"
export MANPATH="/home/linuxbrew/.linuxbrew/share/man${MANPATH+:$MANPATH}:"
export INFOPATH="/home/linuxbrew/.linuxbrew/share/info:${INFOPATH:-}"
pathadd /home/linuxbrew/.linuxbrew/bin
pathadd /home/linuxbrew/.linuxbrew/sbin


##### Things to execute directly on session start #####

# Stuff I don't want to post publicly on Github. Still should be universal, not machine-specific.
if [[ -f "$HOME/.bashrc_private" ]]; then
  source "$HOME/.bashrc_private"
fi
# Stuff specific to a particular machine that I don't want to shoehorn into this file.
if [[ -f "$HOME/.bashrc_single" ]]; then
  source "$HOME/.bashrc_single"
fi

# Add bin directories to PATH.
pathadd "$HOME/bin" start
pathadd /sbin
pathadd /usr/sbin
pathadd /usr/local/sbin
pathadd "$HOME/.local/bin" start
pathadd "$BashrcDir/scripts"

# Conda stuff
function _find_conda {
  # Add only one Conda path, and prefer 3 over 2, and ~/src over ~/
  # Find it in a function to avoid polluting the shell with temporary variables.
  local dir path
  for dir in src/installations/ ''; do
    path="$HOME/${dir}miniconda3"
    if [[ -x "$path/bin/conda" ]]; then
      printf '%s' "$path"
      return 0
    fi
  done
  return 1
}
CondaDir="$(_find_conda)"
if [[ "$CondaDir" ]]; then
  if [[ "$InNcbi" ]]; then
    # The version of Conda installed there doesn't put the right path in the PATH.
    pathadd "$CondaDir/bin" start
  elif [[ -f "$CondaDir/etc/profile.d/conda.sh" ]]; then
    # Manually do the stuff `conda init` puts in your .bashrc.
    # Normally it evals the output of `conda shell.bash hook`. As of conda 4.11.0, that output is
    # identical to $CondaDir/etc/profile.d/conda.sh, except it also activates the conda environment
    # "base". I'd prefer to live in the real world and opt into a conda environment when I want, so
    # I'll just source conda.sh myself.
    source "$CondaDir/etc/profile.d/conda.sh"
  else
    # The code Conda generates adds its bin directory to the start of your PATH, but I'd rather it
    # be at the end so that other versions are preferred.
    pathadd "$CondaDir/bin"
  fi
fi

# a more "sophisticated" method for determining if we're in a remote shell
# check if the system supports the right ps parameters and if parents is able to
# climb the entire process hierarchy
if ps -o comm= -p 1 >/dev/null 2>/dev/null && [[ $(parents | tail -n 1) == "init" ]]; then
  for process in $(parents); do
    if [[ "$process" == sshd || "$process" == slurmstepd ]]; then
      remote="true"
    fi
  done
else
  if [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]; then
    remote="true"
  fi
fi

# Retitle window only if it's an interactive session. Otherwise, this can cause scp to hang.
if [[ "$-" == *i* ]]; then
  title "$Host"
fi

# If it's a remote shell, change $PS1 prompt format and enter a screen.
if [[ "$remote" ]]; then
  export PS1='${ps1_timer_show}\e[${pecol}[\d]\e[m \u@\h: \w\n$ps1_branch\$ '
  # Enter a screen, UNLESS:
  # 1. ! "$STY": We're already in a screen (IMPORTANT to avoid infinite loops).
  # 2. -t 1: We're not attached to a real terminal.
  # 3. $LC_NO_SCREEN != true: The user has requested not to enter a screen.
  #    - Set via: $ LC_NO_SCREEN=true ssh -o SendEnv=LC_NO_SCREEN me@destination
  # 4. ! -f ~/NOSCREEN: The user has requested not to enter a screen (backup method).
  if ! [[ "$STY" ]] && [[ -t 1 ]] && [[ "$LC_NO_SCREEN" != true ]] && ! [[ -f "$HOME/NOSCREEN" ]] \
    && which screen >/dev/null 2>/dev/null; then
      screen -r || exec screen -S auto
  fi
else
  export PS1='$ps1_timer_show\e[$pecol[\d]\e[m \e[0;32m\u@\h:\e[m \e[$pgcol\w\e[m\n$ps1_branch\$ '
fi

BashrcRan=true
