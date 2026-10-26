#!/bin/bash

PATH="$PATH:/cygdrive/c/Program Files (x86)/Minimal ADB and Fastboot/"

function main {
  local buzz="${1?1st arg must be BuzzCode (not unit!)}"
  local utel="${2?2nd arg must be local TelNumber}"
  . ~/user_bash/Foo_Bar.bash
  local -a up
  up=($(foo "lmephone"))
  local tele="${up[0]}"
  local pass="${up[1]}"
  local prog='*11'"$buzz$utel"'#'
  local exit='##'
  local dial="$tele,**$pass#,$prog,$exit"
  local phon
  local devs
  local call
  local stop
  local -a devices
  local maxwait=10
  
  if (( buzz < 555 || buzz > 965 )); then
    echo "Buzz code, not suite!"
    exit 1
  elif (( utel < 1000000000 || utel > 9999999999 )); then
    echo "telno, not acceptable!"
    exit 1
  fi
    
  adb start-server
  devs="$(adb devices)"
  OIFS="$IFS"
  IFS='
'
  devices=($devs)
  IFS="$OIFS"
  for d in "${devices[@]}"; do
    if [[ $d == *device && $d != *emulator* ]]; then
      phon="${d%%\	device}"
      break
    fi
  done
  if [[ -z $phon ]]; then
    echo "error: no phone attached, exiting"
    return 1
  fi
  echo "phon='$phon'"
  echo "dial='${dial/$pass/xxxxxxxx}'"
  # url encode hash symbol
  dial="${dial//#/%23}"
  # Make call (async)
	cmd="am start-activity -W -a android.intent.action.CALL -d tel:'$dial' -n com.android.server.telecom/.components.UserCallActivity"
#  echo "cmd=$cmd"
#  adb -s $phon shell -t "$cmd"
  adb -s $phon shell -T "$cmd"
  # Wait
  echo -n "Calling"
  (( i = 0 ))
  while true; do
    echo -n "."
    (( i += 1 ))
    if (( i > maxwait )); then 
      echo "Timeout $maxwait sec"
      break
    fi
    IFS= read -r -t 2 -n 1 -s holder && stop="$holder"
    if [[ -n $stop ]]; then 
      echo "User interrupt (i=$i)"
      break
    fi
    call=$(adb shell dumpsys telecom)
    if [[ $call != *state=* ]]; then 
      echo "Hungup"
      break 
    fi
    sleep 1
  done
  echo "Done"
  # Hang-up
  adb -s $phon shell "input keyevent 6"
}

# Rebuild the e-ink directory and send it to the Pi (opt in by setting
# ENTERPHONE_DISPLAY_HOST, e.g. pi@enterphone). Edit Contacts & Roles.xlsx first.
# A failure here is reported but does not change this script's exit status.
function update_display {
  [[ -n $ENTERPHONE_DISPLAY_HOST ]] || return 0
  local dir
  dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../enterphone-display"
  echo "Updating the enterphone display on $ENTERPHONE_DISPLAY_HOST"
  "$dir/publish.sh" "$ENTERPHONE_DISPLAY_HOST" || echo "warning: display update failed"
}

main ${1+"$@"} && update_display

# --------------------------------

# cd ~/OneDrive/!Shared/Strata/docs/tmp
# echo "select owner_list,buzz from owners1 where lower(owner_list) like '%geet%'"|csvsql

# Hayes Commands
# P - Pulse Dial
# T - Touch Tone Dial
# W - Wait for the second dial tone
# R - Reverse to answer-mode after dialing
# @ - Wait for up to 30 seconds for one or more ringbacks
# , - Pause for the time specified in register S8 (usually 2 seconds)
# ; - Remain in command mode after dialing.
# ! - Flash switch-hook (Hang up for a half second, as in transferring a call.)
# L - Dial last number

# 0-9 - Digit
# *#  - Special dial codes
# -() - Ignored

# SUI   BUZ
# 101 = 555
# 314 = 965

# adb -s 9AGAY1DN5T shell 
# am start-activity -W -a android.intent.action.CALL -d tel:'6046940195,**61053934%23,*117657789982932%23,%23%23'

# adb shell pm query-activities -a android.intent.action.CALL -d tel:123 | grep name=
