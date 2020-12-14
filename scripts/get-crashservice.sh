#!/usr/bin/env bash
if [ "x$BASH" = x ] || [ ! "$BASH_VERSINFO" ] || [ "$BASH_VERSINFO" -lt 4 ]; then
  echo "Error: Must use bash version 4+." >&2
  exit 1
fi
set -ue
unset CDPATH

ScriptDir=$(dirname "${BASH_SOURCE[0]}")
Usage="Usage: \$ $(basename "$0")"

function main {
  get_crashservice
}

function get_crashservice {
  service_exists=$(get_local_script 'service-exists.sh')
  if "$service_exists" -q code42; then
    echo sudo service code42
  elif "$service_exists" -q crashplan; then
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

function get_local_script {
  script_name="$1"
  if which "$script_name" >/dev/null 2>/dev/null; then
    echo "$script_name"
  elif [[ -x "$ScriptDir/$script_name" ]]; then
    echo "$ScriptDir/$script_name"
  else
    return 1
  fi
}

function fail {
  echo "$@" >&2
  exit 1
}

main "$@"
