#!/usr/bin/env bash
# best compilation of techniques and information so far:
# https://unix.stackexchange.com/questions/92199/how-can-i-reliably-get-the-operating-systems-name
# /etc/os-release adoption, as of August 2012:
# Angstrom, ArchLinux, Debian, Fedora, Frugalware, Gentoo, OpenSUSE, Mageia
# (according to http://www.linuxquestions.org/questions/slackware-14/any-chance-of-slackware-including-etc-os-release-4175423210/#post4760009)

_print=""
if [[ $# -gt 0 ]]; then
  if [[ $1 == '-p' ]]; then
    _print="true"
  elif [[ "$1" == '-h' ]] || [[ "$1" == '--help' ]]; then
    # We have to actively check if $1 is -h because sometimes, when executed via .bashrc in a
    # login shell, $1 is set to the path to the user's .profile.
    _script=$(basename $0)
    printf "Best-effort detection of the distro and kernel.
Source this to set \$Os, \$Distro, and \$Kernel to the detected values:
    source %s
Or you can execute it, and get have it print the values (one per line), with the
-p option:
    \$ read Os Distro Kernel <<< \$(%s -p)
    \$ echo \$Os \$Distro \$Kernel
    ubuntu linux\n" $_script $_script >&2
    exit 1
  fi
fi

# filename prefixes to exclude when determining from files like /etc/*-release
_EXCLUDED='os|lsb|system'

# Do your best to detect the distro
# Uses info from http://www.novell.com/coolsolutions/feature/11251.html
# and http://en.wikipedia.org/wiki/Uname
#TODO: Use $OSTYPE

# Try to get the kernel name from uname
if Kernel=$(uname -s 2>/dev/null | tr '[:upper:]' '[:lower:]'); then
  # Fuzzy-match some known non-linux uname -s outputs and assign standard names
  # for them.
  Os="unix"
  if [[ $Kernel =~ freebsd ]]; then
    Distro="freebsd"
  elif [[ $Kernel =~ bsd$ ]]; then
    Distro="bsd"
  elif [[ $Kernel =~ darwin ]]; then
    Distro="osx"
  elif [[ $Kernel =~ cygwin ]]; then
    Distro="cygwin"
    Os="windows"
  elif [[ $Kernel =~ mingw ]]; then
    Distro="mingw"
    Os="windows"
  elif [[ $Kernel =~ sunos ]]; then
    Distro="solaris"
  elif [[ $Kernel =~ haiku ]]; then
    Distro="haiku"
    Os="beos"
  # If it's a linux kernel, try to determine the distro from files in /etc
  elif [[ $Kernel =~ linux ]]; then
    # Preferred method: /etc/os-release cross-distro standard
    if [[ -f /etc/os-release ]]; then
      source /etc/os-release
      Distro="$ID"
      if ! [[ $Distro ]]; then
        if [[ $TAILS_PRODUCT_NAME ]]; then
          Distro="tails"
        fi
      fi
    fi
    # Check for files like /etc/*-release, /etc/*_release,
    # /etc/*-version, or /etc/*_version, and derive the distro from the *
    if ! [[ $Distro ]]; then
      _files=$(ls /etc/*[-_]{release,version} 2>/dev/null | grep -Ev "/etc/($_EXCLUDED)[-_]")
      if [[ $files ]]; then
        # Extract from the first filename.
        Distro=$(printf '%s\n' "$_files" | sed -E 's#/etc/([^-_]+).*#\1#' | head -n 1)
      fi
    fi
    # Lastly, try /etc/lsb-release (not always helpful, even when present)
    if ! [[ $Distro ]]; then
      if source /etc/lsb-release 2>/dev/null; then
        Distro="$DISTRIB_ID"
      fi
    fi
    # If even that doesn't work, just call it "linux"
    if ! [[ $Distro ]]; then
      Distro="linux"
    fi
  # If the uname -s output is unrecognized, just use it unmodified
  elif [[ $Kernel ]]; then
    Distro="$Kernel"
    Os="unknown"
  fi
# Even uname -s didn't work? Give up.
else
  Distro="unknown"
  Os="unknown"
fi

if [[ $_print ]]; then
  printf '%s\n%s\n%s\n' "$Os" "$Distro" "$Kernel"
fi
