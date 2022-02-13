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
host1u="https://dyndns.whatwelove.org/nic/update/?hostname=cmnet"
host1="web.whatwelove.org:web"
host2u="whatwelo@whatwelove.org"
host2="whatwelove.org:2fa"
. ~/user_bash/Foo_Bar.bash
declare -a up
up=($(foo "$host1"))
user1="${up[0]}"
pass1="${up[1]}"
up=($(foo "$host2"))
user2="${up[0]}"
pass2="${up[1]}"

# save pdf to Downloads
cd ~/"Dropbox/Shared/Home/Strata Documents/bin"
./check_email.pl

# copy to website
cd ~/Downloads
file=$(echo *" Council Meeting Minutes.pdf")
date="${file%% *}"
rdir="$host2u:/home/whatwelo/www/landmarkcourt/www/owners/Council-Minutes"
wget --quiet --output-document=- --user="$user1" --password="$pass1" "$host1u"
echo "$pass2" | ssh "$host2u" id
scp "$file" "$rdir/${date}-council-minutes.pdf"

# move to dropbox
ldir=~/"Dropbox/Shared/Home/Strata Documents/Minutes of Meetings/Council Meetings"
mv  "$file" "$ldir/${date}-council-minutes.pdf"
