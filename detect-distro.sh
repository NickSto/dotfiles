#!/usr/bin/env bash

print=""
if [[ $# -gt 0 ]]; then
  if [[ $1 == '-p' ]]; then
    print="true"
  else 
    echo "Best-effort detection of the distro and kernel.

Source this to set \$distro and \$kernel to the detected values:
    source $(basename $0)
Or you can execute it, and get have it print the values (one per line), with the
-p option:
    \$ read distro kernel <<< \$("$(basename $0)" -p)
    \$ echo \$distro \$kernel
    ubuntu linux" >&2
    exit 1
  fi
fi

# Do your best to detect the distro
# Uses info from http://www.novell.com/coolsolutions/feature/11251.html
# and http://en.wikipedia.org/wiki/Uname

# Try to get the kernel name from uname
if kernel=$(uname -s 2>/dev/null | tr '[:upper:]' '[:lower:]'); then
  # Fuzzy-match some known uname -s outputs and assign standard names for
  # non-linux kernels
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
  # If it's a linux kernel, try to determine the type from files in /etc
  elif [[ $kernel =~ linux ]]; then
    # Preferred method: /etc/os-release cross-distro standard
    if [[ -f /etc/os-release ]]; then
      source /etc/os-release
      distro="$ID"
    # Check for some known distro-specific filenames
    elif [[ -f /etc/debian_version ]]; then
      distro="debian"
    elif [[ -f /etc/redhat_version ]] || [[ -f /etc/redhat-release ]]; then
      distro="redhat"
    elif [[ -f /etc/slackware-version ]]; then
      distro="slackware"
    elif [[ -f /etc/SUSE-release ]]; then
      distro="suse"
    fi
    # Last-ditch: check for files like /etc/*-release, /etc/*_release,
    # /etc/*-version, or /etc/*_version, and derive it from the *
    if [[ ! $distro ]]; then
      files=$(ls /etc/*[-_]release 2>/dev/null) || files=$(ls /etc/*[-_]version 2>/dev/null)
      if [[ $files ]]; then
        # extract from first filename, excluding ones like lsb-release and system-release
        distro=$(echo "$files" | grep -Ev '/etc/(lsb|system)[-_]' | sed -E 's#/etc/([^-_]+).*#\1#' | head -n 1)
      fi
    fi
    # If even that doesn't work, just call it "linux"
    if [[ ! $distro ]]; then
      distro="linux"
    fi
  # If the uname -s output is unrecognized, just use that
  elif [[ $kernel ]]; then
    distro="$kernel"
  fi
# Even uname -s didn't work? Give up.
else
  distro="unknown"
fi

if [[ $print ]]; then
  echo $distro
  echo $kernel
fi
