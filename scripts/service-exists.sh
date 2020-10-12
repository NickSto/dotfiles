#!/usr/bin/env bash
if [ "x$BASH" = x ] || [ ! "$BASH_VERSINFO" ] || [ "$BASH_VERSINFO" -lt 4 ]; then
  echo "Error: Must use bash version 4+." >&2
  exit 1
fi
declare -A Sourced
if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
  Sourced["${BASH_SOURCE[0]}"]=
else
  Sourced["${BASH_SOURCE[0]}"]=true
fi
if ! [[ "${Sourced[${BASH_SOURCE[0]}]}" ]]; then
  set -ue
fi
unset CDPATH

Usage="Usage: \$ $(basename "$0") service_name"

function main {
  if service_exists "$@"; then
    echo "Service found!" >&2
    return 0
  else
    echo "Service NOT found" >&2
    return 1
  fi
}

function service_exists {
  if [[ "$#" -lt 1 ]] || [[ "$1" == '-h' ]] || [[ "$1" == '--help' ]]; then
    fail "$Usage"
  fi
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

function fail {
  echo "$@" >&2
  if [[ "${Sourced[${BASH_SOURCE[0]}]}" ]]; then
    return 1
  else
    exit 1
  fi
}

if ! [[ "${Sourced[${BASH_SOURCE[0]}]}" ]]; then
  main "$@"
fi
