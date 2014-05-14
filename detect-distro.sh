# Do your best to detect the distro
# Uses info from http://www.novell.com/coolsolutions/feature/11251.html
# and http://en.wikipedia.org/wiki/Uname

kernel=$(uname -s 2>/dev/null | tr '[:upper:]' '[:lower:]')
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
elif [[ $kernel =~ linux ]]; then
  if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    distro="$ID"
  fi
  if [[ ! $distro ]]; then
    distro=$(ls /etc/*-release 2>/dev/null | sed -E 's#/etc/([^-]+)-release#\1#' | head -n 1)
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
elif [[ "$kernel" ]]; then
  distro="$kernel"
else
  distro="unknown"
fi
