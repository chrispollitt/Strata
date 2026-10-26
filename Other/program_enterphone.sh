#!/bin/bash

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
    echo "error: no phone attacheed, exiting"
    return
  fi
  echo "phon='$phon'"
  echo "dial='${dial/$pass/xxxxxxxx}'"
  # url encode hash symbol
  dial="${dial//#/%23}"
  # Make call
  adb -s $phon shell "am start-activity -W -a android.intent.action.CALL -d tel:'$dial'"
  # Wait
  echo -n "Calling"
  (( i = 0 ))
  while true; do
    echo -n "."
    (( i += 1 ))
    if (( i > 30 )); then 
      echo "Timeout 30 sec"
      break
    fi
    IFS= read -r -t 2 -n 1 -s holder && stop="$holder"
    if [[ -n $stop ]]; then 
      echo "User interrupt"
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

main ${1+"$@"}

# --------------------------------

# cd ~/Dropbox/Shared/Home/Strata\ Documents/tmp
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
