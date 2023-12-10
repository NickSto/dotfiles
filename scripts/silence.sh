#!/usr/bin/env bash
if [ "x$BASH" = x ] || [ ! "$BASH_VERSINFO" ] || [ "$BASH_VERSINFO" -lt 4 ]; then
  echo "Error: Must use bash version 4+." >&2
  exit 1
fi
unset CDPATH
if [[ "$SUDO_USER" ]]; then
  User="$SUDO_USER"
else
  User="$USER"
fi
set -u

ScriptDir=$(dirname "${BASH_SOURCE[0]}")
SilenceRel=".local/share/nbsdata/SILENCE"
Silence="$HOME/$SilenceRel"
Usage="Usage: \$ $(basename "$0") [option]
Silences background services and creates silence file $Silence
If you are already silenced (as determined by the SILENCE file), this will give you the option
to unsilence with a prompt.
Options:
-u: Unsilence without prompting.
-f: Silence again, even if SILENCE file indicates you're already silenced.
-w: Silence, then pause until you to tell it to unsilence. Useful for some services that require
    sudo, so you can run this script with sudo and not be prompted again.
-H: Force using this directory as \$HOME. Even without this option, this script should automatically
    detect when it's being run under sudo and set the \$HOME back to the real user's home.
    But this could be useful if that doesn't work.
-v: Verbose mode.
Returns 0 when silenced, 2 when unsilenced, and 1 on error."

#TODO: Turn off Ubuntu connectivity checking.


function main {
  # Read arguments.
  command=
  verbose=
  home="$(get_home)"
  while getopts "ufwvH:h" opt; do
    case "$opt" in
      u) command='unsilence';;
      f) command='force';;
      w) command='wait';;
      v) verbose='true';;
      H) home="$OPTARG";;
      [h?]) fail "$Usage";;
    esac
  done
  silence_file="$home/$SilenceRel"

  if [[ "$command" == "" ]] || [[ "$command" == 'force' ]]; then
    if [[ -f "$silence_file" ]] && ! [[ "$command" == 'force' ]]; then
      read -p "You're currently silenced! Use -f to force silencing again or type \"louden\" to unsilence! " response
      if [[ "$response" == 'louden' ]]; then
        unsilence_services "$silence_file"
      else
        echo "Aborting!"
        return 1
      fi
    else
      silence_services "$silence_file"
    fi
  elif [[ "$command" == 'unsilence' ]]; then
    unsilence_services "$silence_file"
  elif [[ "$command" == 'wait' ]]; then
    silence_services "$silence_file"
    echo "Press  [enter] to unsilence."
    echo "Or hit [Ctrl+C] to exit without unsilencing"
    read
    unsilence_services "$silence_file"
  fi
}

function silence_services {
  if [[ "$#" -ge 1 ]]; then
    silence_file="$1"
  else
    silence_file="$Silence"
  fi
  echo "Silencing.."
  failure=
  # Dropbox
  echo "Killing Dropbox.."
  if ! silence_dropbox; then
    failure=true
  fi
  # Snap daemon (often maintains a connection) (listening for updates?)
  echo "Killing snapd.."
  if ! silence_snapd; then
    failure=true
  fi
  # CrashPlan
  echo "Killing CrashPlan.."
  if ! silence_crashplan; then
    failure=true
  fi
  # Results and silence file
  if [[ "$failure" ]]; then
    echo "Error silencing some services!" >&2
    return 1
  else
    touch "$silence_file"
    echo 'Silenced!'
    return 0
  fi
}

function unsilence_services {
  if [[ "$#" -ge 1 ]]; then
    silence_file="$1"
  else
    silence_file="$Silence"
  fi
  echo "Unsilencing.."
  rm -f "$silence_file"
  failure=
  # Dropbox
  echo "Starting Dropbox.."
  if ! unsilence_dropbox; then
    failure=true
  fi
  # Snap Daemon
  echo "Starting snapd.."
  if ! unsilence_snapd; then
    failure=true
  fi
  # Crashplan
  echo "Starting CrashPlan.."
  if ! unsilence_crashplan; then
    failure=true
  fi
  # Results and silence file
  if [[ "$failure" ]]; then
    echo "Error unsilencing some services!" >&2
    return 1
  else
    echo "Unsilenced!"
    return 0
  fi
}

# Silencing and unsilencing individual services

function silence_dropbox {
  if which dropbox >/dev/null 2>/dev/null; then
    sudo -u "$User" dropbox stop
    sleep_time=1
    # The "running" command seems to return the opposite of what you expect.
    while ! sudo -u "$User" dropbox running >/dev/null 2>/dev/null; do
      sleep "$sleep_time"
      sleep_time=$((sleep_time*2))
      if [[ "$sleep_time" -ge 32 ]]; then
        echo "Error: Could not kill Dropbox!" >&2
        failure=true
        break
      fi
    done
    if [[ "$failure" ]]; then
      return 1
    else
      # Sometimes dropbox gives conflicting messages. Let's reassure with our own.
      echo "Dropbox daemon stopped." >&2
    fi
  else
    echo "Did not find 'dropbox' command" >&2
    return 1
  fi
}

function unsilence_dropbox {
  if which dropbox >/dev/null 2>/dev/null; then
    if ! sudo -u "$User" dropbox start 2>/dev/null; then
      echo "Error: Problem starting Dropbox." >&2
      return 1
    else
      echo "Dropbox started successfully." >&2
    fi
  else
    return 1
  fi
}

function silence_crashplan {
  crashservice=$(get_local_script 'crashservice.sh')
  if [[ "$crashservice" ]]; then
    if ! $crashservice stop; then
      echo "Error: $crashservice could not kill CrashPlan!" >&2
      return 1
    fi
  else
    echo "Error: Could not find script to kill CrashPlan!" >&2
    return 1
  fi
}

function unsilence_crashplan {
  crashservice=$(get_local_script 'crashservice.sh')
  if [[ "$crashservice" ]]; then
    if ! $crashservice start; then
      echo "Error: $crashservice could not start CrashPlan." >&2
      return 1
    fi
  else
    echo "Warning: did not find script to start CrashPlan." >&2
    return 1
  fi
}

function silence_snapd {
  if service snapd status >/dev/null 2>/dev/null; then
    sudo service snapd stop
  else
    return 1
  fi
}

function unsilence_snapd {
  service snapd status >/dev/null 2>/dev/null
  if [[ "$?" != 4 ]]; then
    # The status command returns 4 if the service doesn't exist, but 3 if it's not running.
    sudo service snapd start
  else
    return 1
  fi
}

function suppress_crashplan {
  verbose=
  if [[ "$#" -ge 1 ]]; then
    verbose="$1"
  fi
  if ! ( [[ -d /usr/local/crashplan/bin ]] && [[ -f /usr/local/crashplan/bin/service.sh ]] ); then
    echo "Did not find Crashplan installed in the expected location." >&2
    return 1
  fi
  if [[ "$verbose" ]]; then
    suppress_crashplan_loop
  else
    suppress_crashplan_loop >/dev/null 2>/dev/null
  fi
  return "$?"
}

function suppress_crashplan_loop {
  while true; do
    if pgrep -af /usr/local/crashplan/bin; then
      /usr/local/crashplan/bin/service.sh stop
      if [[ "$?" != 0 ]]; then
        return 1
      fi
    fi
    sleep 0.1
  done
}

# Utilities

function get_home {
  set +u
  if [[ "$SUDO_USER" ]]; then
    getent passwd "$SUDO_USER" | cut -d : -f 6
  else
    echo "$HOME"
  fi
  set -u
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
