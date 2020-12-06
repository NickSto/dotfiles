# A catalog of stuff I don't use anymore.

##### Aliases #####

alias vib="vim $BashrcDir/.bashrc"
alias noheader='grep -v "^#"'
alias veramount="veracrypt -t --truecrypt -k '' --protect-hidden=no"
alias mountv="sudo mount -t vboxsf -o uid=1000,gid=1000,rw shared $HOME/shared"


##### Functions and Misc #####

function vil {
  vi $(deref "$1")
}
# Swap caps lock and esc.
alias swapkeys="loadkeys-safe.sh && sudo loadkeys $HOME/aa/computer/keymap-loadkeys.txt"
# If an .xmodmap is present, source it to alter the keys however it says. Disable with noremap=1.
# This is possibly obsoleted by the loadkeys method above.
if [[ -f ~/.xmodmap ]] && [[ -z "$noremap" ]]; then
  xmodmap ~/.xmodmap
fi
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
alias minecraft="cd ~/src/minecraft && java -Xmx400M -Xincgc -jar $HOME/src/minecraft_server.jar nogui"
alias minelog='ssh vps "tail src/minecraft/server.log"'
alias mineme='ssh vps "cat src/minecraft/server.log" | grep -i nick | tail'
alias minelist="ssh vps 'screen -S minecraft -X stuff \"list\"; sleep 1; tail src/minecraft/server.log'"
alias minemem='ssh vps "if pgrep -f java >/dev/null; then pgrep -f java | xargs ps -o %mem; fi"']
if [[ "$Distro" == osx ]] || [[ "$Distro" == *bsd ]]; then
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
alias blockedips="grep 'UFW BLOCK' /var/log/ufw.log | sed -E 's/.* SRC=([0-9a-f:.]+) .*/\1/g' | sort -g | uniq -c | sort -rg -k 1"
# a quick shortcut to placing a script in the ~/bin dir
# only if the system supports readlink -f (BSD doesn't)
if readlink -f / >/dev/null 2>/dev/null; then
  function bin {
    ln -s $(readlink -f "$1") ~/bin/$(basename "$1")
  }
fi
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
function showdups {
  local line
  cat "$1" | while read line; do
    local notfirst=''
    grep -n "^$line$" "$1" | while read line; do
      if [ "$notfirst" ]; then echo "$line"; else notfirst=1; fi
    done
  done
}
function oneline {
  if [[ "$#" == 0 ]]; then
    tr -d '\n'
  else
    echo "$@" | tr -d '\n'
  fi
}


##### Bioinformatics #####

alias rdp='java -Xmx1g -jar ~/bin/MultiClassifier.jar'
alias gatk="java -jar ~/bin/GenomeAnalysisTK.jar"
alias qsh='source $HOME/src/qiime_software/activate.sh'
alias bcat="samtools view -h"
function align {
  local opts_default='-M -t 32'
  if [[ "$#" -lt 3 ]]; then
    echo "Usage: \$ align ref.fa reads_1.fq reads_2.fq [--other --bwa --options]
If you provide your own options, yours will replace the defaults ($opts_default).
For when align.py and align-mem.sh aren't available." 1>&2
    return 1
  fi
  local ref fastq1 fastq2 opts
  read ref fastq1 fastq2 opts <<< "$@"
  if ! [[ "$opts" ]]; then
    opts="$opts_default"
  fi
  local base=$(echo "$fastq1" | sed -E -e 's/\.gz$//' -e 's/\.fa(sta)?$//' -e 's/\.f(ast)?q$//' -e 's/_[12]$//')
  bwa mem "$opts" "$ref" "$fastq1" "$fastq2" > "$base.sam"
  samtools view -Sbu "$base.sam" | samtools sort - "$base"
  samtools index "$base.bam"
  echo "Final alignment is in: $base.bam"
}
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
function gatc {
  if [[ "$#" -gt 0 ]]; then
    echo "$1" | sed -E 's/[^GATCNgatcn]//g';
  else
    local data
    while read data; do
      echo "$data" | sed -E 's/[^GATCNgatcn]//g';
    done;
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
if [[ "$Host" == ruby ]]; then
  alias sfree='ssh bru sinfo -h -p general -t idle -o %n'
  alias scpus="ssh bru 'sinfo -h -p general -t idle,alloc -o "'"'"%n %C"'"'"' | tr ' /' '\t\t' | cut -f 1,3 | sort -k 1.3g"
  alias squeue='ssh bru squeue'
  alias squeuep="ssh bru 'squeue -o "'"'"%.7i %Q %.8u %.8T %.10M %11R %4h %j"'"'"' | sort -g -k 2"
else
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