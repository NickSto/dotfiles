#!/usr/bin/env bash
if [ "x$BASH" = x ] || [ ! "$BASH_VERSINFO" ] || [ "$BASH_VERSINFO" -lt 4 ]; then
  echo "Error: Must use bash version 4+." >&2
  exit 1
fi
set -ue
unset CDPATH

ScriptDir=$(dirname "${BASH_SOURCE[0]}")
Usage="Usage: \$ $(basename "$0") [stop|start]
This will find the correct way to stop or start the background Crashplan service and do it for you."

function main {
  crashservice "$@"
}

function crashservice {
  if [[ "$#" -lt 1 ]] || [[ "$1" == '-h' ]] || [[ "$1" == '--help' ]]; then
    echo "$Usage" >&2
    return 1
  fi
  command="$1"
  service_exists=$(get_local_script 'service-exists.sh')
  if "$service_exists" -q crashplan; then
    sudo service crashplan "$command"
    if [[ "$command" == 'stop' ]] && "$service_exists" -q code42; then
      sudo service code42 "$command"
    fi
  elif "$service_exists" -q code42; then
    sudo service code42 "$command"
  elif which CrashPlanEngine >/dev/null 2>/dev/null; then
    CrashPlanEngine "$command"
  elif [[ -f /usr/local/crashplan/bin/service.sh ]]; then
    sudo /usr/local/crashplan/bin/service.sh "$command"
  elif [[ -x "$HOME/src/crashplan/bin/CrashPlanEngine" ]]; then
    "$HOME/src/crashplan/bin/CrashPlanEngine" "$command"
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
