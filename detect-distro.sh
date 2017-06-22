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
  else
    _script=$(basename $0)
    printf "Best-effort detection of the distro and kernel.

Source this to set \$distro and \$kernel to the detected values:
    source %s
Or you can execute it, and get have it print the values (one per line), with the
-p option:
    \$ read distro kernel <<< \$(%s -p)
    \$ echo \$distro \$kernel
    ubuntu linux\n" $_script $_script >&2
    exit 1
  fi
fi

# filename prefixes to exclude when determining from files like /etc/*-release
_EXCLUDED='os|lsb|system'

# Do your best to detect the distro
# Uses info from http://www.novell.com/coolsolutions/feature/11251.html
# and http://en.wikipedia.org/wiki/Uname

# Try to get the kernel name from uname
if kernel=$(uname -s 2>/dev/null | tr '[:upper:]' '[:lower:]'); then
  # Fuzzy-match some known non-linux uname -s outputs and assign standard names
  # for them.
  if [[ $kernel =~ freebsd ]]; then
    distro="freebsd"
  elif [[ $kernel =~ bsd$ ]]; then
    distro="bsd"
  elif [[ $kernel =~ darwin ]]; then
    distro="osx"
  elif [[ $kernel =~ cygwin ]]; then
    distro="cygwin"
  elif [[ $kernel =~ mingw ]]; then
    distro="mingw"
  elif [[ $kernel =~ sunos ]]; then
    distro="solaris"
  elif [[ $kernel =~ haiku ]]; then
    distro="haiku"
  # If it's a linux kernel, try to determine the distro from files in /etc
  elif [[ $kernel =~ linux ]]; then
    # Preferred method: /etc/os-release cross-distro standard
    if [[ -f /etc/os-release ]]; then
      source /etc/os-release
      distro="$ID"
      if ! [[ $distro ]]; then
        if [[ $TAILS_PRODUCT_NAME ]]; then
          distro="tails"
        fi
      fi
    fi
    # Check for files like /etc/*-release, /etc/*_release,
    # /etc/*-version, or /etc/*_version, and derive the distro from the *
    if ! [[ $distro ]]; then
      _files=$(ls /etc/*[-_]{release,version} 2>/dev/null | grep -Ev "/etc/($_EXCLUDED)[-_]")
      if [[ $files ]]; then
        # Extract from the first filename.
        distro=$(printf '%s\n' "$_files" | sed -E 's#/etc/([^-_]+).*#\1#' | head -n 1)
      fi
    fi
    # Lastly, try /etc/lsb-release (not always helpful, even when present)
    if [[ ! $distro ]]; then
      if source /etc/lsb-release 2>/dev/null; then
        distro="$DISTRIB_ID"
      fi
    fi
    # If even that doesn't work, just call it "linux"
    if [[ ! $distro ]]; then
      distro="linux"
    fi
  # If the uname -s output is unrecognized, just use it unmodified
  elif [[ $kernel ]]; then
    distro="$kernel"
  fi
# Even uname -s didn't work? Give up.
else
  distro="unknown"
fi

if [[ $_print ]]; then
  printf '%s\n%s\n' $distro $kernel
fi
