#!/bin/bash

# Catch errors
prog_name="${0##*/}"
function trap_error () {
  local name="$prog_name"        # name of the script
  local lastline="$1"            # arg 1: last line of error occurence
  local lastcmd="$2"             # arg 2: last cmd
  local lasterr="$3"             # arg 3: error code of last cmd
  echo "${name}: line ${lastline}: cmd='${lastcmd}' status=${lasterr}"
  exit 1
}
trap 'trap_error ${LINENO} "${BASH_COMMAND}" "${PIPESTATUS[*]}"' ERR
set -E

# Get passwords
host2u="whatwelo@whatwelove.org"

iso8601_regex="^[0-9]{4}-[0-9]{2}-[0-9]{2}$"

# save pdf to Downloads
cd "${BASH_SOURCE[0]%/*}"
if [[ -z $1 ]]; then
  ./check_email.pl
  code=$(/home/chris/bin/get2fa_code.py | tr -d '[:space:]')
  echo "$code" | ssh "$host2u" id
fi

# process file
cd ~/Downloads
IFS='
'
files=$(ls -1 "VR0180-"*"inutes.pdf" 2>/dev/null)
for file in $files; do
  # exist
  if [[ -z $file || ! -s $file ]]; then
		echo "empty file: $file"
	  continue
  fi

  # Annual or Special General Meeting
  mtype="GM"
  if [[ $file == *$mtype* ]]; then
    rdir="Annual-General-Meetings"
    if [[ $file == *AGM* ]]; then
      mtype2="agm"
    elif [[ $file == *SGM* ]]; then
      mtype2="sgm"
		else
		  echo "unknown GM type: $file"
      continue
		fi
  else
    # Council Meeting
		mtype="CM"
    rdir="Council-Minutes"
    mtype2="council"
	fi
  echo "$mtype2 file=$file"

	# move file
	new="${file#VR0180-}"
	mv "$file" "$new"
  file="$new"
	
	# copy to web
  date="${file:0:10}"
  if [[ ! $date =~ $iso8601_regex ]]; then
    echo "Invalid date: $date"
		continue
  fi	
  rdir="$host2u:/home/whatwelo/www/landmarkcourt/www/owners/$rdir"
  scp "$file" "$rdir/${date}-$mtype2-minutes.pdf"
  
  # move to OneDrive
  ldir=~/OneDrive/!Shared/Strata/minutes
  mv  "$file" "$ldir/${date}-$mtype2-minutes.pdf"
done

# scp 2022-02-28 VR180 Landmark Court 2022 Annual General Meeting Minutes.pdf 
#   whatwelo@whatwelove.org:/home/whatwelo/
#   /cygdrive/z/public_html/landmarkcourt/www/owners/Annual-General-Meetings
#   2022-02-28-agm-minutes.pdf
# mv 2022-02-28 VR180 Landmark Court 2022 Annual General Meeting Minutes.pdf 
#   ~/OneDrive/!Shared/Strata/minutes
#   2022-02-28-agm-minutes.pdf
