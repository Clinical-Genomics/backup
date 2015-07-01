#!/bin/bash
#
#    Usage: overview.bash
#      run as hiseq.clinical 
#      use screen or nohup
#


VERSION=1.1.0
echo "VERSION ${VERSION}"

SERVERS=(clinical-db clinical-preproc clinical-nas-1 clinical-nas-2 seq-nas-1 seq-nas-2 seq-nas-3 nas-6 nas-7 nas-8 nas-9 nas-10)

for SERVER in "${SERVERS[@]}"; do
  NOW=$(date +"%Y%m%d%H%M%S")
  echo "[${NOW}] Will check ${SERVER}"
  SERVER_HOME=$(ssh ${SERVER} df -h 2> /dev/null | grep home)
  SERVER_HOME=$(echo ${SERVER_HOME} | awk '{ print $6,$5 }')
  echo -n "   ${SERVER} ${SERVER_HOME}"
  if [[ "$(echo ${SERVER_HOME} | awk '{split($2,arr,"%");print arr[1]}')" -ge 85 ]]; then
    echo -n "   -  C R I T I C A L !"
  fi
  echo
done

exit 0
