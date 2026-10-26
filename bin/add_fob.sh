#!/bin/bash

function main {
  local unit="${1?1st arg must be Unit (not BuzzCode!)}"
  local fob="${2?2nd arg must be FobNumber}"
  local debug="${3+--debug}"

  cd /home/chris/github/chrispollitt/WebAutomation
  export NODE_PATH="$(cygpath -w $HOME/user_js)"
  UNITNUM="$unit" FOBNUM="$fob" npx playwright test addfob $debug
}

main ${1+"$@"}
