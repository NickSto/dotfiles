#!/usr/bin/env bash

if [[ $# -gt 0 ]]; then
  echo "This will try to detect the distro and kernel, and it will print them on
two separate lines, like:
    \$ $(basename $0)
    ubuntu
    linux
You can read them into variable names at once like this:
    \$ read distro kernel <<< \$("$(basename $0)")
    \$ echo \$distro: \$kernel
    ubuntu: linux" >&2
  exit 1
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
    fi
    # Last-ditch: check for any /etc/*-release and derive it from the *
    if [[ ! $distro ]]; then
      if ls /etc/*-release >/dev/null 2>/dev/null; then
        distro=$(ls /etc/*-release 2>/dev/null | sed -E 's#/etc/([^-]+)-release#\1#' | head -n 1)
      # If even that doesn't work, just call it "linux"
      else
        distro="linux"
      fi
    fi
  # If the uname -s output is unrecognized, just use that
  elif [[ $kernel ]]; then
    distro="$kernel"
  fi
# Even uname -s didn't work? Give up.
else
  distro="unknown"
fi

# Print results, unless we're being sourced
if [[ $0 != 'bash' ]]; then
  echo $distro
  echo $kernel
fi
