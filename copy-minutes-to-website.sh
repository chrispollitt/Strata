#!/bin/bash

cd ~/Downloads

file=$(echo *" Council Meeting Minutes.pdf")
date="${file%% *}"
rdir="whatwelo@whatwelove.org:/home/whatwelo/www/landmarkcourt/www/owners/Council-Minutes"
ldir=~/"Dropbox/Shared/Home/Strata Documents/Minutes of Meetings/Council Meetings"

scp "$file" "$rdir/${date}-council-minutes.pdf"
mv  "$file" "$ldir/${date}-council-minutes.pdf"
