#!/usr/bin/env bash
if [ "x$BASH" = x ] || [ ! "$BASH_VERSINFO" ] || [ "$BASH_VERSINFO" -lt 4 ]; then
  echo "Error: Must use bash version 4+." >&2
  exit 1
fi
set -ue
unset CDPATH

Usage="Usage: \$ $(basename "$0") service_name"

function main {
  # Read arguments.
  quiet=
  while getopts "qh" opt; do
    case "$opt" in
      q) quiet='true';;
      [h?]) fail "$Usage";;
    esac
  done
  service="${@:$OPTIND:1}"
  if ! [[ "$service" ]]; then
    fail "$Usage"
  fi
  # Look for service.
  if service_exists "$service"; then
    if ! [[ "$quiet" ]]; then
      echo "Service found!" >&2
    fi
    return 0
  else
    if ! [[ "$quiet" ]]; then
      echo "Service NOT found" >&2
    fi
    return 1
  fi
}

function service_exists {
  service="$1"
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
  exit 1
}

main "$@"
