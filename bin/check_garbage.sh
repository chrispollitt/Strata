#!/bin/bash

to="chris.pollitt@gmail.com"
subject="Garbage collection log"
out="check_garbage.out"
sql1="select logtime,cardnumber,result from logs where firstname = 'Garbage' order by logtime;"
sql2="select distinct date(logtime) from logs where firstname = 'Garbage' order by date(logtime);"
perl1='s,\d:\d{2}\.\d+,0,;s,\s+, ,g'
perl2='s/^\s*\d{4}-//;/^(\d{2})-(\d{2})/ and push(@{$d{$1}} , $2);END{for $k (sort keys %d){print "--$k--\n".join("\n",@{$d{$k}})}}'

function meshdb() {
  PGPASSWORD=mesh psql -h mesh -U mesh -d mesh
}

echo "TODAY = $(date +'%Y-%m-%d')"

echo "$sql1" |meshdb|perl -lpe "$perl1"|sort|uniq 
echo "=========================="
echo "$sql2"  |meshdb|perl -lne "$perl2" | tee $out

#cat "$out" | maily -s "$subject" "$to"
