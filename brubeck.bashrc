# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# System wide functions and aliases
# Environment stuff goes in /etc/profile

# By default, we want this to get set.
umask 002

# are we an interactive shell?
if [ "$PS1" ]; then
    case $TERM in
	xterm*)
		if [ -e /etc/sysconfig/bash-prompt-xterm ]; then
			PROMPT_COMMAND=/etc/sysconfig/bash-prompt-xterm
		else
	    	PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/~}"; echo -ne "\007"'
		fi
		;;
	screen)
		if [ -e /etc/sysconfig/bash-prompt-screen ]; then
			PROMPT_COMMAND=/etc/sysconfig/bash-prompt-screen
		else
		PROMPT_COMMAND='echo -ne "\033_${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/~}"; echo -ne "\033\\"'
		fi
		;;
	*)
		[ -e /etc/sysconfig/bash-prompt-default ] && PROMPT_COMMAND=/etc/sysconfig/bash-prompt-default
	    ;;
    esac
    # Turn on checkwinsize
    shopt -s checkwinsize
    # set prompt
	PS1="[\u@\h \W]\\$ "
fi

if ! shopt -q login_shell ; then # We're not a login shell
	# Need to redefine pathmunge, it get's undefined at the end of /etc/profile
    pathmunge () {
		if ! echo $PATH | /bin/egrep -q "(^|:)$1($|:)" ; then
			if [ "$2" = "after" ] ; then
				PATH=$PATH:$1
			else
				PATH=$1:$PATH
			fi
		fi
	}

	if [ -d /etc/profile.d/ ]; then
		for i in /etc/profile.d/*.sh; do
			if [ -r "$i" ]; then
				. $i
			fi
		unset i
		done
	fi
	unset pathmunge
fi

# system path augmentation
test -f /afs/bx.psu.edu/service/etc/env.sh && . /afs/bx.psu.edu/service/etc/env.sh

# make afs friendlier-ish
if [ -d /afs/bx.psu.edu/service/etc/bash.d/ ]; then
	for file in /afs/bx.psu.edu/service/etc/bash.d/*.bashrc; do
	. $file
	done
fi



# User specific aliases and functions
alias lsl='ls -lFha'
alias lsld='ls -lFhad'
alias cdb='cd ~/scratch/bodymap'
alias targ='tar -zxvpf'
alias tarb='tar -jxvpf'
alias vib='vi ~/.bashrc'
alias awkt="awk -F '\t' -v OFS='\t'"
alias gatk="java -jar ~/bin/GenomeAnalysisTK.jar"

alias mountf='mount | perl -we '"'"'printf("%-25s %-25s %-25s\n","Device","Mount Point","Type"); for (<>) { if (m/^(.*) on (.*) type (.*) \(/) { printf("%-25s %-25s %-25s\n", $1, $2, $3); } }'"'"''
calc () {
  echo $@ | perl -we 'my $in = <STDIN>;
    chomp($in);
    if ($in =~ m#\(?-[\d.]+\)?\^-?\d+\.\d+#) {
      print "note: cannot raise a negative number to a decimal exponent with precision\n"
    }
    $in =~ s#([\d.]+)\^(-?\d+\.\d+)#e($2*l($1))#g;
    $in = chr(39).$in.chr(39);
    my $cmd = "echo $in | bc -l";
    print "\$ $cmd\n";
    print `$cmd`;'
}
vix () {
  if [ -e $1 ]; then
    vim $1
  else
    touch $1; chmod +x $1; vim $1
  fi
}
lc () {
  echo "$1" | tr '[:upper:]' '[:lower:]'
}
wcc () {
  wc=$(echo "$@" | wc -c)
  echo "$wc - 1" | bc -l
}
pg () {
    if pgrep -f $@ > /dev/null;
    then
        pgrep -f $@ | xargs ps -o user,pid,stat,rss,%mem,pcpu,args \
                               --sort -pcpu,-rss;
    else 
        exit 1;
    fi
}
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
vil () {
  vi $(deref "$1")
}

# If interactive, set $PS1 prompt format and enter a screen
if [ ! -z "$PS1" ]; then
  export PS1="[\d] \u@\h:\w\n\$ "
  if [ ! $STY ]; then
    export PATH=$PATH:~/code
#    exec screen -RR -S auto
    exec ~/code/pagscr-me.sh '-RR -S auto'
  fi
fi
