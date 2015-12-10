#!/bin/bash
# on rasta

# To quickly check if a run in an oldRuns dir on a NAS is on tape already
# 
# 1/ generate a list on the NAS
OLDRUNS_FILE=$(mktemp)
ssh $1 ls -1 oldRuns > $OLDRUNS_FILE

# 2/ check if those are on tape
while read -r RUN; do
   echo $RUN;
   
   find /mnt/hds/proj/bioinfo/ON_TAPE/ -name "${RUN}*" | grep '.*'; FOUND=$?;
   if [[ $FOUND -eq 0 ]]; then
       echo "ssh $1 'rm -Rf oldRuns/$RUN'"
       ssh $1 "rm -Rf oldRuns/$RUN" &
   fi
done < $OLDRUNS_FILE
rm $OLDRUNS_FILE
