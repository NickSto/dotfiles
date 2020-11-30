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

ScriptDir=$(dirname "${BASH_SOURCE[0]}")
source "$ScriptDir/service-exists.sh"

Usage="Usage: \$ $(basename "$0")"

function main {
  get_crashservice "$@"
}

function get_crashservice {
  if service_exists code42; then
    echo sudo service code42
  elif service_exists crashplan; then
    echo sudo service crashplan
  elif which CrashPlanEngine >/dev/null 2>/dev/null; then
    echo CrashPlanEngine
  elif [[ -f /usr/local/crashplan/bin/service.sh ]]; then
    echo sudo /usr/local/crashplan/bin/service.sh
  elif [[ -x "$HOME/src/crashplan/bin/CrashPlanEngine" ]]; then
    echo "$HOME/src/crashplan/bin/CrashPlanEngine"
  else
    echo "Error: Crashplan service not found and CrashPlanEngine command not found." >&2
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
